//
//  HandSelectionView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import SwiftUI

struct HandSelectionView: View {
    let onSelect: (Hand) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Hand")
                .font(.title)
                .padding()
            
            HStack(spacing: 10) {
                
                Button(action: { onSelect(.left) }) {
                    HandButton(hand: "Left", color: .green)
                }
                
                Button(action: { onSelect(.right) }) {
                    HandButton(hand: "Right", color: .blue)
                }
            }
        }
        .padding()
    }
}

struct HandButton: View {
    let hand: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(hand)
                .font(.title2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(30)
    }
}

#Preview {
    HandSelectionView { _ in }
}
