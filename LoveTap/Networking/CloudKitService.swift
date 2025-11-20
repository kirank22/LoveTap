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
        // TODO: Implement CloudKit logic to create a new Pair with the given code (optional)
        // Suggested approach:
        // - Create a new CKRecord of type `Pair`
        // - Set PairKeys.userAId to current user's id, PairKeys.userBId to empty string initially
        // - If you use a join code, set PairKeys.code = code
        // - Save to CloudKit
        // - Map CKRecord to `Pair`
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func joinPair(with code: String) async throws -> Pair? {
        // TODO: Implement CloudKit logic to join an existing Pair using the code
        // Suggested approach:
        // - Query for a `Pair` record where PairKeys.code == code
        // - If found and userBId is empty, set userBId to current user's id
        // - Save changes and map to `Pair`
        // - Return nil if not found
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func fetchPair(with id: String) async throws -> Pair? {
        // TODO: Implement CloudKit logic to fetch a Pair by id (record name)
        // Suggested approach:
        // - Fetch CKRecord with the given recordName
        // - Map to `Pair` or return nil if not found
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func sendTap(to pairID: String, tap: Tap) async throws {
        // TODO: Implement CloudKit logic to send a Tap to the specified Pair
        // Suggested approach:
        // - Create a `Tap` CKRecord and set fields:
        //   text, pairId (pairID), senderId (current user id), createdAt (Date())
        // - Save record
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func fetchRecentTaps(for pairID: String) async throws -> [Tap] {
        // TODO: Implement CloudKit logic to fetch recent Taps for a Pair
        // Suggested approach:
        // - Query `Tap` records where pairId == pairID
        // - Sort by createdAt descending
        // - Map to `[Tap]`
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
    }
    
    func subscribeToTaps(for pairID: String) async throws {
        // TODO: Implement CloudKit subscription logic for Tap changes on the Pair
        // Suggested approach:
        // - Create a subscription on `Tap` where pairId == pairID
        // - Save the subscription to receive push notifications on changes
        
        throw NSError(domain: "NotImplemented", code: 0, userInfo: nil)
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
}
