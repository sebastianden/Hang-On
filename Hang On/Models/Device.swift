//
//  Device.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import CoreBluetooth
import Foundation

struct Device: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let peripheral: CBPeripheral
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}
