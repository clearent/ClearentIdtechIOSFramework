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

    public func readRSSI() {

        let items = centralManager.retrievePeripherals(withIdentifiers: [self.udid!])
        if (items.count == 1 && device?.delegate != nil) {
            device = items[0]
            if (device?.state == .connected) {
                device?.delegate = self
            } else {
                centralManager.connect(device!, options: nil)
            }
        }
        
        device?.readRSSI()
    }
    
    func levelForRSSI(RSSI: NSNumber) -> SignalLevel {
        var signal = SignalLevel.good
        
        if (RSSI.intValue < -60) {
            signal = SignalLevel.medium
        }
        
        if (RSSI.intValue < -80) {
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
            central.scanForPeripherals(withServices: nil, options: nil)
        @unknown default:
            print("default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.identifier.uuidString == self.udid!.uuidString) {
            device = peripheral
            device?.delegate = self
            
            

            var signal = SignalLevel.good
            
            if (RSSI.intValue < -60) {
                signal = SignalLevel.medium
            }
            
            if (RSSI.intValue < -80) {
                signal = SignalLevel.bad
            }

            self.delegate?.didReceivedSignalStrength(level: signal)
            centralManager.stopScan()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
       // guard error != nil else { return }
        let level = levelForRSSI(RSSI: RSSI)
        self.delegate?.didReceivedSignalStrength(level: level)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        peripheral.readRSSI()
    }
}
