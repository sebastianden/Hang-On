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
    @State private var showingSetup = false
    @State private var isShowingWorkout = false
    @State private var workoutToShow: CriticalForceWorkout?
    @State private var showingWorkoutDetail: CriticalForceWorkout?
    @State private var selectedMetric: Metric = .criticalForce
    @State private var showRelative = false
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    enum Metric: String {
        case criticalForce = "CF"
        case wPrime = "W'"
        
        var valueProvider: (CriticalForceWorkout) -> Double {
            switch self {
            case .criticalForce: return { $0.criticalForce }
            case .wPrime: return { $0.wPrime }
            }
        }
        
        var relativeValueProvider: (CriticalForceWorkout) -> Double {
            switch self {
            case .criticalForce: return { $0.criticalForce / $0.bodyweight * 100 }
            case .wPrime: return { $0.wPrime / $0.bodyweight }
            }
        }
        
        var yAxisLabel: String {
            switch self {
            case .criticalForce: return "Critical Force (kg)"
            case .wPrime: return "W' (kg⋅s)"
            }
        }
        
        var relativeYAxisLabel: String {
            switch self {
            case .criticalForce: return "Critical Force (% BW)"
            case .wPrime: return "W' (BW⋅s)"
            }
        }
        
        var format: String {
            switch self {
            case .criticalForce: return "%.1f"
            case .wPrime: return "%.0f"
            }
        }
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                HStack {
                    Picker("Metric", selection: $selectedMetric) {
                        Text(Metric.criticalForce.rawValue).tag(Metric.criticalForce)
                        Text(Metric.wPrime.rawValue).tag(Metric.wPrime)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Unit", selection: $showRelative) {
                        Text("Abs").tag(false)
                        Text("% BW").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                HistoricalChart(
                    workouts: workoutStorage.criticalForceWorkouts,
                    valueProvider: showRelative ? selectedMetric.relativeValueProvider : selectedMetric.valueProvider,
                    yAxisLabel: showRelative ? selectedMetric.relativeYAxisLabel : selectedMetric.yAxisLabel,
                    yAxisFormat: selectedMetric.format
                )
                .frame(height: 200)
            }
            .padding()
            
            List {
                ForEach(workoutStorage.criticalForceWorkouts.sorted(by: { $0.date > $1.date })) { workout in
                    CriticalForceWorkoutRow(
                        workout: workout,
                        showRelativeCF: showRelative && selectedMetric == .criticalForce,
                        showRelativeWPrime: showRelative && selectedMetric == .wPrime
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingWorkoutDetail = workout
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
                showingSetup = true
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
        .sheet(isPresented: $showingSetup) {
            WorkoutSetupView { hand, weight in
                navigateToWorkout(hand: hand, bodyweight: weight)
            }
        }
        .sheet(item: $showingWorkoutDetail) { workout in
            CriticalForceDetailView(workout: workout)
        }
        .navigationDestination(isPresented: Binding(
            get: { workoutToShow != nil },
            set: { if !$0 { workoutToShow = nil }}
        )) {
            if let workout = workoutToShow {
                CriticalForceView(
                    bluetoothManager: bluetoothManager,
                    isPresented: Binding(
                        get: { workoutToShow != nil },
                        set: { if !$0 { workoutToShow = nil }}
                    ),
                    selectedHand: workout.hand,
                    bodyweight: workout.bodyweight
                )
            }
        }
    }
    
    private func navigateToWorkout(hand: Hand, bodyweight: Double) {
        workoutToShow = CriticalForceWorkout(
            hand: hand,
            criticalForce: 0,
            wPrime: 0,
            cycles: [],
            completedCycles: 0,
            allMeasurements: [],
            bodyweight: bodyweight
        )
        isShowingWorkout = true
    }
}

struct CriticalForceWorkoutRow: View {
    let workout: CriticalForceWorkout
    let showRelativeCF: Bool
    let showRelativeWPrime: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.date.formatted(date: .long, time: .shortened))
                .font(.headline)
            HStack {
                HandBadgeView(hand: workout.hand)
                Spacer()
                VStack(alignment: .trailing) {
                    if showRelativeCF {
                        Text("CF: \(String(format: "%.0f%% BW", workout.criticalForce / workout.bodyweight * 100))")
                            .bold()
                    } else {
                        Text("CF: \(String(format: "%.1f kg", workout.criticalForce))")
                            .bold()
                    }
                    if showRelativeWPrime {
                        Text("W': \(String(format: "%.1f BW⋅s", workout.wPrime / workout.bodyweight))")
                            .bold()
                    } else {
                        Text("W': \(String(format: "%.0f kg⋅s", workout.wPrime))")
                            .bold()
                    }
                    Text("\(workout.completedCycles)/24 cycles • \(String(format: "%.1f kg", workout.bodyweight)) BW")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
