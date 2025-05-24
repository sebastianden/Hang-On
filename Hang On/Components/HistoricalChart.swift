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
    let valueProvider: (T) -> Double
    let yAxisLabel: String
    let yAxisFormat: String
    
    static func defaultValueProvider(_ workout: T) -> Double {
        workout.plotValue
    }
    
    init(
        workouts: [T],
        valueProvider: @escaping (T) -> Double = Self.defaultValueProvider,
        yAxisLabel: String = T.yAxisLabel,
        yAxisFormat: String = T.yAxisFormat
    ) {
        self.workouts = workouts
        self.valueProvider = valueProvider
        self.yAxisLabel = yAxisLabel
        self.yAxisFormat = yAxisFormat
    }
    
    private var leftHandData: [T] {
        workouts.filter { $0.hand == .left }.sorted { $0.date < $1.date }
    }
    
    private var rightHandData: [T] {
        workouts.filter { $0.hand == .right }.sorted { $0.date < $1.date }
    }
    
    private var maxValue: Double {
        let maxLeft = leftHandData.map(valueProvider).max() ?? 0
        let maxRight = rightHandData.map(valueProvider).max() ?? 0
        return max(maxLeft, maxRight)
    }
    
    var body: some View {
        Chart {
            ForEach(leftHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value(yAxisLabel, valueProvider(workout))
                )
                .foregroundStyle(Color.green)
            }
            .symbol(by: .value("Hand", "Left"))
            
            ForEach(rightHandData) { workout in
                LineMark(
                    x: .value("Date", workout.date),
                    y: .value(yAxisLabel, valueProvider(workout))
                )
                .foregroundStyle(Color.blue)
            }
            .symbol(by: .value("Hand", "Right"))
        }
        .chartYScale(domain: 0...maxValue * 1.1)
        .chartForegroundStyleScale([
            "Left": .green,
            "Right": .blue
        ])
        .chartLegend(position: .top)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let val = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: yAxisFormat, val))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks {}
        }
    }
}
