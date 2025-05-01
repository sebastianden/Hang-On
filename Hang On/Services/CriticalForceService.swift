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
    private var audioPlayer: AVAudioPlayer?
    var onNewMeasurement: ((CriticalForceWorkout.CycleData.CycleMeasurement) -> Void)?
    
    @Published var currentState: WorkoutState = .idle {
        didSet {
            print("CriticalForceService: State changed from \(oldValue) to \(currentState)")
        }
    }
    
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
        print("CriticalForceService: Received force measurement: \(force), Current state: \(currentState), Threshold: \(forceThreshold)")
        
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
            print("CriticalForceService: Force threshold (\(forceThreshold)) reached with force \(force), starting work cycle")
            startWorkCycle()
        }
        
        if currentState == .working {
            measurements.append(measurement)
            print("CriticalForceService: Added measurement during work cycle. Total measurements: \(measurements.count)")
        }
    }
    
    private func startWorkCycle() {
        print("CriticalForceService: Starting work cycle \(currentCycle + 1)")
        currentState = .working
        timeRemaining = 7
        startTimer()
    }
    
    private func startRestCycle() {
        print("CriticalForceService: Starting rest cycle after cycle \(currentCycle + 1)")
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
                options: [.mixWithOthers]  // Add these options
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            guard let soundURL = Bundle.main.url(forResource: "sound", withExtension: "mp3") else {
                print("Sound file not found")
                return
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    private func playSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
    
    private func updateTimer() {
        timeRemaining -= 1
        print("CriticalForceService: Time remaining: \(timeRemaining), State: \(currentState)")
        
        if currentState == .working {
            if timeRemaining == 3 {  // Play sound 3 seconds before work cycle ends
                playSound()
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
                }
            }
        }
    }
    
    // Add cleanup
    deinit {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
