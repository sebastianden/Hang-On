//
//  Device.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import Foundation

struct Device: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let peripheral: Any // We'll use this to store CBPeripheral without making it public
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}
