//
//  ContentView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var weightService: WeightService
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
                        MaxForceHistoryView()
                    } label: {
                        WorkoutButton(
                            title: "Max Force",
                            icon: "chart.bar.fill",
                            description: "Measure your maximum finger strength"
                        )
                    }
                    
                    NavigationLink {
                        CriticalForceHistoryView()
                    } label: {
                        WorkoutButton(
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
