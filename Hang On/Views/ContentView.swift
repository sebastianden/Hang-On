//
//  ContentView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var measurementStore = MeasurementStore()
    @StateObject private var bluetoothManager: BluetoothManager
    @State private var showingDeviceSheet = false
    
    init() {
        // Create a single MeasurementStore instance
        let store = MeasurementStore()
        // Pass the same store instance to BluetoothManager
        _bluetoothManager = StateObject(wrappedValue: BluetoothManager(measurementStore: store))
        // Use the same store instance for the view
        _measurementStore = StateObject(wrappedValue: store)
    }
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(connectionStateColor)
                    .frame(width: 10, height: 10)
                Text(connectionStateText)
            }
            .padding()
            
            Text("Current Weight: \(String(format: "%.1f", bluetoothManager.currentWeight)) kg")
                .font(.title)
            
            Text("Max Weight: \(String(format: "%.1f", measurementStore.maxWeight)) kg")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Debug text to show measurement count
            Text("Measurements: \(measurementStore.measurements.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            if measurementStore.measurements.isEmpty {
                Text("No measurements yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart(measurementStore.measurements) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Weight", measurement.weight)
                    )
                }
                .frame(height: 300)
                .padding()
            }
            
            Button(action: {
                switch bluetoothManager.connectionState {
                case .disconnected:
                    bluetoothManager.startScanning()
                    showingDeviceSheet = true
                case .scanning:
                    bluetoothManager.stopScanning()
                    showingDeviceSheet = false
                case .connected:
                    bluetoothManager.disconnect()
                }
            }) {
                Text(buttonTitle)
            }
            .padding()
        }
        .sheet(isPresented: $showingDeviceSheet) {
            DeviceSelectionView(
                devices: bluetoothManager.discoveredDevices,
                isScanning: bluetoothManager.isScanning,
                onDeviceSelected: { device in
                    bluetoothManager.connectToDevice(device)
                    showingDeviceSheet = false
                }
            )
        }
    }
    
    private var buttonTitle: String {
        switch bluetoothManager.connectionState {
        case .disconnected:
            return "Scan for Devices"
        case .scanning:
            return "Cancel"
        case .connected:
            return "Disconnect"
        }
    }
    
    private var connectionStateColor: Color {
        switch bluetoothManager.connectionState {
        case .connected:
            return .green
        case .scanning:
            return .yellow
        case .disconnected:
            return .red
        }
    }
    
    private var connectionStateText: String {
        switch bluetoothManager.connectionState {
        case .connected:
            return "Connected"
        case .scanning:
            return "Scanning..."
        case .disconnected:
            return "Disconnected"
        }
    }
}

struct DeviceSelectionView: View {
    let devices: [Device]
    let isScanning: Bool
    let onDeviceSelected: (Device) -> Void
    
    var body: some View {
        NavigationView {
            List {
                if devices.isEmpty {
                    if isScanning {
                        HStack {
                            ProgressView()
                            Text("Scanning for devices...")
                        }
                    } else {
                        Text("No devices found")
                    }
                } else {
                    ForEach(devices) { device in
                        Button(action: { onDeviceSelected(device) }) {
                            Text(device.name)
                        }
                    }
                }
            }
            .navigationTitle("Select Device")
        }
    }
}
