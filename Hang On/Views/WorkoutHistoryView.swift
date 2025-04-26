//
//  WorkoutHistoryView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import SwiftUI

struct WorkoutHistoryView: View {
    @StateObject private var workoutStorage = WorkoutStorage.shared
    @State private var showingHandSelection = false
    @State private var selectedHand: Workout.Hand?
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var weightService: WeightService
    
    var body: some View {
        VStack {
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
                weightService.reset()  // Reset before showing hand selection
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
            set: { if !$0 {
                selectedHand = nil
                weightService.reset()  // Reset when navigation state changes
            }}
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
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.date.formatted(date: .long, time: .shortened))
                .font(.headline)
            HStack {
                Text(workout.hand.rawValue.capitalized)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f kg", workout.maxForce))
                    .bold()
            }
        }
    }
}
