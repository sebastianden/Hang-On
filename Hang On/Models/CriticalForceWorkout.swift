//
//  CriticalForceWorkout.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 27.04.25.
//

import Foundation

struct CriticalForceWorkout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let hand: Workout.Hand
    let criticalForce: Double
    let cycles: [CycleData]
    let completedCycles: Int
    let allMeasurements: [CycleData.CycleMeasurement]  // Fixed: Use full path to CycleMeasurement
    
    struct CycleData: Identifiable, Codable {
        let id: UUID
        let cycleNumber: Int
        let measurements: [CycleMeasurement]
        let averageForce: Double
        
        struct CycleMeasurement: Identifiable, Codable {
            let id: UUID
            let timestamp: Date
            let force: Double
        }
        
        init(id: UUID = UUID(), cycleNumber: Int, measurements: [CycleMeasurement]) {
            self.id = id
            self.cycleNumber = cycleNumber
            self.measurements = measurements
            self.averageForce = measurements.map(\.force).reduce(0, +) / Double(measurements.count)
        }
    }
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         hand: Workout.Hand,
         criticalForce: Double,
         cycles: [CycleData],
         completedCycles: Int,
         allMeasurements: [CycleData.CycleMeasurement]) {
        self.id = id
        self.date = date
        self.hand = hand
        self.criticalForce = criticalForce
        self.cycles = cycles
        self.completedCycles = completedCycles
        self.allMeasurements = allMeasurements
    }
}
