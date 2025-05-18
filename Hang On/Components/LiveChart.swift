//
//  LiveChart.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import SwiftUI
import Charts

import SwiftUI
import Charts

class LiveChartViewModel: ObservableObject {
    @Published var displayMeasurements: [Measurement] = []
    private var actualMeasurements: [Measurement] = []
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: TimeInterval = 0
    private let timeWindow: TimeInterval = 5.0
    private var workoutStartTime: Date?
    
    init() {
        setupDisplayLink()
    }
    
    // Convert measurement to elapsed seconds
    func elapsedSeconds(for measurement: Measurement) -> Double {
        guard let startTime = workoutStartTime else { return 0 }
        return measurement.timestamp.timeIntervalSince(startTime)
    }
    
    // Get current visible time range
    func currentTimeRange() -> ClosedRange<Double>? {
        guard let startTime = workoutStartTime else { return nil }
        let now = Date()
        let currentElapsed = now.timeIntervalSince(startTime)
        return (currentElapsed - timeWindow)...currentElapsed
    }
    
    func updateMeasurements(_ measurements: [Measurement]) {
        // Set workout start time if not set and we have measurements
        if workoutStartTime == nil, let firstMeasurement = measurements.first {
            workoutStartTime = firstMeasurement.timestamp
        }
        
        // Keep only measurements within the last 5 seconds
        let cutoffDate = Date().addingTimeInterval(-timeWindow)
        actualMeasurements = measurements.filter { $0.timestamp > cutoffDate }
    }
    
    // Add getter for workout start time
    func getWorkoutStartTime() -> Date? {
        return workoutStartTime
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .current, forMode: .common)
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        let currentDate = Date()
        let cutoffDate = currentDate.addingTimeInterval(-timeWindow)
        
        // If we have actual measurements, interpolate between them
        if !actualMeasurements.isEmpty {
            DispatchQueue.main.async {
                // Filter out old measurements
                self.displayMeasurements = self.actualMeasurements.filter { $0.timestamp > cutoffDate }
                
                // If there's no recent data, add a zero force measurement at current time
                if let lastMeasurement = self.displayMeasurements.last,
                   currentDate.timeIntervalSince(lastMeasurement.timestamp) > 0.1 {
                    let currentMeasurement = Measurement(
                        id: UUID(),
                        force: lastMeasurement.force,
                        timestamp: currentDate
                    )
                    self.displayMeasurements.append(currentMeasurement)
                }
            }
        }
        
        lastUpdateTime = displayLink.timestamp
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

struct LiveChart: View {
    @StateObject private var viewModel = LiveChartViewModel()
    let measurements: [Measurement]
    let criticalForce: Double?
    
    init(measurements: [Measurement], criticalForce: Double? = nil) {
        self.measurements = measurements
        self.criticalForce = criticalForce
    }
    
    var body: some View {
        Chart(viewModel.displayMeasurements) { measurement in
            LineMark(
                x: .value("Time", viewModel.elapsedSeconds(for: measurement)),
                y: .value("Force", measurement.force)
            )
            .interpolationMethod(.stepCenter)
            
            if let cf = criticalForce, cf > 0 {
                RuleMark(
                    y: .value("Critical Force", cf)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top) {
                    Text("Critical Force")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let seconds = value.as(Double.self) {
                        Text("\(Int(seconds))s")
                    }
                }
            }
        }
        .chartYScale(domain: 0...max(20, (measurements.map { $0.force }.max() ?? 20)))
        .chartXScale(domain: viewModel.currentTimeRange() ?? 0...5)
        .frame(height: 300)
        .padding()
        .onAppear {
            viewModel.updateMeasurements(measurements)
        }
        .onChange(of: measurements) { _, newMeasurements in
            viewModel.updateMeasurements(newMeasurements)
        }
    }
}
