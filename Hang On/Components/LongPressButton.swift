//
//  LongPressButton.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 02.05.25.
//

import SwiftUI

struct LongPressButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var progress: CGFloat = 0
    @State private var longPressTask: Task<Void, Never>?
    
    var body: some View {
        Button(action: {}) {
            Text("Stop")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background color
                            Rectangle()
                                .fill(isEnabled ? Color.red.opacity(0.6) : Color.gray)
                            
                            // Loading animation
                            if isPressed && isEnabled {
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: geometry.size.width * progress)
                            }
                        }
                    }
                )
                .cornerRadius(10)
        }
        .disabled(!isEnabled)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                    if isEnabled {
                        action()
                    }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && isEnabled {
                        isPressed = true
                        withAnimation(.linear(duration: 1.0)) {
                            progress = 1.0
                        }
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    progress = 0
                }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        LongPressButton(isEnabled: true) {
            print("Button action triggered!")
        }
        .padding()
        
        LongPressButton(isEnabled: false) {
            print("Button action triggered!")
        }
        .padding()
    }
}
