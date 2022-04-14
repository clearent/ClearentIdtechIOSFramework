//
//  BluetoothManager.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 14.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerProtocol : AnyObject {
    func didReceivedSignalStrength(level:SignalLevel)
    func didFinishWithError()
}

class BluetoothManager: NSObject {

    private var centralManager: CBCentralManager!
    private var readerUDID: String?
    private var udid: UUID?
    private weak var delegate: BluetoothManagerProtocol?
    private var device: CBPeripheral?
    
    init(udid:UUID, delegate: BluetoothManagerProtocol) {
        super.init()
        self.udid = udid
        self.delegate = delegate
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func setupDevice() {
        guard let udid = self.udid else {return}
        let devices = centralManager.retrievePeripherals(withIdentifiers: [udid])
        
        if devices.count == 1 {
            self.device = devices[0]
            self.device?.delegate = self
            // without connecting to the device from this instance of CBCEntralManager we can't read the RSSI
            centralManager.connect(devices[0], options: nil)
        }
    }

    public func readRSSI() {
        device?.readRSSI()
    }
    
    func levelForRSSI(RSSI: NSNumber) -> SignalLevel {
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
}

extension BluetoothManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            self.delegate?.didFinishWithError()
        case .unauthorized:
            self.delegate?.didFinishWithError()
        case .poweredOff:
            self.delegate?.didFinishWithError()
        case .poweredOn:
            setupDevice()
            central.scanForPeripherals(withServices: nil, options: nil)
        @unknown default:
            print("default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.identifier.uuidString == self.udid!.uuidString) {
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
