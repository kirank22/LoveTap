//
//  HomeView.swift
//  LoveTap
//
//  Created by Kiran Kothapalli on 10/5/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var shareURL: URL?

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [.purple.opacity(0.4), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Main content view switcher
            mainContentView
        }
        .onAppear {
            Task {
                await viewModel.initialize()
            }
        }
        // This is the new modifier that makes joining a pair work.
        .onOpenURL { incomingURL in
            Task {
                await viewModel.joinPair(from: incomingURL)
            }
        }
        .sheet(isPresented: .constant(shareURL != nil), onDismiss: { shareURL = nil }) {
            if let url = shareURL {
                ShareSheet(activityItems: [url.absoluteString])
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        if viewModel.isLoading {
            ProgressView("Connecting...")
                .tint(.white)
                .foregroundStyle(.white)
        } else if viewModel.pair != nil {
            // Use the extracted TapView
            TapView { tapType in
                Task {
                    await viewModel.sendTap(type: tapType)
                }
            }
        } else {
            // Use the extracted PairingView
            PairingView {
                Task {
                    shareURL = await viewModel.createPair()
                }
            }
        }
    }
}

// A simple wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


#Preview {
    HomeView()
}
