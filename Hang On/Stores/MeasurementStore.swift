//
//  MeasurementStore.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import Foundation

class MeasurementStore: ObservableObject {
    @Published var measurements: [Measurement] = [] {
        didSet {
            updateMaxWeight()
        }
    }
    @Published var maxWeight: Double = 0.0
    
    private func updateMaxWeight() {
        if let max = measurements.map({ $0.weight }).max() {
            maxWeight = max
        }
    }
    
    func addMeasurement(weight: Double) {
        print("Adding measurement: \(weight)")
        DispatchQueue.main.async {
            let measurement = Measurement(weight: weight, timestamp: Date())
            self.measurements.append(measurement)
            print("Added measurement. New count: \(self.measurements.count)")
        }
    }
}
