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

            if viewModel.isLoading {
                ProgressView("Connecting...")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let _ = viewModel.pair {
                tapView
            } else {
                pairingView
            }
        }
        .onAppear {
            Task {
                await viewModel.initialize()
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

    // MARK: - Tap View
    private var tapView: some View {
        VStack(spacing: 40) {
            Text("You're Paired!")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
            
            Button {
                Task { await viewModel.sendTap(type: .quickTap) }
            } label: {
                ZStack {
                    Circle()
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                }
                .frame(width: 200, height: 200)
            }
            .buttonStyle(PlainButtonStyle()) // To allow custom animation
        }
    }
    
    // MARK: - Pairing View
    private var pairingView: some View {
        VStack(spacing: 20) {
            Text("Welcome to LoveTap")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Pair with your partner to start sending taps.")
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    shareURL = await viewModel.createPair()
                }
            } label: {
                Text("Create a Pair")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(30)
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
