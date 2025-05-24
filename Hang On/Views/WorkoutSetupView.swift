//
//  WorkoutSetupView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.05.25.
//

import SwiftUI

struct WorkoutSetupView: View {
    @State private var bodyweight: String = ""
    @State private var selectedHand: Hand?
    @FocusState private var isBodyweightFocused: Bool
    let onComplete: (Hand, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hand Selection")) {
                    VStack(spacing: 20) {
                        Text("Select your hand:")
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            // Left hand button
                            VStack {
                                Image(systemName: "hand.point.left.fill")
                                    .font(.system(size: 40))
                                Text("Left")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(selectedHand == .left ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(selectedHand == .left ? .white : .primary)
                            .cornerRadius(10)
                            .onTapGesture {
                                selectedHand = .left
                            }
                            
                            // Right hand button
                            VStack {
                                Image(systemName: "hand.point.right.fill")
                                    .font(.system(size: 40))
                                Text("Right")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(selectedHand == .right ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedHand == .right ? .white : .primary)
                            .cornerRadius(10)
                            .onTapGesture {
                                selectedHand = .right
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Bodyweight")) {
                    HStack {
                        TextField("Enter your bodyweight", text: $bodyweight)
                            .keyboardType(.decimalPad)
                            .focused($isBodyweightFocused)
                            .onChange(of: bodyweight) { _, newValue in
                                // Only allow numbers and one decimal point
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    bodyweight = filtered
                                }
                                // Ensure only one decimal point
                                let components = filtered.components(separatedBy: ".")
                                if components.count > 2 {
                                    bodyweight = components[0] + "." + components[1]
                                }
                            }
                        Text("kg")
                    }
                }
                
                Section {
                    Button("Start Workout") {
                        if let weight = Double(bodyweight), let hand = selectedHand {
                            onComplete(hand, weight)
                            dismiss()
                        }
                    }
                    .disabled(selectedHand == nil || bodyweight.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Workout Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .submitLabel(.done)
            .onSubmit {
                isBodyweightFocused = false
            }
        }
    }
}

#Preview {
    WorkoutSetupView { hand, weight in
        print("Selected hand: \(hand), weight: \(weight)")
    }
} 
