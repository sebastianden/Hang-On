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
    
    init(id: UUID = UUID(), date: Date = Date(), hand: Hand, maxForce: Double) {
        self.id = id
        self.date = date
        self.hand = hand
        self.maxForce = maxForce
    }
}
