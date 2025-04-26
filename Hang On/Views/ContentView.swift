//
//  ContentView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var weightService = WeightService()
    @StateObject private var bluetoothManager: BluetoothManager
    @State private var showingDeviceSheet = false
    
    init() {
        let service = WeightService()
        _weightService = StateObject(wrappedValue: service)
        _bluetoothManager = StateObject(wrappedValue: BluetoothManager(weightService: service))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Main navigation buttons
                VStack(spacing: 30) {
                    NavigationLink {
                        WorkoutHistoryView()
                    } label: {
                        HomeButtonView(
                            title: "Max Force",
                            icon: "chart.bar.fill",
                            description: "Measure your maximum finger strength"
                        )
                    }
                    
                    NavigationLink{
                        ComingSoonView()
                    } label: {
                        HomeButtonView(
                            title: "Critical Force",
                            icon: "bolt.fill",
                            description: "Measure your critical force"
                        )
                    }
                }
                .padding()
                
                // Connection status and button
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
                    HStack {
                        Circle()
                            .fill(connectionStateColor)
                            .frame(width: 10, height: 10)
                        Text(connectionStateText)
                    }
                    .padding()
                }
                .padding(.top)
                
                Spacer()
            }
            .navigationTitle("Hang On")
        }
        .environmentObject(bluetoothManager)
        .environmentObject(weightService)
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

struct HomeButtonView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .bold()
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ComingSoonView: View {
    var body: some View {
        VStack {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .padding()
            Text("Coming Soon!")
                .font(.title)
            Text("We're working hard to bring you this feature.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Critical Force")
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
