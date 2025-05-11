//
//  Measurement.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import Foundation

struct Measurement: Identifiable, Codable {
    let id: UUID
    let force: Double
    let timestamp: Date
}
