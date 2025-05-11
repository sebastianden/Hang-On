//
//  CriticalForceWorkout.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 27.04.25.
//

import Foundation

struct CriticalForceWorkout: Workout {
    let id: UUID
    let date: Date
    let hand: Hand
    let criticalForce: Double
    let wPrime: Double
    let cycles: [CycleData]
    let completedCycles: Int
    let allMeasurements: [Measurement]
    
    struct CycleData: Identifiable, Codable {
        let id: UUID
        let cycleNumber: Int
        let measurements: [Measurement]
        let averageForce: Double
        
        init(id: UUID = UUID(), cycleNumber: Int, measurements: [Measurement]) {
            self.id = id
            self.cycleNumber = cycleNumber
            self.measurements = measurements
            self.averageForce = measurements.map(\.force).reduce(0, +) / Double(measurements.count)
        }
    }
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         hand: Hand,
         criticalForce: Double,
         wPrime: Double,
         cycles: [CycleData],
         completedCycles: Int,
         allMeasurements: [Measurement]) {
        self.id = id
        self.date = date
        self.hand = hand
        self.criticalForce = criticalForce
        self.wPrime = wPrime
        self.cycles = cycles
        self.completedCycles = completedCycles
        self.allMeasurements = allMeasurements
    }
}
