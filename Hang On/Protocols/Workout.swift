//
//  Workout.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 11.05.25.
//

import Foundation

enum Hand: String, Codable {
    case left
    case right
}

protocol Workout: Identifiable, Codable {
    var id: UUID { get }
    var date: Date { get }
    var hand: Hand { get }
}
