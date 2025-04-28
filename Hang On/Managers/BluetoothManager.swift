//
//  BluetoothManager.swift
//  Hang On
//
//  Created by STDG (Sebastian Dengler) on 21.04.25.
//

import CoreBluetooth
import Combine

enum ConnectionState {
    case disconnected
    case scanning
    case connected
}

class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning: Bool = false
    @Published var discoveredDevices: [Device] = []
    @Published var connectionState: ConnectionState = .disconnected
    
    private var centralManager: CBCentralManager?
    private var selectedPeripheral: CBPeripheral?
    let weightService: WeightService
    
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
            self.connectionState = .connected
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
    
    private func decodeWeight(from advertisementData: [String: Any]) -> Double? {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return nil
        }
        
        // We know we have 19 bytes
        guard manufacturerData.count >= 19 else {
            print("Manufacturer data too short")
            return nil
        }
        
        // Looking at the changing parts around the middle
        let weight = ((Int(manufacturerData[12]) & 0xff) << 8) | (Int(manufacturerData[13]) & 0xff)
        let weightKg = Double(weight) / 100.0
        
        return weightKg
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    // Called when Bluetooth state changes
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
    
    // Called when a device is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, name.contains("IF") else { return }
        
        // Add device if not already discovered
        if !discoveredDevices.contains(where: { ($0.peripheral as? CBPeripheral)?.identifier == peripheral.identifier }) {
            let device = Device(name: name, peripheral: peripheral)
            DispatchQueue.main.async {
                self.discoveredDevices.append(device)
            }
        }
        
        // Only process weight data if this is our selected peripheral AND we're recording
        if peripheral == selectedPeripheral && weightService.isRecording {
            if let weight = decodeWeight(from: advertisementData) {
                DispatchQueue.main.async {
                    self.weightService.addMeasurement(weight)
                }
            }
        }
    }
    
    // Called when connection is established
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
        // We still need to scan for updates, but we're now in connected state
        startScanning()
    }

    // Called when device disconnects
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "unknown device")")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.selectedPeripheral = nil
        }
    }
}
