import Foundation

struct CriticalForceCycle: Identifiable, Codable {
    let id: UUID
    let cycleNumber: Int
    let startTime: Date
    let measurements: [Measurement]
    
    init(id: UUID = UUID(), cycleNumber: Int, startTime: Date, measurements: [Measurement]) {
        self.id = id
        self.cycleNumber = cycleNumber
        self.startTime = startTime
        self.measurements = measurements
    }
    
    var averageForce: Double {
        guard !measurements.isEmpty else { return 0 }
        return measurements.map(\.force).reduce(0, +) / Double(measurements.count)
    }
} 
