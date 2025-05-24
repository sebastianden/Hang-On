//
//  PlottableWorkout.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import Charts

protocol PlottableWorkout: Workout {
    var plotValue: Double { get }
    static var yAxisLabel: String { get }
    static var yAxisFormat: String { get }
}
