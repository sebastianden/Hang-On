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
                            .onChange(of: bodyweight) { _, newValue in
                                let decimalSeparator = Locale.current.decimalSeparator ?? "."
                                
                                // Only allow numbers and one decimal separator
                                let filtered = newValue.filter { 
                                    $0.isNumber || String($0) == decimalSeparator
                                }
                                if filtered != newValue {
                                    bodyweight = filtered
                                }
                                
                                // Ensure only one decimal separator
                                let components = filtered.components(separatedBy: decimalSeparator)
                                if components.count > 2 {
                                    bodyweight = components[0] + decimalSeparator + components[1]
                                }
                            }
                        Text("kg")
                    }
                }
                
                Section {
                    Button("Start Workout") {
                        let formatter = NumberFormatter()
                        formatter.locale = .current
                        formatter.numberStyle = .decimal
                        if let weight = formatter.number(from: bodyweight)?.doubleValue,
                           let hand = selectedHand {
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
        }
    }
}

#Preview {
    WorkoutSetupView { hand, weight in
        print("Selected hand: \(hand), weight: \(weight)")
    }
} 
