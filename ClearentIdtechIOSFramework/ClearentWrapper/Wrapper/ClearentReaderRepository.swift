//
//  ClearentReaderRepository.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 20.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CoreBluetooth

protocol ReaderRepositoryProtocol {
    var delegate: ClearentWrapperProtocol? { get set }
    var isBluetoothPermissionGranted: Bool { get }
    var isBluetoothOn: Bool { get }
    var isInternetOn: Bool { get set }
    func startPairing(reconnectIfPossible: Bool)
    func connectTo(reader: ReaderInfo)
    func startTransaction(payment: ClearentPayment?)
    func cancelTransaction()
    func isReaderConnected() -> Bool
    func startDeviceInfoUpdate()
    func stopContinousSearching()
    func isReaderEncrypted() -> Bool?
    func searchRecentlyUsedReaders()
    func disconnectFromReader()
    func bluetoothDevices(_ bluetoothDevices: [ClearentBluetoothDevice]!)
    func updateReaderInRecentlyUsed(reader: ReaderInfo)
    func removeReaderFromRecentlyUsed(reader: ReaderInfo)
    func addReaderToRecentlyUsed(reader: ReaderInfo)
    func invalidateConnectionTimer()
    func deviceConnected()
    func deviceDisconnected()
    func cardReaderTransaction()
}

class ReaderRepository: ReaderRepositoryProtocol {
    var delegate: ClearentWrapperProtocol?
    var isInternetOn = false
    var isBluetoothOn = false
    private let clearentVP3300: Clearent_VP3300
    private var connection: ClearentConnection = ClearentConnection(bluetoothSearch: ())
    private var shouldStopUpdatingReadersListDuringContinuousSearching: Bool? = false
    private var bleManager: BluetoothScanner?
    private var continuousSearchingTimer: Timer?
    private var connectToReaderTimer: Timer?
    private var shouldBeginContinuousSearchingForReaders: ((_ searchingEnabled: Bool) -> Void)?
    private var shouldSendPressButton = false
    
    // MARK: - Init

    init(clearentVP3300: Clearent_VP3300) {
        self.clearentVP3300 = clearentVP3300
        self.bleManager = BluetoothScanner.init(udid: nil, delegate: self)
        
        shouldBeginContinuousSearchingForReaders = { [weak self] searchingEnabled in
            if searchingEnabled {
                self?.continuousSearchingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                    guard let strongSelf = self, let _ = strongSelf.shouldStopUpdatingReadersListDuringContinuousSearching else { return }
                    strongSelf.shouldStopUpdatingReadersListDuringContinuousSearching = true
                    strongSelf.startPairing(reconnectIfPossible: false)
                }
            } else {
                self?.connection.searchBluetooth = false
                self?.continuousSearchingTimer?.invalidate()
                self?.continuousSearchingTimer = nil
                self?.shouldStopUpdatingReadersListDuringContinuousSearching = false
            }
        }
    }
    
    // MARK: - Internal
    
    func startPairing(reconnectIfPossible: Bool) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            if let readerInfo = ClearentWrapperDefaults.pairedReaderInfo, reconnectIfPossible == true   {
                strongSelf.connection = ClearentConnection(bluetoothWithFriendlyName: readerInfo.readerName)
                DispatchQueue.main.async {
                    strongSelf.startConnectionTimeoutTimer()
                }
            } else {
                strongSelf.connection = ClearentConnection(bluetoothSearch: ())
                DispatchQueue.main.async { [weak self] in
                    guard let shouldStopUpdatingReadersListDuringContinuousSearching = strongSelf.shouldStopUpdatingReadersListDuringContinuousSearching else { return }
                    shouldStopUpdatingReadersListDuringContinuousSearching ? self?.delegate?.didBeginContinuousSearching() : self?.delegate?.didStartPairing()
                }
            }
            strongSelf.clearentVP3300.start(strongSelf.connection)
        }
    }
    
    func connectTo(reader: ReaderInfo) {
        if reader.uuid != nil {
            DispatchQueue.main.async {
                self.startConnectionTimeoutTimer()
            }
            shouldStopUpdatingReadersListDuringContinuousSearching = nil
            connection  = ClearentConnection(bluetoothWithFriendlyName: reader.readerName)
            updateConnectionWithDevice(readerInfo: reader)
        }
    }
    
    func searchRecentlyUsedReaders() {
        if let recentlyUsedReaders = ClearentWrapperDefaults.recentlyPairedReaders, recentlyUsedReaders.count > 0 {
            delegate?.didFindRecentlyUsedReaders(readers: recentlyUsedReaders)
        } else {
            delegate?.didFindRecentlyUsedReaders(readers: [])
        }
    }
    
    func startTransaction(payment: ClearentPayment?) {
        clearentVP3300.startTransaction(payment, clearentConnection: connection)
    }
    
    func cancelTransaction() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.clearentVP3300.device_cancelTransaction()
        }
    }
    
    func isReaderConnected() -> Bool {
        ClearentWrapperDefaults.pairedReaderInfo != nil && ClearentWrapperDefaults.pairedReaderInfo?.isConnected == true
    }
    
    func disconnectFromReader() {
        clearentVP3300.device_disconnectBLE()
        bleManager?.cancelPeripheralConnection()
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
    }
    
    func startDeviceInfoUpdate() {
        bleManager?.readRSSI()
        getBatterylevel()
        getReaderVersion()
        getSerialNumber()
    }
    
    func stopContinousSearching() {
        connection.searchBluetooth = false
        shouldBeginContinuousSearchingForReaders?(false)
        invalidateConnectionTimer()
    }
    
    func isReaderEncrypted() -> Bool? {
        ClearentWrapperDefaults.pairedReaderInfo?.encrypted
    }
    
    func deviceConnected() {
        invalidateConnectionTimer()
        bleManager?.udid = ClearentWrapperDefaults.pairedReaderInfo?.uuid
        bleManager?.setupDevice()
        startDeviceInfoUpdate()
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = true
        self.delegate?.didFinishPairing()
    }
    
    func deviceDisconnected() {
        DispatchQueue.main.async {
            ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
            self.bleManager?.cancelPeripheralConnection()
            self.delegate?.deviceDidDisconnect()
        }
    }
    
    func bluetoothDevices(_ bluetoothDevices: [ClearentBluetoothDevice]!) {
        if (bluetoothDevices.count > 0) {
            let readers = bluetoothDevices.map { readerInfo(from: $0) }
            self.delegate?.didFindReaders(readers: readers)
        } else {
            self.delegate?.didFindReaders(readers: [])
        }
        
        shouldStopUpdatingReadersListDuringContinuousSearching = true
        shouldBeginContinuousSearchingForReaders?(true)
    }
    
    func addReaderToRecentlyUsed(reader: ReaderInfo) {
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders, !existingReaders.isEmpty else {
            ClearentWrapperDefaults.recentlyPairedReaders = [reader]
            return
        }
        if let defaultReaderIndex = existingReaders.firstIndex(where: { $0 == reader }) {
            existingReaders[defaultReaderIndex] = reader
        } else {
            existingReaders.insert(reader, at: 0)
        }
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
    }
    
    func updateReaderInRecentlyUsed(reader: ReaderInfo) {
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders, !existingReaders.isEmpty else { return }
        if let defaultReaderIndex = existingReaders.firstIndex(where: { $0 == reader }) {
            existingReaders[defaultReaderIndex] = reader
        }
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
    }
    
    func removeReaderFromRecentlyUsed(reader: ReaderInfo) {
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders else { return }
        existingReaders.removeAll(where: { $0 == reader })
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
    }
    
    func readerFromRecentlyPaired(uuid: UUID?) -> ReaderInfo? {
        ClearentWrapperDefaults.recentlyPairedReaders?.first {
            $0.uuid == uuid
        }
    }
    
    func readerInfo(from clearentDevice:ClearentBluetoothDevice) -> ReaderInfo {
        let uuid: UUID? = UUID(uuidString: clearentDevice.deviceId)
        let customReader = readerFromRecentlyPaired(uuid: uuid)
            
        return ReaderInfo(readerName: clearentDevice.friendlyName, customReaderName: customReader?.customReaderName, batterylevel: nil, signalLevel: nil, isConnected: clearentDevice.connected, autojoin: customReader?.autojoin ?? false, uuid: uuid, serialNumber: nil, version: nil, encrypted: nil)
    }
    
    func invalidateConnectionTimer() {
        DispatchQueue.main.async {
            self.connectToReaderTimer?.invalidate()
            self.connectToReaderTimer = nil
            self.shouldSendPressButton = false
        }
    }
    
    func cardReaderTransaction() {
        let dispatchQueue = DispatchQueue(label: "xsdk.UserInteractiveQueue", qos: .userInteractive, attributes: .concurrent)
        dispatchQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.startDeviceInfoUpdate()
            let payment = ClearentPayment.init(sale: ())
            strongSelf.startTransaction(payment: payment)
        }
    }
    
    // MARK: - Private

    private func startConnectionTimeoutTimer() {
        self.shouldSendPressButton = true
        connectToReaderTimer = Timer.scheduledTimer(withTimeInterval: 17, repeats: false) { [weak self] _ in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if strongSelf.shouldSendPressButton && strongSelf.isBluetoothOn && strongSelf.isInternetOn {
                    strongSelf.delegate?.userActionNeeded(action: .connectionTimeout)
                }
            }
        }
    }
    
    private func updateConnectionWithDevice(readerInfo: ReaderInfo) {
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
        ClearentWrapperDefaults.pairedReaderInfo = readerInfo

        if let uuid = readerInfo.uuid {
            bleManager?.udid? = uuid
            bleManager?.setupDevice()
            connection.bluetoothDeviceId = uuid.uuidString
            connection.fullFriendlyName = readerInfo.readerName
        }
        
        connection.searchBluetooth = false
        clearentVP3300.start(connection)
        delegate?.startedReaderConnection(with: readerInfo)
    }
    
    private func getBatterylevel() {
        var response : NSData? = NSData()
        _ = clearentVP3300.device_sendIDGCommand(0xF0, subCommand: 0x02, data: nil, response: &response)
        guard let response = response else {
            ClearentWrapperDefaults.pairedReaderInfo?.batterylevel = nil
            return
        }
        let curentLevel = response.int
        
        if (curentLevel > 0) {
            let batteryLevel = batteryLevelPercentageFrom(level: response.int)
            ClearentWrapperDefaults.pairedReaderInfo?.batterylevel = batteryLevel
        } else {
            ClearentWrapperDefaults.pairedReaderInfo?.batterylevel = nil
        }
    }
    
    private func getReaderVersion() {
        var response: NSString? = NSString()
        _ = clearentVP3300.device_getFirmwareVersion(&response)
        guard let response = response else { return }
        ClearentWrapperDefaults.pairedReaderInfo?.version = response.description
    }
    
    private func getSerialNumber() {
        var response: NSString? = NSString()
        _ = clearentVP3300.config_getSerialNumber(&response)
        guard let response = response else { return }
        ClearentWrapperDefaults.pairedReaderInfo?.serialNumber = response.description
    }
        
    private func batteryLevelPercentageFrom(level: Int) -> Int {
        let minim = 192.0
        let maxim = 210.0
        let lvl = min(maxim, Double(level))
        var percentage: Double = Double((lvl - minim) / (maxim - minim) * 100.0)
        percentage = min(percentage, 100)
        var result = 0
        
        if percentage > 95 { result = 100 }
        else if percentage > 75 { result = 75 }
        else if percentage > 50 { result = 50 }
        else if percentage > 25 { result = 25 }
        else if percentage > 5 { result = 5 }
        return result
    }
}

extension ReaderRepository: BluetoothScannerProtocol {
    var isBluetoothPermissionGranted: Bool {
        if #available(iOS 13.1, *) {
            return CBCentralManager.authorization == .allowedAlways
        } else if #available(iOS 13.0, *) {
            return CBCentralManager().authorization == .allowedAlways
        }
        
        // Before iOS 13, Bluetooth permissions are not required
        return true
    }
    
    func didUpdateBluetoothState(isOn: Bool) {
        isBluetoothOn = isOn
        
        if (!isBluetoothOn) {
            disconnectFromReader()
        }
    }
    
    internal func didReceivedSignalStrength(level: SignalLevel) {
        ClearentWrapperDefaults.pairedReaderInfo?.signalLevel = level.rawValue
        delegate?.didReceiveSignalStrength()
    }
    
    internal func didFinishWithError() {
        delegate?.didFinishPairing()
    }
}
