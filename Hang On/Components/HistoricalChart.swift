//
//  HistoricalChart.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import SwiftUI
import Charts

struct HistoricalChart<T: PlottableWorkout>: View {
    let workouts: [T]
    
    private var leftHandData: [T] {
        workouts.filter { $0.hand == .left }.sorted { $0.date < $1.date }
    }
    
    private var rightHandData: [T] {
        workouts.filter { $0.hand == .right }.sorted { $0.date < $1.date }
    }
    
    private var maxValue: T.ValueType {
        let maxLeft = leftHandData.map { $0.plotValue }.max() ?? 0
        let maxRight = rightHandData.map { $0.plotValue }.max() ?? 0
        return max(maxLeft, maxRight)
    }
    
    var body: some View {
        Chart {
            ForEach(leftHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value(T.yAxisLabel, workout.plotValue)
                )
                .foregroundStyle(Color.green)
            }
            .symbol(by: .value("Hand", "Left"))
            
            ForEach(rightHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value(T.yAxisLabel, workout.plotValue)
                )
                .foregroundStyle(Color.blue)
            }
            .symbol(by: .value("Hand", "Right"))
        }
        .chartYScale(domain: 0...Double(maxValue) * 1.1)
        .chartForegroundStyleScale([
            "Left": .green,
            "Right": .blue
        ])
        .chartLegend(position: .top)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let val = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: T.yAxisFormat, val))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks {}
        }
    }
}
