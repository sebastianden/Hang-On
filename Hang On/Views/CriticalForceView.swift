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
    let earlyFinishThreshold: Int = 3
    @State private var showingSaveAlert = false
    @State private var showingEarlyFinishAlert = false
    @State private var liveMeasurements: [CriticalForceWorkout.CycleData.CycleMeasurement] = []
    
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
            if criticalForceService.currentState != .idle {
                CriticalForceLiveChartView(
                    measurements: liveMeasurements,
                    criticalForce: criticalForceService.calculateCriticalForce(),
                    currentState: criticalForceService.currentState
                )
                .frame(height: 300)
                .padding()
            }
            
            // Control Buttons
            controlButtons
                .padding()
        }
        .navigationTitle("Critical Force")
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            print("CriticalForceView: View appeared")
            bluetoothManager.weightService.addSubscriber(criticalForceService)
            criticalForceService.onNewMeasurement = { measurement in
                DispatchQueue.main.async {
                    self.liveMeasurements.append(measurement)
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            print("CriticalForceView: View disappeared")
            bluetoothManager.weightService.removeSubscriber(criticalForceService)
            criticalForceService.onNewMeasurement = nil
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
            Text("You've completed \(earlyFinishThreshold) cycles. Would you like to finish the workout now?")
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
                    bluetoothManager.weightService.startRecording()
                    criticalForceService.startWorkout()
                    liveMeasurements.removeAll()
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
                LongPressButton(
                    isEnabled: criticalForceService.currentCycle >= earlyFinishThreshold,
                    action: {
                        if criticalForceService.currentCycle >= earlyFinishThreshold {
                            showingEarlyFinishAlert = true
                        }
                    }
                )
            }
        }
    }
    
    private func saveWorkout() {
        let workout = CriticalForceWorkout(
            hand: selectedHand,
            criticalForce: criticalForceService.calculateCriticalForce(),
            wPrime: criticalForceService.calculateWPrime(),
            cycles: criticalForceService.cycles,
            completedCycles: criticalForceService.currentCycle,
            allMeasurements: criticalForceService.allMeasurements
        )
        WorkoutStorage.shared.saveCriticalForceWorkout(workout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
}

struct CriticalForceLiveChartView: View {
    let measurements: [CriticalForceWorkout.CycleData.CycleMeasurement]
    let criticalForce: Double
    let currentState: CriticalForceService.WorkoutState
    
    var body: some View {
        Chart {
            ForEach(measurements) { measurement in
                LineMark(
                    x: .value("Time", measurement.timestamp),
                    y: .value("Force", measurement.force)
                )
                .interpolationMethod(.stepCenter)
            }
            
            if criticalForce > 0 {
                RuleMark(
                    y: .value("Critical Force", criticalForce)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top) {
                    Text("Critical Force")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour().minute().second())
                    }
                }
            }
        }
        .overlay(
            VStack {
                switch currentState {
                case .working:
                    Text("PULL!")
                        .font(.title)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                case .resting:
                    Text("REST")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                default:
                    EmptyView()
                }
            }
        )
    }
}
