//
//  WorkoutStorage.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import Foundation

class WorkoutStorage: ObservableObject {
    static let shared = WorkoutStorage()
    
    @Published private(set) var maxForceWorkouts: [MaxForceWorkout] = []
    @Published private(set) var criticalForceWorkouts: [CriticalForceWorkout] = []
    
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "savedWorkouts"
    private let criticalForceWorkoutsKey = "savedCriticalForceWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    func saveMaxForceWorkout(_ workout: MaxForceWorkout) {
        DispatchQueue.main.async {
            self.maxForceWorkouts.append(workout)
            self.saveToStorage()
        }
    }
    
    func deleteMaxForceWorkout(_ workout: MaxForceWorkout) {
        maxForceWorkouts.removeAll { $0.id == workout.id }
        saveToStorage()
    }
    
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
           let decoded = try? JSONDecoder().decode([MaxForceWorkout].self, from: data) {
            maxForceWorkouts = decoded
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
        if let encoded = try? JSONEncoder().encode(maxForceWorkouts) {
            userDefaults.set(encoded, forKey: workoutsKey)
        }
        
        // Save critical force workouts
        if let encoded = try? JSONEncoder().encode(criticalForceWorkouts) {
            userDefaults.set(encoded, forKey: criticalForceWorkoutsKey)
        }
    }
}

extension WorkoutStorage {
    func exportData() -> URL? {
        let backup = WorkoutBackup(
            maxForceWorkouts: maxForceWorkouts,
            criticalForceWorkouts: criticalForceWorkouts
        )
        
        guard let data = try? JSONEncoder().encode(backup) else {
            print("Failed to encode workout data")
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let fileName = "hangon_backup_\(dateFormatter.string(from: Date())).json"
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write backup file: \(error)")
            return nil
        }
    }
    
    func importData(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(WorkoutBackup.self, from: data)
            
            DispatchQueue.main.async {
                self.maxForceWorkouts = backup.maxForceWorkouts
                self.criticalForceWorkouts = backup.criticalForceWorkouts
                self.saveToStorage()
            }
            
            return true
        } catch {
            print("Failed to import backup: \(error)")
            return false
        }
    }
}
