//
//  CriticalForceDetailView.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import SwiftUI
import Charts

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
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            
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
