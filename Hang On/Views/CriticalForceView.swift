//
//  CriticalForceView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 27.04.25.
//

import SwiftUI
import Charts

struct CriticalForceView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @StateObject private var criticalForceService = CriticalForceService()
    @Environment(\.dismiss) var dismiss
    
    let selectedHand: Workout.Hand
    
    @State private var showingSaveAlert = false
    @State private var showingEarlyFinishAlert = false
    
    var body: some View {
        VStack {
            // Status Section
            VStack(spacing: 10) {
                Text("Selected Hand: \(selectedHand.rawValue.capitalized)")
                    .font(.headline)
                
                Text("Current Force: \(String(format: "%.2f", criticalForceService.currentForce)) kg")
                    .font(.title)
                
                statusView
                
                if criticalForceService.currentState == .finished {
                    Text("Critical Force: \(String(format: "%.2f", criticalForceService.calculateCriticalForce())) kg")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            
            // Chart Section
            if !criticalForceService.cycles.isEmpty {
                CriticalForceChartView(cycles: criticalForceService.cycles)
                    .frame(height: 300)
                    .padding()
            }
            
            // Control Buttons
            controlButtons
                .padding()
        }
        .navigationTitle("Critical Force")
        .onAppear {
            print("CriticalForceView: View appeared")
            bluetoothManager.weightService.addSubscriber(criticalForceService)
        }
        .onDisappear {
            print("CriticalForceView: View disappeared")
            bluetoothManager.weightService.removeSubscriber(criticalForceService)
        }
        .alert("Save Workout", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save") { saveWorkout() }
        } message: {
            Text("Do you want to save this workout?")
        }
        .alert("Finish Early", isPresented: $showingEarlyFinishAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Finish") {
                criticalForceService.finishWorkout()
                showingSaveAlert = true
            }
        } message: {
            Text("You've completed 16 cycles. Would you like to finish the workout now?")
        }
    }
    
    private var statusView: some View {
        VStack {
            switch criticalForceService.currentState {
            case .idle:
                Text("Ready to start")
                    .foregroundColor(.secondary)
            case .waitingForForce:
                Text("Pull to start cycle \(criticalForceService.currentCycle + 1)")
                    .foregroundColor(.blue)
            case .working:
                Text("PULL! \(criticalForceService.timeRemaining)s")
                    .foregroundColor(.green)
                    .font(.title)
            case .resting:
                Text("Rest \(criticalForceService.timeRemaining)s")
                    .foregroundColor(.red)
                    .font(.title)
            case .finished:
                Text("Workout Complete!")
                    .foregroundColor(.green)
            }
            
            if criticalForceService.currentState != .idle && criticalForceService.currentState != .finished {
                Text("Cycle \(criticalForceService.currentCycle + 1)/24")
                    .font(.subheadline)
            }
        }
    }
    
    private var controlButtons: some View {
        HStack {
            switch criticalForceService.currentState {
            case .idle:
                Button(action: {
                    print("Starting workout...")
                    bluetoothManager.weightService.startRecording() // Add this line
                    criticalForceService.startWorkout()
                }) {
                    Text("Start Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            case .finished:
                Button(action: { showingSaveAlert = true }) {
                    Text("Save Workout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            default:
                Button(action: {
                    print("Manual workout stop requested")
                    bluetoothManager.weightService.stopRecording() // Add this line
                    criticalForceService.finishWorkout()
                }) {
                    Text("Stop")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func saveWorkout() {
        let workout = CriticalForceWorkout(
            hand: selectedHand,
            criticalForce: criticalForceService.calculateCriticalForce(),
            cycles: criticalForceService.cycles,
            completedCycles: criticalForceService.currentCycle
        )
        WorkoutStorage.shared.saveCriticalForceWorkout(workout)
        dismiss()
    }
}

// CriticalForceChartView.swift
struct CriticalForceChartView: View {
    let cycles: [CriticalForceWorkout.CycleData]
    
    var body: some View {
        Chart {
            ForEach(cycles) { cycle in
                ForEach(cycle.measurements) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Force", measurement.force)
                    )
                    .foregroundStyle(by: .value("Cycle", "Cycle \(cycle.cycleNumber)"))
                }
            }
        }
    }
}
