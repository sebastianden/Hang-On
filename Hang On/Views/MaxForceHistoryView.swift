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
    @State private var showingHandSelection = false
    @State private var selectedHand: Hand?
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var weightService: WeightService
    
    var body: some View {
        VStack {
            HistoricalChart(workouts: workoutStorage.maxForceWorkouts)
                .frame(height: 200)
                .padding()
            
            List {
                ForEach(workoutStorage.maxForceWorkouts.sorted(by: { $0.date > $1.date })) { workout in
                    WorkoutRow(workout: workout)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let workout = workoutStorage.maxForceWorkouts.sorted(by: { $0.date > $1.date })[index]
                        workoutStorage.deleteMaxForceWorkout(workout)
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


struct WorkoutRow: View {
    let workout: MaxForceWorkout
    
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
