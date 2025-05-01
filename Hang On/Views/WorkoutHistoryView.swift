//
//  WorkoutHistoryView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import SwiftUI
import Charts

struct WorkoutHistoryView: View {
    @StateObject private var workoutStorage = WorkoutStorage.shared
    @State private var showingHandSelection = false
    @State private var selectedHand: Workout.Hand?
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var weightService: WeightService
    
    var body: some View {
        VStack {
            HistoryChartView(workouts: workoutStorage.workouts)
                .frame(height: 200)
                .padding()
            
            List {
                ForEach(workoutStorage.workouts.sorted(by: { $0.date > $1.date })) { workout in
                    WorkoutRow(workout: workout)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let workout = workoutStorage.workouts.sorted(by: { $0.date > $1.date })[index]
                        workoutStorage.deleteWorkout(workout)
                    }
                }
            }
            
            Button(action: {
                showingHandSelection = true
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
        .navigationTitle("Workout History")
        .sheet(isPresented: $showingHandSelection) {
            HandSelectionView { hand in
                selectedHand = hand
                showingHandSelection = false
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedHand != nil },
            set: { if !$0 { selectedHand = nil }}
        )) {
            if let hand = selectedHand {
                MaxForceView(
                    bluetoothManager: bluetoothManager,
                    weightService: weightService,
                    selectedHand: hand
                )
            }
        }
    }
}

struct HistoryChartView: View {
    let workouts: [Workout]
    
    private var leftHandData: [Workout] {
        workouts.filter { $0.hand == .left }.sorted { $0.date < $1.date }
    }
    
    private var rightHandData: [Workout] {
        workouts.filter { $0.hand == .right }.sorted { $0.date < $1.date }
    }
    
    private var maxForce: Double {
        let maxLeft = leftHandData.map { $0.maxForce }.max() ?? 0
        let maxRight = rightHandData.map { $0.maxForce }.max() ?? 0
        return max(maxLeft, maxRight)
    }
    
    var body: some View {
        Chart {
            ForEach(leftHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("Force", workout.maxForce)
                )
                .foregroundStyle(Color.green)
            }
            .symbol(by: .value("Hand", "Left"))
            
            ForEach(rightHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value("Force", workout.maxForce)
                )
                .foregroundStyle(Color.blue)
            }
            .symbol(by: .value("Hand", "Right"))
        }
        .chartYScale(domain: 0...(maxForce * 1.1))
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

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.date.formatted(date: .long, time: .shortened))
                .font(.headline)
            HStack {
                HandBadgeView(hand: workout.hand)
                Spacer()
                Text(String(format: "%.1f kg", workout.maxForce))
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
}

struct HandBadgeView: View {
    let hand: Workout.Hand
    
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
