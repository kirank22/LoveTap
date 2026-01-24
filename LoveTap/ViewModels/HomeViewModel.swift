//
//  HomeViewModel.swift
//  LoveTap
//
//  Created by Kiran Kothapalli on 10/5/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = true
    @Published var userProfile: UserProfile?
    @Published var pair: Pair?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Private Properties
    private let cloudKitService = CloudKitService()
    
    // MARK: - Public Methods
    
    func initialize() async {
        isLoading = true
        do {
            // 1. Fetch or create the user profile
            let profile = try await cloudKitService.createOrFetchUser()
            self.userProfile = profile
            
            // TODO: Persist and check for an existing pair ID before assuming no pair.
            // For now, we'll just check if a pair can be fetched with a placeholder.
            // In a real app, you would save the pair ID in UserDefaults upon pairing.
            
            self.isLoading = false
            
        } catch {
            handle(error: error)
        }
    }
    
    func createPair() async -> URL? {
        do {
            // Using a simple code for now, could be a random string.
            let (newPair, shareURL) = try await cloudKitService.createSharedPairReturningShareURL(code: "PAIR-\(UUID().uuidString)")
            self.pair = newPair
            return shareURL
        } catch {
            handle(error: error)
            return nil
        }
    }
    
    func joinPair(from url: URL) async {
        do {
            let joinedPair = try await cloudKitService.joinPair(with: url)
            self.pair = joinedPair
        } catch {
            handle(error: error)
        }
    }
    
    func sendTap(type: TapType) async {
        guard let pairID = pair?.id, let senderID = userProfile?.id else {
            handle(error: "Missing Pair or User ID")
            return
        }
        
        let newTap = Tap(
            id: UUID().uuidString,
            type: type,
            pairId: pairID,
            senderId: senderID,
            createdAt: Date()
        )
        
        do {
            try await cloudKitService.sendTap(to: pairID, tap: newTap)
            // TODO: Add some UI feedback for success
        } catch {
            handle(error: error)
        }
    }
    
    // MARK: - Private Helpers
    private func handle(error: Error) {
        print("Error: \(error.localizedDescription)")
        self.errorMessage = error.localizedDescription
        self.showError = true
        self.isLoading = false
    }
    
    private func handle(error: String) {
        print("Error: \(error)")
        self.errorMessage = error
        self.showError = true
        self.isLoading = false
    }
}
