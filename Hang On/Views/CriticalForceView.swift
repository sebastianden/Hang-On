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
    let selectedHand: Hand
    let earlyFinishThreshold: Int = 16
    @State private var showingSaveAlert = false
    @State private var showingEarlyFinishAlert = false
    @State private var showingDeviceSheet = false
    @State private var liveMeasurements: [Measurement] = []
    
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
                // TODO: critical force shouldn't be calculated every time
                LiveChart(measurements: liveMeasurements, criticalForce: criticalForceService.calculateCriticalForce())
                .overlay(
                    VStack {
                        switch criticalForceService.currentState {
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
        .sheet(isPresented: $showingDeviceSheet) {
            DeviceSelectionView(
                devices: bluetoothManager.discoveredDevices,
                isScanning: bluetoothManager.isScanning,
                onDeviceSelected: { device in
                    bluetoothManager.connectToDevice(device)
                    showingDeviceSheet = false
                    // Start workout after successful connection
                    startWorkout()
                }
            )
            .onAppear {
                bluetoothManager.startScanning()
            }
            .onDisappear {
                if bluetoothManager.connectionState != .connected {
                    bluetoothManager.stopScanning()
                }
            }
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
                    if bluetoothManager.connectionState == .connected {
                        startWorkout()
                    } else {
                        showingDeviceSheet = true
                    }
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
    
    private func startWorkout() {
        print("Starting workout...")
        bluetoothManager.weightService.startRecording()
        criticalForceService.startWorkout()
        liveMeasurements.removeAll()
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

#Preview {
    CriticalForceView(
        bluetoothManager: BluetoothManager(weightService: WeightService()),
        selectedHand: .right
    )
}
