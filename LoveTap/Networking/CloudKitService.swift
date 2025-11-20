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
        // Optional: a pairing code if you store one in CloudKit
        static let code = "code"
    }

    private enum TapKeys {
        static let text = "text"
        static let pairId = "pairId"
        static let senderId = "senderId"
        static let createdAt = "createdAt"
    }
    
    func createOrFetchUser() async throws -> UserProfile {
        // TODO: Implement CloudKit logic to create or fetch the current user profile
        // Suggested approach:
        // - Resolve the current user's identity and a stable record ID
        // - Try to fetch a `UserProfile` CKRecord by that ID
        // - If not found, create a new record with keys: name, email, avatar
        // - Map CKRecord to `UserProfile` (id = recordID.recordName)
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func createPair(with code: String) async throws -> Pair {
        let currentUserId = try await currentUserRecordName()

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
    
    func joinPair(with code: String) async throws -> Pair? {
        guard let url = URL(string: code) else { return nil }

        // 1) Fetch share metadata for URL
        let metadata = try await fetchShareMetadata(for: url)

        // 2) Accept the share
        try await acceptShare(metadata)

        // 3) Fetch the root record (Pair) from the shared database
        let record = try await fetchRecord(in: sharedDatabase, id: metadata.rootRecordID)
        return mapPair(from: record)
    }
    
    func fetchPair(with id: String) async throws -> Pair? {
        // TODO: Fetch a Pair by id (record name)
        // Suggested approach:
        // - First try to fetch from the shared database (if participating in a share)
        // - If not found and you are the owner, also try the private database
        // - Map to `Pair` or return nil if not found
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func sendTap(to pairID: String, tap: Tap) async throws {
        let record = CKRecord(recordType: RecordType.tap)
        record[TapKeys.text] = tap.text as CKRecordValue?
        record[TapKeys.pairId] = pairID as CKRecordValue
        record[TapKeys.senderId] = tap.senderId as CKRecordValue?
        record[TapKeys.createdAt] = (tap.createdAt ?? Date()) as CKRecordValue

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sharedDatabase.save(record) { _, error in
                if let error = error { return continuation.resume(throwing: error) }
                continuation.resume()
            }
        }
    }
    
    func fetchRecentTaps(for pairID: String) async throws -> [Tap] {
        let predicate = NSPredicate(format: "%K == %@", TapKeys.pairId, pairID)
        let query = CKQuery(recordType: RecordType.tap, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: TapKeys.createdAt, ascending: false)]

        var results: [Tap] = []

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Tap], Error>) in
            let operation = CKQueryOperation(query: query)
            operation.recordFetchedBlock = { record in
                let tap = self.mapTap(from: record)
                results.append(tap)
            }
            operation.queryCompletionBlock = { _, error in
                if let error = error { return continuation.resume(throwing: error) }
                continuation.resume(returning: results)
            }
            sharedDatabase.add(operation)
        }
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

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sharedDatabase.save(subscription) { _, error in
                if let error = error { return continuation.resume(throwing: error) }
                continuation.resume()
            }
        }
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

    private func mapTap(from record: CKRecord) -> Tap {
        var tap = Tap()
        tap.text = record[TapKeys.text] as? String ?? ""
        tap.pairId = record[TapKeys.pairId] as? String
        tap.senderId = record[TapKeys.senderId] as? String
        tap.createdAt = record[TapKeys.createdAt] as? Date
        return tap
    }

    // MARK: - Helpers (Async wrappers)
    private func currentUserRecordName() async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            container.fetchUserRecordID { recordID, error in
                if let error = error { return continuation.resume(throwing: error) }
                guard let recordID = recordID else {
                    return continuation.resume(throwing: NSError(domain: "CloudKitService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No user record ID"]))
                }
                continuation.resume(returning: recordID.recordName)
            }
        }
    }

    private func modifyRecords(in database: CKDatabase, saving recordsToSave: [CKRecord], deleting recordIDsToDelete: [CKRecord.ID]) async throws {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let op = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
            op.savePolicy = .allKeys
            op.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error { return continuation.resume(throwing: error) }
                continuation.resume()
            }
            database.add(op)
        }
    }

    private func fetchRecord(in database: CKDatabase, id: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
            database.fetch(withRecordID: id) { record, error in
                if let error = error { return continuation.resume(throwing: error) }
                guard let record = record else {
                    return continuation.resume(throwing: NSError(domain: "CloudKitService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Record not found"]))
                }
                continuation.resume(returning: record)
            }
        }
    }

    private func fetchShareMetadata(for url: URL) async throws -> CKShare.Metadata {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKShare.Metadata, Error>) in
            let op = CKFetchShareMetadataOperation(shareURLs: [url])
            var captured: CKShare.Metadata?
            var capturedError: Error?
            op.perShareMetadataBlock = { _, metadata, error in
                if let error = error { capturedError = error; return }
                captured = metadata
            }
            op.fetchShareMetadataResultBlock = { result in
                switch result {
                case .failure(let error): continuation.resume(throwing: error)
                case .success:
                    if let capturedError = capturedError { return continuation.resume(throwing: capturedError) }
                    guard let captured = captured else {
                        return continuation.resume(throwing: NSError(domain: "CloudKitService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No share metadata found"]))
                    }
                    continuation.resume(returning: captured)
                }
            }
            container.add(op)
        }
    }

    private func acceptShare(_ metadata: CKShare.Metadata) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let op = CKAcceptSharesOperation(shareMetadatas: [metadata])
            op.acceptSharesResultBlock = { result in
                switch result {
                case .failure(let error): continuation.resume(throwing: error)
                case .success: continuation.resume()
                }
            }
            container.add(op)
        }
    }
}
