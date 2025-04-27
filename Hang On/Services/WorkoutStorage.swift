//
//  WorkoutStorage.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import Foundation

class WorkoutStorage: ObservableObject {
    static let shared = WorkoutStorage()
    
    @Published private(set) var workouts: [Workout] = []
    @Published private(set) var criticalForceWorkouts: [CriticalForceWorkout] = []
    
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "savedWorkouts"
    private let criticalForceWorkoutsKey = "savedCriticalForceWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    // Existing methods for regular workouts
    func saveWorkout(_ workout: Workout) {
        DispatchQueue.main.async {
            self.workouts.append(workout)
            self.saveToStorage()
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveToStorage()
    }
    
    // New methods for critical force workouts
    func saveCriticalForceWorkout(_ workout: CriticalForceWorkout) {
        DispatchQueue.main.async {
            self.criticalForceWorkouts.append(workout)
            self.saveToStorage()
        }
    }
    
    func deleteCriticalForceWorkout(_ workout: CriticalForceWorkout) {
        criticalForceWorkouts.removeAll { $0.id == workout.id }
        saveToStorage()
    }
    
    // Updated load method to handle both workout types
    private func loadWorkouts() {
        // Load regular workouts
        if let data = userDefaults.data(forKey: workoutsKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
        
        // Load critical force workouts
        if let data = userDefaults.data(forKey: criticalForceWorkoutsKey),
           let decoded = try? JSONDecoder().decode([CriticalForceWorkout].self, from: data) {
            criticalForceWorkouts = decoded
        }
    }
    
    // Updated save method to handle both workout types
    private func saveToStorage() {
        // Save regular workouts
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: workoutsKey)
        }
        
        // Save critical force workouts
        if let encoded = try? JSONEncoder().encode(criticalForceWorkouts) {
            userDefaults.set(encoded, forKey: criticalForceWorkoutsKey)
        }
    }
}
