//
//  CriticalForceHistoryView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 27.04.25.
//

import SwiftUI
import Charts

struct CriticalForceHistoryView: View {
    @StateObject private var workoutStorage = WorkoutStorage.shared
    @State private var showingHandSelection = false
    @State private var selectedHand: Hand?
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedWorkout: CriticalForceWorkout?
    
    var body: some View {
        VStack {
            CriticalForceHistoryChartView(workouts: workoutStorage.criticalForceWorkouts)
                .padding()
            List {
                ForEach(workoutStorage.criticalForceWorkouts.sorted(by: { $0.date > $1.date })) { workout in
                    CriticalForceWorkoutRow(workout: workout)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorkout = workout
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let workout = workoutStorage.criticalForceWorkouts.sorted(by: { $0.date > $1.date })[index]
                        workoutStorage.deleteCriticalForceWorkout(workout)
                    }
                }
            }
            
            Button(action: {
                showingHandSelection = true
            }) {
                Text("Start New Assessment")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Critical Force History")
        .sheet(isPresented: $showingHandSelection) {
            HandSelectionView { hand in
                selectedHand = hand
                showingHandSelection = false
            }
        }
        .sheet(item: $selectedWorkout) { workout in
            CriticalForceDetailView(workout: workout)
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedHand != nil },
            set: { if !$0 { selectedHand = nil }}
        )) {
            if let hand = selectedHand {
                CriticalForceView(
                    bluetoothManager: bluetoothManager,
                    selectedHand: hand
                )
            }
        }
    }
}

struct CriticalForceHistoryChartView: View {
    let workouts: [CriticalForceWorkout]
    @State private var selectedMetric: Metric = .criticalForce
    
    enum Metric {
        case criticalForce
        case wPrime
        
        var title: String {
            switch self {
            case .criticalForce: return "Critical Force"
            case .wPrime: return "W'"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("Metric", selection: $selectedMetric) {
                Text("Critical Force").tag(Metric.criticalForce)
                Text("W'").tag(Metric.wPrime)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            switch selectedMetric {
            case .criticalForce:
                CFChart(workouts: workouts)
                    .frame(height: 200)
            case .wPrime:
                WPrimeChart(workouts: workouts)
                    .frame(height: 200)
            }
        }
    }
}

struct CFChart: View {
    let workouts: [CriticalForceWorkout]
    
    private var leftHandData: [CriticalForceWorkout] {
        workouts.filter { $0.hand == .left }.sorted { $0.date < $1.date }
    }
    
    private var rightHandData: [CriticalForceWorkout] {
        workouts.filter { $0.hand == .right }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        Chart {
            ForEach(leftHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("Critical Force", workout.criticalForce)
                )
                .foregroundStyle(Color.green)
            }
            .symbol(by: .value("Hand", "Left"))
            
            ForEach(rightHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("Critical Force", workout.criticalForce)
                )
                .foregroundStyle(Color.blue)
            }
            .symbol(by: .value("Hand", "Right"))
        }
        .chartForegroundStyleScale([
            "Left": .green,
            "Right": .blue
        ])
        .chartLegend(position: .top)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let force = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.0f kg", force))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month().day())
                    }
                }
            }
        }
    }
}

struct WPrimeChart: View {
    let workouts: [CriticalForceWorkout]
    
    private var leftHandData: [CriticalForceWorkout] {
        workouts.filter { $0.hand == .left }.sorted { $0.date < $1.date }
    }
    
    private var rightHandData: [CriticalForceWorkout] {
        workouts.filter { $0.hand == .right }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        Chart {
            ForEach(leftHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("W'", workout.wPrime)
                )
                .foregroundStyle(Color.green)
            }
            .symbol(by: .value("Hand", "Left"))
            
            ForEach(rightHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("W'", workout.wPrime)
                )
                .foregroundStyle(Color.blue)
            }
            .symbol(by: .value("Hand", "Right"))
        }
        .chartForegroundStyleScale([
            "Left": .green,
            "Right": .blue
        ])
        .chartLegend(position: .top)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let wPrime = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.0f kg⋅s", wPrime))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.month().day())
                    }
                }
            }
        }
    }
}

struct CriticalForceWorkoutRow: View {
    let workout: CriticalForceWorkout
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.date.formatted(date: .long, time: .shortened))
                .font(.headline)
            HStack {
                HandBadgeView(hand: workout.hand)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("CF: \(String(format: "%.1f kg", workout.criticalForce))")
                        .bold()
                    Text("W': \(String(format: "%.0f kg⋅s", workout.wPrime))")
                        .bold()
                    Text("\(workout.completedCycles)/24 cycles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CriticalForceDetailView: View {
    let workout: CriticalForceWorkout
    @Environment(\.dismiss) var dismiss
    
    // Use allMeasurements directly instead of computing it
    private var sortedMeasurements: [Measurement] {
        workout.allMeasurements.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Summary")
                            .font(.title2)
                            .bold()
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Critical Force")
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f kg", workout.criticalForce))
                                    .font(.title3)
                                    .bold()
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Completed Cycles")
                                    .foregroundColor(.secondary)
                                Text("\(workout.completedCycles)/24")
                                    .font(.title3)
                                    .bold()
                            }
                        }
                        Text("Hand: \(workout.hand.rawValue.capitalized)")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    
                    // Complete Force Profile
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Force Profile")
                            .font(.title2)
                            .bold()
                        Chart {
                            // Plot all measurements
                            ForEach(sortedMeasurements) { measurement in
                                LineMark(
                                    x: .value("Time", measurement.timestamp),
                                    y: .value("Force", measurement.force)
                                )
                                .foregroundStyle(.blue)
                            }
                            .interpolationMethod(.stepCenter)
                            
                            // Critical Force line
                            RuleMark(
                                y: .value("Critical Force", workout.criticalForce)
                            )
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Critical Force")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(height: 300)
                        .chartYScale(domain: 0...(sortedMeasurements.map(\.force).max() ?? 50) * 1.1)
                        .chartXAxis {
                            AxisMarks(position: .bottom) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, format: .dateTime.hour().minute().second())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    
                    // Individual Cycles Summary
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cycle Summary")
                            .font(.title2)
                            .bold()
                        ForEach(workout.cycles) { cycle in
                            HStack {
                                Text("Cycle \(cycle.cycleNumber)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f kg", cycle.averageForce))
                                    .bold()
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 1)
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
