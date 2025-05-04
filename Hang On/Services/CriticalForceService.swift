//
//  CriticalForceService.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 27.04.25.
//

import Foundation
import AVFoundation

class CriticalForceService: ObservableObject {
    @Published var currentCycle: Int = 0
    @Published var timeRemaining: Int = 0
    @Published var currentForce: Double = 0
    @Published var measurements: [CriticalForceWorkout.CycleData.CycleMeasurement] = []
    @Published var cycles: [CriticalForceWorkout.CycleData] = []
    @Published var allMeasurements: [CriticalForceWorkout.CycleData.CycleMeasurement] = []
    
    let forceThreshold: Double = 5.0
    private var timer: Timer?
    private var endWarningSound: AVAudioPlayer?
    private var cycleStartSound: AVAudioPlayer?
    var onNewMeasurement: ((CriticalForceWorkout.CycleData.CycleMeasurement) -> Void)?
    
    @Published var currentState: WorkoutState = .idle
    
    enum WorkoutState {
        case idle
        case waitingForForce
        case working
        case resting
        case finished
    }
    
    init() {
        setupAudio()
    }
    
    func startWorkout() {
        print("CriticalForceService: Starting workout")
        currentState = .waitingForForce
        currentCycle = 0
        cycles.removeAll()
        clearMeasurements()
        allMeasurements.removeAll()  // Clear all measurements when starting new workout
    }
    
    func addMeasurement(_ force: Double) {
        currentForce = force
        
        // Create measurement object
        let measurement = CriticalForceWorkout.CycleData.CycleMeasurement(
            id: UUID(),
            timestamp: Date(),
            force: force
        )
        
        // Store all measurements
        allMeasurements.append(measurement)
        
        // Notify view about new measurement
        onNewMeasurement?(measurement)
        
        if currentState == .waitingForForce && force >= forceThreshold {
            startWorkCycle()
        }
        
        if currentState == .working {
            measurements.append(measurement)
        }
    }
    
    private func startWorkCycle() {
        currentState = .working
        timeRemaining = 7
        startTimer()
    }
    
    private func startRestCycle() {
        // Save the current cycle's measurements
        let cycleData = CriticalForceWorkout.CycleData(
            id: UUID(),
            cycleNumber: currentCycle + 1,
            measurements: measurements
        )
        cycles.append(cycleData)
        measurements.removeAll()
        currentState = .resting
        timeRemaining = 3
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func finishWorkout() {
        print("CriticalForceService: Finishing workout")
        timer?.invalidate()
        currentState = .finished
    }
    
    func calculateCriticalForce() -> Double {
        let lastSixCycles = cycles.suffix(6)
        return lastSixCycles.map(\.averageForce).reduce(0, +) / Double(lastSixCycles.count)
    }
    
    func clearMeasurements() {
        measurements.removeAll()
    }
    
    private func setupAudio() {
        do {
            // Configure audio session to mix with other audio
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Setup end warning sound
            if let endWarningSoundURL = Bundle.main.url(forResource: "end", withExtension: "mp3") {
                endWarningSound = try AVAudioPlayer(contentsOf: endWarningSoundURL)
                endWarningSound?.prepareToPlay()
            } else {
                print("End warning sound file not found")
            }
            
            // Setup cycle start sound
            if let cycleStartSoundURL = Bundle.main.url(forResource: "start", withExtension: "mp3") {
                cycleStartSound = try AVAudioPlayer(contentsOf: cycleStartSoundURL)
                cycleStartSound?.prepareToPlay()
            } else {
                print("Cycle start sound file not found")
            }
            
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    private func playEndWarningSound() {
        endWarningSound?.currentTime = 0
        endWarningSound?.play()
    }
    
    private func playCycleStartSound() {
        cycleStartSound?.currentTime = 0
        cycleStartSound?.play()
    }
    
    private func updateTimer() {
        timeRemaining -= 1
        if currentState == .working {
            if timeRemaining == 3 {  // Play sound 3 seconds before work cycle ends
                playEndWarningSound()
            }
            if timeRemaining <= 0 {
                startRestCycle()
            }
        } else if currentState == .resting {
            if timeRemaining <= 0 {
                currentCycle += 1
                if currentCycle >= 24 {
                    finishWorkout()
                } else {
                    currentState = .waitingForForce
                    playCycleStartSound()
                }
            }
        }
    }
    
    deinit {
        endWarningSound?.stop()
        cycleStartSound?.stop()
        endWarningSound = nil
        cycleStartSound = nil
    }
}

extension CriticalForceService {
    func calculateWPrime() -> Double {
        let cf = calculateCriticalForce()
        var wPrime = 0.0
        
        // Get all measurements sorted by timestamp
        let sortedMeasurements = allMeasurements.sorted { $0.timestamp < $1.timestamp }
        
        // We need at least two measurements to calculate the area
        guard sortedMeasurements.count >= 2 else { return 0.0 }
        
        // Calculate the area above CF using trapezoidal integration
        for i in 1..<sortedMeasurements.count {
            let prevMeasurement = sortedMeasurements[i-1]
            let currentMeasurement = sortedMeasurements[i]
            
            // Time difference in seconds
            let dt = currentMeasurement.timestamp.timeIntervalSince(prevMeasurement.timestamp)
            
            // Forces above CF
            let prevForceAboveCF = max(0, prevMeasurement.force - cf)
            let currentForceAboveCF = max(0, currentMeasurement.force - cf)
            
            // Area of trapezoid
            let area = 0.5 * (prevForceAboveCF + currentForceAboveCF) * dt
            
            wPrime += area
        }
        
        return wPrime
    }
}
