//
//  MaxForceWorkout.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 26.04.25.
//

import Foundation

struct MaxForceWorkout: Workout {
    let id: UUID
    let date: Date
    let hand: Hand
    let maxForce: Double
    let bodyweight: Double
    
    init(id: UUID = UUID(), date: Date = Date(), hand: Hand, maxForce: Double, bodyweight: Double) {
        self.id = id
        self.date = date
        self.hand = hand
        self.maxForce = maxForce
        self.bodyweight = bodyweight
    }
}

extension MaxForceWorkout: PlottableWorkout {
    var plotValue: Double { maxForce }
    var plotValueRelative: Double { (maxForce / bodyweight) * 100 }  // Convert to percentage
    static var yAxisLabel: String { "Force" }
    static var yAxisLabelRelative: String { "Force (% of bodyweight)" }
    static var yAxisFormat: String { "%.0f kg" }
    static var yAxisFormatRelative: String { "%.0f%%" }
}
