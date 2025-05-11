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
                HistoricalChart(workouts: workouts)
                    .frame(height: 200)
            case .wPrime:
                HistoricalChart(workouts: workouts.map(WPrimeWorkout.init))
                    .frame(height: 200)
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
