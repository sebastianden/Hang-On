//
//  LiveChart.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import SwiftUI
import Charts

struct LiveChart: View {
    let measurements: [Measurement]
    let criticalForce: Double?

    init(measurements: [Measurement], criticalForce: Double? = nil) {
        self.measurements = measurements
        self.criticalForce = criticalForce
    }

    var body: some View {
        Chart(measurements) { measurement in
            LineMark(
                x: .value("Time", measurement.timestamp),
                y: .value("Force", measurement.force)
            )
            .interpolationMethod(.stepCenter)
            
            // Check if criticalForce is non-nil and valid (greater than zero)
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
        .frame(height: 300)
        .padding()
    }
}
