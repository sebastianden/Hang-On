//
//  WorkoutStorage.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import Foundation

class WorkoutStorage: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "savedWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    func saveWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveToStorage()
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveToStorage()
    }
    
    private func loadWorkouts() {
        guard let data = userDefaults.data(forKey: workoutsKey),
              let decoded = try? JSONDecoder().decode([Workout].self, from: data) else {
            return
        }
        workouts = decoded
    }
    
    private func saveToStorage() {
        guard let encoded = try? JSONEncoder().encode(workouts) else { return }
        userDefaults.set(encoded, forKey: workoutsKey)
    }
}
