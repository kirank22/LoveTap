//
//  LTWatchView.swift
//  LoveTapWatch Watch App
//
//  Created by Kiran Kothapalli on 1/31/26.
//

import SwiftUI

struct LTWatchView: View {
    var body: some View {
        NavigationStack {
            Grid(alignment: .topLeading) {
                GridRow {
                    LTHomeButton(systemImage: "microphone.fill", style: .blue, onTap: {
                        print("Button Pressed")
                    })
                    LTHomeButton(systemImage: "heart.fill", style: .red, onTap: {
                        print("Button Pressed")
                    })
                }
                
                GridRow {
                    LTHomeButton(systemImage: "message.fill", style: .green, onTap: {
                        print("Button Pressed")
                    })
                    LTHomeButton(systemImage: "waveform", style: .pink, onTap: {
                        print("Button Pressed")
                    })
                }
            }
            LTHomeButton(systemImage: "arrow.forward", style: .white, onTap: {
                print("Button Pressed")
            })
            .navigationTitle(Text("LoveTap").font(.headline).foregroundColor(.white))
        }
    }
}

struct LTHomeButton<S: ShapeStyle>: View {
    var systemImage: String
    var style: S
    var onTap: () -> Void

    
    var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: systemImage)
                .foregroundStyle(style)
        }
    }
}

#Preview {
    LTWatchView()
}
