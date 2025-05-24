//
//  WorkoutHistoryView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import SwiftUI
import Charts

struct MaxForceHistoryView: View {
    @StateObject private var workoutStorage = WorkoutStorage.shared
    @State private var showingSetup = false
    @State private var selectedWorkout: MaxForceWorkout?
    @State private var showRelative = false
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var weightService: WeightService
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                HStack {
                    Picker("Metric", selection: $showRelative) {
                        Text("Abs").tag(false)
                        Text("% BW").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                if showRelative {
                    HistoricalChart(
                        workouts: workoutStorage.maxForceWorkouts,
                        valueProvider: { $0.plotValueRelative },
                        yAxisLabel: MaxForceWorkout.yAxisLabelRelative,
                        yAxisFormat: MaxForceWorkout.yAxisFormatRelative
                    )
                    .frame(height: 200)
                } else {
                    HistoricalChart(
                        workouts: workoutStorage.maxForceWorkouts,
                        valueProvider: { $0.plotValue },
                        yAxisLabel: MaxForceWorkout.yAxisLabel,
                        yAxisFormat: MaxForceWorkout.yAxisFormat
                    )
                    .frame(height: 200)
                }
            }
            .padding()
            
            List {
                ForEach(workoutStorage.maxForceWorkouts.sorted(by: { $0.date > $1.date })) { workout in
                    WorkoutRow(workout: workout, showRelative: showRelative)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let workout = workoutStorage.maxForceWorkouts.sorted(by: { $0.date > $1.date })[index]
                        workoutStorage.deleteMaxForceWorkout(workout)
                    }
                }
            }
            
            Button(action: {
                showingSetup = true
            }) {
                Text("Start New Measurement")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Max Force History")
        .sheet(isPresented: $showingSetup) {
            WorkoutSetupView { hand, weight in
                navigateToWorkout(hand: hand, bodyweight: weight)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedWorkout != nil },
            set: { if !$0 { selectedWorkout = nil }}
        )) {
            if let workout = selectedWorkout {
                MaxForceView(
                    bluetoothManager: bluetoothManager,
                    weightService: weightService,
                    selectedHand: workout.hand,
                    bodyweight: workout.bodyweight
                )
            }
        }
    }
    
    private func navigateToWorkout(hand: Hand, bodyweight: Double) {
        selectedWorkout = MaxForceWorkout(
            hand: hand,
            maxForce: 0,
            bodyweight: bodyweight
        )
    }
}

struct WorkoutRow: View {
    let workout: MaxForceWorkout
    let showRelative: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.date.formatted(date: .long, time: .shortened))
                .font(.headline)
            HStack {
                HandBadgeView(hand: workout.hand)
                Spacer()
                VStack(alignment: .trailing) {
                    if showRelative {
                        Text(String(format: "%.0f%% BW", workout.plotValueRelative))
                            .bold()
                        Text("\(String(format: "%.1f kg", workout.bodyweight)) BW")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(format: "%.1f kg", workout.maxForce))
                            .bold()
                        Text("\(String(format: "%.1f kg", workout.bodyweight)) BW")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HandBadgeView: View {
    let hand: Hand
    
    var backgroundColor: Color {
        switch hand {
        case .left:
            return .green
        case .right:
            return .blue
        }
    }
    
    var body: some View {
        Text(hand.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}
