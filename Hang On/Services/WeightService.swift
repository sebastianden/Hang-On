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
        if let max = measurements.map({ $0.force }).max() {
            maxWeight = max
        }
    }
    
    private var subscribers: [CriticalForceService] = []

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
    
    func addSubscriber(_ subscriber: CriticalForceService) {
        subscribers.append(subscriber)
    }

    func removeSubscriber(_ subscriber: CriticalForceService) {
        subscribers.removeAll { $0 === subscriber }
    }

    func addMeasurement(_ weight: Double) {
        guard isRecording else {
            print("WeightService: Measurement ignored - not recording")
            return
        }
        
        DispatchQueue.main.async {
            self.currentWeight = weight
            self.measurements.append(Measurement(id: UUID(), force: weight, timestamp: Date()))
            
            // Notify subscribers
            for subscriber in self.subscribers {
                subscriber.addMeasurement(weight)
            }
        }
    }

    
    func reset() {
        measurements.removeAll()
        maxWeight = 0.0
        currentWeight = 0.0
        isRecording = false
    }
}
