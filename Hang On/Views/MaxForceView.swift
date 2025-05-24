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
    
    let selectedHand: Hand
    let bodyweight: Double
    
    @State private var showingSaveAlert = false
    @State private var isRecording = false
    @State private var showingDeviceSheet = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Selected Hand:")
                    .font(.headline)
                    .padding()
                HandBadgeView(hand: selectedHand)
            }
            
            HStack {
                VStack {
                    Text("Current")
                        .font(.title2)
                    Text("\(String(format: "%.2f", weightService.currentWeight)) kg")
                        .font(.title).bold()
                }.padding()
                
                VStack {
                    Text("Max")
                        .font(.title2)
                    Text("\(String(format: "%.2f", weightService.maxWeight)) kg")
                        .font(.title).bold()
                }.padding()
                
            }
            
            if weightService.measurements.isEmpty {
                Text("No measurements yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LiveChart(measurements: weightService.measurements)
            }
            
            Button(action: {
                if isRecording {
                    stopRecording()
                    showingSaveAlert = true
                } else {
                    if bluetoothManager.connectionState == .connected {
                        startRecording()
                    } else {
                        showingDeviceSheet = true
                    }
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
        .onAppear() {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear() {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .alert("Save Workout", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) {
                weightService.reset()
            }
            Button("Save") {
                saveWorkout()
            }
        } message: {
            Text("Do you want to save this workout?")
        }
        .sheet(isPresented: $showingDeviceSheet) {
            DeviceSelectionView(
                devices: bluetoothManager.discoveredDevices,
                isScanning: bluetoothManager.isScanning,
                onDeviceSelected: { device in
                    bluetoothManager.connectToDevice(device)
                    showingDeviceSheet = false
                    // Start recording after successful connection
                    startRecording()
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
        let workout = MaxForceWorkout(
            hand: selectedHand,
            maxForce: weightService.maxWeight,
            bodyweight: bodyweight
        )
        WorkoutStorage.shared.saveMaxForceWorkout(workout)
        weightService.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()  // dismiss with a slight delay
        }
    }
}

#Preview {
    MaxForceView(
        bluetoothManager: BluetoothManager(weightService: WeightService()),
        weightService: WeightService(),
        selectedHand: .right,
        bodyweight: 70.0
    )
}
