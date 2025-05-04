//
//  WorkoutBackup.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 04.05.25.
//

import Foundation

struct WorkoutBackup: Codable {
    let maxForceWorkouts: [Workout]
    let criticalForceWorkouts: [CriticalForceWorkout]
    let exportDate: Date
    
    init(maxForceWorkouts: [Workout], criticalForceWorkouts: [CriticalForceWorkout]) {
        self.maxForceWorkouts = maxForceWorkouts
        self.criticalForceWorkouts = criticalForceWorkouts
        self.exportDate = Date()
    }
}
