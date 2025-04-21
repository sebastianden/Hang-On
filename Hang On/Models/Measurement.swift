//
//  Measurement.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import Foundation

struct Measurement: Identifiable {
    let id = UUID()
    let weight: Double
    let timestamp: Date
}
