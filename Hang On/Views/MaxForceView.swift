//
//  MaxForceView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 22.04.25.
//

import SwiftUI
import Charts

struct MaxForceView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var weightService: WeightService
    @Environment(\.dismiss) var dismiss
    
    let selectedHand: Workout.Hand
    
    @State private var showingSaveAlert = false
    @State private var isRecording = false
    
    var body: some View {
        VStack {
            Text("Selected Hand: \(selectedHand.rawValue.capitalized)")
                .font(.headline)
                .padding()
            
            Text("Current Force: \(String(format: "%.2f", weightService.currentWeight)) kg")
                .font(.title)
            
            Text("Max Force: \(String(format: "%.2f", weightService.maxWeight)) kg")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if weightService.measurements.isEmpty {
                Text("No measurements yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart(weightService.measurements) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Weight", measurement.weight)
                    )
                    .interpolationMethod(.stepCenter)
                }
                .frame(height: 300)
                .padding()
            }
            
            Button(action: {
                if isRecording {
                    stopRecording()
                    showingSaveAlert = true
                } else {
                    startRecording()
                }
            }) {
                Text(isRecording ? "Finish" : "Start Recording")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Max Force")
        .alert("Save Workout", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveWorkout()
            }
        } message: {
            Text("Do you want to save this workout?")
        }
        .interactiveDismissDisabled(isRecording)
    }
    
    private func startRecording() {
        isRecording = true
        weightService.startRecording()
    }
    
    private func stopRecording() {
        isRecording = false
        weightService.stopRecording()
    }
    
    private func saveWorkout() {
        let workout = Workout(
            hand: selectedHand,
            maxForce: weightService.maxWeight
        )
        WorkoutStorage.shared.saveWorkout(workout)
        weightService.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()  // dismiss with a slight delay
        }
    }
}
