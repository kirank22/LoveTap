//
//  PairingView.swift
//  LoveTap
//
//  Created by Kiran Kothapalli on 10/5/25.
//

import SwiftUI

struct PairingView: View {
    /// A closure to execute when the user wants to create a pair.
    var onCreatePair: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to LoveTap")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Pair with your partner to start sending taps.")
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button(action: onCreatePair) {
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

#Preview {
    // This allows you to preview the PairingView in isolation.
    ZStack {
        LinearGradient(
            colors: [.purple.opacity(0.4), .blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        PairingView(onCreatePair: {
            print("Create Pair button tapped in preview.")
        })
    }
}
