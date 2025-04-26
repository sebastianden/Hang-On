//
//  HandSelectionView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import SwiftUI

struct HandSelectionView: View {
    let onSelect: (Workout.Hand) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Hand")
                .font(.title)
                .padding()
            
            Button(action: { onSelect(.left) }) {
                HandButton(hand: "Left")
            }
            
            Button(action: { onSelect(.right) }) {
                HandButton(hand: "Right")
            }
        }
        .padding()
    }
}

struct HandButton: View {
    let hand: String
    
    var body: some View {
        HStack {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 30))
            Text(hand)
                .font(.title2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}
