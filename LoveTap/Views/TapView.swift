//
//  TapView.swift
//  LoveTap
//
//  Created by Kiran Kothapalli on 10/5/25.
//

import SwiftUI

struct TapView: View {
    /// A closure to execute when the user sends a tap.
    var onSendTap: (TapType) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Text("You're Paired!")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
            
            Button {
                onSendTap(.quickTap)
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
            // Use a custom button style for a nice press effect.
            .buttonStyle(TapButtonStyle())
        }
    }
}

/// A custom button style for a scaling animation on press.
struct TapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.purple.opacity(0.4), .blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        TapView(onSendTap: { tapType in
            print("Sent a \(tapType.rawValue) in preview.")
        })
    }
}
