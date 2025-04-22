//
//  BluetoothManager.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning: Bool = false
    @Published var discoveredDevices: [Device] = []
    @Published var connectionState: ConnectionState = .disconnected
    
    enum ConnectionState {
        case disconnected
        case scanning
        case connected
    }
    
    private var centralManager: CBCentralManager?
    private var selectedPeripheral: CBPeripheral?
    private var weightService: WeightService
    
    init(weightService: WeightService) {
        self.weightService = weightService
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager?.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        print("Starting to scan for devices...")
        isScanning = true
        // Only update connection state to scanning if we're not already connected
        if connectionState != .connected {
            connectionState = .scanning
        }
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScanning() {
        print("Stopping scan")
        isScanning = false
        centralManager?.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }
    
    func connectToDevice(_ device: Device) {
        guard let peripheral = device.peripheral as? CBPeripheral else { return }
        print("Attempting to connect to device: \(device.name)")
        selectedPeripheral = peripheral
        DispatchQueue.main.async {
            self.connectionState = .connected  // Update state when connecting
        }
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = selectedPeripheral {
            print("Disconnecting from device")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        selectedPeripheral = nil
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
    
    private func decodeWeight(from manufacturerData: Data) -> (weight: Double, stable: Int, unit: Int)? {
        print("Raw manufacturer data: \(manufacturerData.map { String(format: "%02X", $0) }.joined())")
        
        guard manufacturerData.count >= 15 else {
            print("Manufacturer data too short")
            return nil
        }
        
        // Print individual bytes for debugging
        print("Weight bytes: \(String(format: "%02X", manufacturerData[10])) \(String(format: "%02X", manufacturerData[11]))")
        print("Status byte: \(String(format: "%02X", manufacturerData[14]))")
        
        let weight = ((Int(manufacturerData[10]) & 0xff) << 8) | (Int(manufacturerData[11]) & 0xff)
        let statusByte = manufacturerData[14]
        let stable = Int((statusByte & 0xf0) >> 4)
        let unit = Int(statusByte & 0x0f)
        
        print("Status byte decoded: stable=\(stable) (raw: \(String(format: "%04b", stable))), unit=\(unit) (raw: \(String(format: "%04b", unit)))")
        
        let weightKg = Double(weight) / 100.0
        print("Decoded: weight=\(weightKg)kg, stable=\(stable), unit=\(unit)")
        
        return (weightKg, stable, unit)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
            connectionState = .disconnected
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is unsupported")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unknown Bluetooth state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let name = peripheral.name, name.contains("IF") else { return }
        
        // Add device if not already discovered
        if !discoveredDevices.contains(where: { ($0.peripheral as? CBPeripheral)?.identifier == peripheral.identifier }) {
            let device = Device(name: name, peripheral: peripheral)
            DispatchQueue.main.async {
                self.discoveredDevices.append(device)
            }
        }
        
        // Process weight data if this is our selected peripheral
        if peripheral == selectedPeripheral {
            print("Processing data from selected peripheral: \(name)")
            // Get manufacturer data
            guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
                print("No manufacturer data found")
                return
            }
            
            // Convert manufacturer data to companies dictionary
            var companies: [UInt16: Data] = [:]
            var index = manufacturerData.startIndex
            while index < manufacturerData.endIndex {
                let companyID = manufacturerData[index..<min(index + 2, manufacturerData.endIndex)].withUnsafeBytes { $0.load(as: UInt16.self) }
                index += 2
                let length = min(manufacturerData.endIndex - index, manufacturerData.count - index)
                let data = manufacturerData[index..<min(index + length, manufacturerData.endIndex)]
                companies[companyID] = Data(data)
                index += length
            }
            
            // Check for company ID 256 (0x0100)
            guard let scaleData = companies[256] else {
                print("No data for company ID 256")
                return
            }
            
            if let (weight, stable, _) = decodeWeight(from: scaleData) {
                print("Processing weight: \(weight)kg (stable: \(stable))")
                
                DispatchQueue.main.async {
                    self.weightService.addMeasurement(weight)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
        // We still need to scan for updates, but we're now in connected state
        startScanning()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "unknown device")")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.selectedPeripheral = nil
        }
    }
}
