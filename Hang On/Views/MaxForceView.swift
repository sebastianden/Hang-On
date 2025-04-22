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
    
    var body: some View {
        VStack {
            Text("Current Weight: \(String(format: "%.2f", weightService.currentWeight)) kg")
                .font(.title)
            Text("Max Weight: \(String(format: "%.2f", weightService.maxWeight)) kg")
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
        }
        .navigationTitle("Max Force")
    }
}
