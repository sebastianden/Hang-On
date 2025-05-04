//
//  ContentView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import SwiftUI
import UniformTypeIdentifiers

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
                    
                    NavigationLink {
                        CriticalForceHistoryView()
                    } label: {
                        HomeButtonView(
                            title: "Critical Force",
                            icon: "bolt.fill",
                            description: "Measure your critical force"
                        )
                    }
                }
                .padding()
                
                Spacer()
                
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
            }
            .navigationTitle("Hang On")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    backupControls
                }
            }
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

extension ContentView {
    @ViewBuilder
    var backupControls: some View {
        Menu {
            Button(action: exportWorkouts) {
                Label("Export Workouts", systemImage: "square.and.arrow.up")
            }
            
            Button(action: importWorkouts) {
                Label("Import Workouts", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private func exportWorkouts() {
        guard let url = WorkoutStorage.shared.exportData() else {
            // Show error alert
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func importWorkouts() {
        let supportedTypes: [UTType] = [.json]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = DocumentPickerDelegate.shared
        
        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        }
    }
}

// Add this class at the bottom of ContentView.swift
class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    static let shared = DocumentPickerDelegate()
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        let success = WorkoutStorage.shared.importData(from: url)
        
        // You might want to show a success/failure alert here
    }
}

#Preview {
    ContentView()
}
