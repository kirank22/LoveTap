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
    // NOTE: CloudKit functionality is temporarily disabled for UI development.
    // The service methods below have been replaced with mock implementations
    // that return sample data, allowing the UI to run without a real backend.
    // To re-enable CloudKit, revert the changes in this file.

    // MARK: - Record Types (Unused in mock implementation)
    private enum RecordType {
        static let userProfile = "UserProfile"
        static let pair = "Pair"
        static let tap = "Tap"
    }

    // MARK: - Keys (Unused in mock implementation)
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
    
    // MARK: - Mock Service Methods
    
    func createOrFetchUser() async throws -> UserProfile {
        print("CloudKitService: Using MOCK createOrFetchUser()")
        // Simulate a short network delay to mimic loading.
        try? await Task.sleep(for: .seconds(0.5))
        return UserProfile(id: "mockUserID", name: "You", email: "user@example.com", avatar: "")
    }
    
    func createPair(with code: String) async throws -> Pair {
        print("CloudKitService: Using MOCK createPair()")
        return Pair(id: "mockPairID", userAId: "mockUserID", userBId: "")
    }
    
    func joinPair(with shareURL: URL) async throws -> Pair {
        print("CloudKitService: Using MOCK joinPair()")
        // Simulate joining a pair successfully.
        return Pair(id: "mockPairID", userAId: "partnerID", userBId: "mockUserID")
    }
    
    func fetchPair(with id: String) async throws -> Pair? {
        print("CloudKitService: Using MOCK fetchPair()")
        // To test the view for a PAIRED user (TapView), return a mock Pair object.
        // To test the view for an UNPAIRED user (PairingView), return nil.
        return Pair(id: "mockPairID", userAId: "mockUserID", userBId: "partnerID")
    }
    
    func sendTap(to pairID: String, tap: Tap) async throws {
        print("CloudKitService: Using MOCK sendTap() with type: \(tap.type.rawValue)")
        // This function does nothing in the mock implementation.
    }
    
    func fetchRecentTaps(for pairID: String) async throws -> [Tap] {
        print("CloudKitService: Using MOCK fetchRecentTaps()")
        return []
    }
    
    func subscribeToTaps(for pairID: String) async throws {
        print("CloudKitService: Using MOCK subscribeToTaps()")
        // This function does nothing in the mock implementation.
    }
    
    func createSharedPairReturningShareURL(code: String) async throws -> (pair: Pair, shareURL: URL) {
        print("CloudKitService: Using MOCK createSharedPairReturningShareURL()")
        let mockPair = Pair(id: "mockPairID", userAId: "mockUserID", userBId: "")
        // Provide a dummy URL for the share sheet to display.
        let mockURL = URL(string: "https://www.apple.com")!
        return (mockPair, mockURL)
    }
    
    // MARK: - Original CloudKit Helpers (Unused in mock implementation)
    
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
        }
    }
}

