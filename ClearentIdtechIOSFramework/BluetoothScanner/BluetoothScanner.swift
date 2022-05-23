//
//  BluetoothManager.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 14.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothScannerProtocol : AnyObject {
    func didReceivedSignalStrength(level:SignalLevel)
    func didUpdateBluetoothState(isOn: Bool)
    func didFinishWithError()
}

class BluetoothScanner: NSObject {

    private var centralManager: CBCentralManager!
    private var readerUDID: String?
    private weak var delegate: BluetoothScannerProtocol?
    private var device: CBPeripheral?
    
    internal var udid: UUID? {
        didSet {
            setupDevice()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [self] in
                centralManager.stopScan()
            }
        }
    }
    
    // MARK: Init
    
    init(udid:UUID?, delegate: BluetoothScannerProtocol) {
        super.init()
        self.udid = udid
        self.delegate = delegate
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: Public

    public func setupDevice() {
        guard let udid = self.udid else {return}
        let devices = centralManager.retrievePeripherals(withIdentifiers: [udid])
        
        if devices.count == 1 {
            self.device = devices[0]
            self.device?.delegate = self
            // Without connecting to the device from this instance of CBCEntralManager we can't read the RSSI
            centralManager.connect(devices[0], options: nil)
        }
    }

    public func readRSSI() {
        device?.readRSSI()
    }
    
    // MARK: Private
    
    private func levelForRSSI(RSSI: NSNumber) -> SignalLevel {
        var signal = SignalLevel.good
        
        if (RSSI.intValue > -60) {
            signal = SignalLevel.good
        } else if (RSSI.intValue > -80) {
            signal = SignalLevel.medium
        } else {
            signal = SignalLevel.bad
        }
        
        return signal
    }
    
    func cancelPeripheralConnection() {
        guard let device = device else { return }
        centralManager.cancelPeripheralConnection(device)
        udid = nil
    }
}

extension BluetoothScanner: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown, .resetting:
            break
        case .unsupported:
            self.delegate?.didFinishWithError()
        case .unauthorized:
            self.delegate?.didFinishWithError()
        case .poweredOff:
            self.delegate?.didUpdateBluetoothState(isOn: false)
        case .poweredOn:
            self.delegate?.didUpdateBluetoothState(isOn: true)
        @unknown default:
            print("Unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let uuid = self.udid else {return}
        if (peripheral.identifier.uuidString == uuid.uuidString) {
            let signal = levelForRSSI(RSSI: RSSI)
            self.delegate?.didReceivedSignalStrength(level: signal)
            central.stopScan()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        let level = levelForRSSI(RSSI: RSSI)
        self.delegate?.didReceivedSignalStrength(level: level)
    }
}
