//
//  WeightService.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 22.04.25.
//

import Foundation
import Combine

class WeightService: ObservableObject {
    @Published var currentWeight: Double = 0.0
    @Published var measurements: [Measurement] = [] {
        didSet {
            updateMaxWeight()
        }
    }
    @Published var maxWeight: Double = 0.0
    @Published var isRecording: Bool = false

    private func updateMaxWeight() {
        if let max = measurements.map({ $0.weight }).max() {
            maxWeight = max
        }
    }

    func startRecording() {
        print("Starting recording")
        isRecording = true
        measurements.removeAll()  // Clear old measurements
        maxWeight = 0.0          // Reset max weight
        currentWeight = 0.0      // Reset current weight
    }

    func stopRecording() {
        print("Stopping recording")
        isRecording = false
    }

    func addMeasurement(_ weight: Double) {
        guard isRecording else {
            print("Measurement ignored - not recording")
            return
        }
        //print("Adding measurement: \(weight)")
        let measurement = Measurement(weight: weight, timestamp: Date())
        DispatchQueue.main.async {
            self.currentWeight = weight
            self.measurements.append(measurement)
            //print("Added measurement. New count: \(self.measurements.count)")
        }
    }
    
    func reset() {
        measurements.removeAll()
        maxWeight = 0.0
        currentWeight = 0.0
        isRecording = false
    }
}
