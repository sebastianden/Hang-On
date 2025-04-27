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
    @State private var selectedHand: Workout.Hand?
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedWorkout: CriticalForceWorkout?
    
    var body: some View {
        VStack {
            CriticalForceHistoryChartView(workouts: workoutStorage.criticalForceWorkouts)
                .frame(height: 200)
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
                .interpolationMethod(.catmullRom)
            }
            .symbol(by: .value("Hand", "Left"))
            
            ForEach(rightHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("Critical Force", workout.criticalForce)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
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
                    Text(String(format: "%.1f kg", workout.criticalForce))
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
                    
                    // Cycles Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Force Profile")
                            .font(.title2)
                            .bold()
                        
                        Chart {
                            ForEach(workout.cycles) { cycle in
                                ForEach(cycle.measurements) { measurement in
                                    LineMark(
                                        x: .value("Time", measurement.timestamp),
                                        y: .value("Force", measurement.force)
                                    )
                                }
                                .foregroundStyle(by: .value("Cycle", cycle.cycleNumber))
                            }
                            
                            RuleMark(
                                y: .value("Critical Force", workout.criticalForce)
                            )
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .trailing) {
                                Text("Critical Force")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(height: 300)
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
