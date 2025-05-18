//
//  Measurement.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import Foundation

struct Measurement: Identifiable, Codable, Equatable {
    let id: UUID
    let force: Double
    let timestamp: Date
    
    static func == (lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.id == rhs.id &&
               lhs.force == rhs.force &&
               lhs.timestamp == rhs.timestamp
    }
}
