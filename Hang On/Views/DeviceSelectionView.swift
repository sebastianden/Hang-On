//
//  DeviceSelectionView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import SwiftUI

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
