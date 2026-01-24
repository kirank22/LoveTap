//
//  CloudKitService.swift
//  LoveTap
//
//  Created by Kiran Kothapalli on 10/5/25.
//

import Foundation
import CloudKit

class CloudKitService {
    
    // MARK: - CloudKit
    private let container = CKContainer.default()
    private let database = CKContainer.default().privateCloudDatabase
    private let sharedDatabase = CKContainer.default().sharedCloudDatabase

    // MARK: - Record Types
    private enum RecordType {
        static let userProfile = "UserProfile"
        static let pair = "Pair"
        static let tap = "Tap"
    }

    // MARK: - Keys
    private enum UserKeys {
        static let name = "name"
        static let email = "email"
        static let avatar = "avatar"
    }

    private enum PairKeys {
        static let userAId = "userAId"
        static let userBId = "userBId"
        static let code = "code"
    }

    private enum TapKeys {
        static let type = "type" // Changed from 'text'
        static let pairId = "pairId"
        static let senderId = "senderId"
        static let createdAt = "createdAt"
    }
    
    func createOrFetchUser() async throws -> UserProfile {
        let userRecordID = try await container.userRecordID()

        do {
            let userRecord = try await database.record(for: userRecordID)
            guard let userProfile = mapUser(from: userRecord) else {
                throw NSError(domain: "CloudKitService", code: 10, userInfo: [NSLocalizedDescriptionKey: "Fetched user record but failed to map."])
            }
            return userProfile
        } catch let error as CKError where error.code == .unknownItem {
            let identity = try await container.userIdentity(forUserRecordID: userRecordID)
            let name = identity?.nameComponents.flatMap(PersonNameComponentsFormatter().string) ?? "Anonymous"
            let email = identity?.lookupInfo?.emailAddress ?? ""

            let newUserRecord = CKRecord(recordType: RecordType.userProfile, recordID: userRecordID)
            newUserRecord[UserKeys.name] = name as CKRecordValue
            newUserRecord[UserKeys.email] = email as CKRecordValue
            newUserRecord[UserKeys.avatar] = "" as CKRecordValue

            let savedRecord = try await database.save(newUserRecord)
            
            guard let userProfile = mapUser(from: savedRecord) else {
                 throw NSError(domain: "CloudKitService", code: 11, userInfo: [NSLocalizedDescriptionKey: "Created and saved user record but failed to map."])
            }
            return userProfile
        }
    }
    
    func createPair(with code: String) async throws -> Pair {
        let currentUserId = try await container.userRecordID().recordName

        let pairRecord = CKRecord(recordType: RecordType.pair)
        pairRecord[PairKeys.userAId] = currentUserId as CKRecordValue
        pairRecord[PairKeys.userBId] = "" as CKRecordValue
        pairRecord[PairKeys.code] = code as CKRecordValue

        let share = CKShare(rootRecord: pairRecord)
        share[CKShare.SystemFieldKey.title] = "LoveTap Pair" as CKRecordValue

        try await modifyRecords(in: database, saving: [pairRecord, share], deleting: [])

        guard let pair = mapPair(from: pairRecord) else {
            throw NSError(domain: "CloudKitService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to map saved Pair record."])
        }
        return pair
    }
    
    func joinPair(with shareURL: URL) async throws -> Pair {
        let metadata = try await container.shareMetadata(for: shareURL)
        _ = try await container.accept(metadata)
        let record = try await sharedDatabase.record(for: metadata.rootRecordID)
        
        guard let pair = mapPair(from: record) else {
            throw NSError(domain: "CloudKitService", code: 12, userInfo: [NSLocalizedDescriptionKey: "Failed to map joined Pair record."])
        }
        return pair
    }
    
    func fetchPair(with id: String) async throws -> Pair? {
        let recordID = CKRecord.ID(recordName: id)
        
        // Asynchronously try fetching from both databases
        async let sharedRecord = try? sharedDatabase.record(for: recordID)
        async let privateRecord = try? database.record(for: recordID)
        
        if let record = await sharedRecord, let pair = mapPair(from: record) {
            return pair
        }
        
        if let record = await privateRecord, let pair = mapPair(from: record) {
            return pair
        }
        
        return nil
    }
    
    func sendTap(to pairID: String, tap: Tap) async throws {
        let record = CKRecord(recordType: RecordType.tap)
        record[TapKeys.type] = tap.type.rawValue as CKRecordValue
        record[TapKeys.pairId] = pairID as CKRecordValue
        record[TapKeys.senderId] = tap.senderId as CKRecordValue
        record[TapKeys.createdAt] = tap.createdAt as CKRecordValue

        // Modern async/await version
        _ = try await sharedDatabase.save(record)
    }
    
    func fetchRecentTaps(for pairID: String) async throws -> [Tap] {
        let predicate = NSPredicate(format: "%K == %@", TapKeys.pairId, pairID)
        let query = CKQuery(recordType: RecordType.tap, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: TapKeys.createdAt, ascending: false)]

        // Modern async/await version
        let (matchResults, _) = try await sharedDatabase.records(matching: query)
        let records = matchResults.compactMap { try? $0.1.get() }
        
        return records.compactMap(mapTap)
    }
    
    func subscribeToTaps(for pairID: String) async throws {
        let predicate = NSPredicate(format: "%K == %@", TapKeys.pairId, pairID)
        let subscription = CKQuerySubscription(recordType: RecordType.tap,
                                               predicate: predicate,
                                               subscriptionID: "tap-subscription-\(pairID)",
                                               options: [.firesOnRecordCreation])
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        // Modern async/await version
        _ = try await sharedDatabase.save(subscription)
    }
    
    // MARK: - Mapping
    private func mapUser(from record: CKRecord) -> UserProfile? {
        let id = record.recordID.recordName
        guard let name = record[UserKeys.name] as? String else { return nil }
        let email = record[UserKeys.email] as? String ?? ""
        let avatar = record[UserKeys.avatar] as? String ?? ""
        return UserProfile(id: id, name: name, email: email, avatar: avatar)
    }

    private func mapPair(from record: CKRecord) -> Pair? {
        let id = record.recordID.recordName
        guard let userAId = record[PairKeys.userAId] as? String,
              let userBId = record[PairKeys.userBId] as? String else {
            return nil
        }
        return Pair(id: id, userAId: userAId, userBId: userBId)
    }

    private func mapTap(from record: CKRecord) -> Tap? {
        let id = record.recordID.recordName
        guard let typeString = record[TapKeys.type] as? String,
              let type = TapType(rawValue: typeString),
              let pairId = record[TapKeys.pairId] as? String,
              let senderId = record[TapKeys.senderId] as? String,
              let createdAt = record[TapKeys.createdAt] as? Date else {
            return nil
        }
        return Tap(id: id, type: type, pairId: pairId, senderId: senderId, createdAt: createdAt)
    }

    func createSharedPairReturningShareURL(code: String) async throws -> (pair: Pair, shareURL: URL) {
        let currentUserId = try await container.userRecordID().recordName

        let pairRecord = CKRecord(recordType: RecordType.pair)
        pairRecord[PairKeys.userAId] = currentUserId as CKRecordValue
        pairRecord[PairKeys.userBId] = "" as CKRecordValue
        pairRecord[PairKeys.code] = code as CKRecordValue

        let share = CKShare(rootRecord: pairRecord)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "LoveTap Pair" as CKRecordValue

        _ = try await database.modifyRecords(saving: [pairRecord, share], deleting: [])

        guard let pair = mapPair(from: pairRecord), let url = share.url else {
            throw NSError(domain: "CloudKitService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to map pair or get share URL."])
        }
        return (pair, url)
    }

    // MARK: - Helpers (Now replaced by modern APIs where possible)
    private func modifyRecords(in database: CKDatabase, saving recordsToSave: [CKRecord], deleting recordIDsToDelete: [CKRecord.ID]) async throws {
        // This helper is still useful as a wrapper around the operation
        let op = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        op.savePolicy = .allKeys
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(op)
        }
    }
}

