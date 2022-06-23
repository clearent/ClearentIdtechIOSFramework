//
//  SDKWrapper.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 17.03.2022.
//

import Foundation
import CocoaLumberjack
import Network

public enum UserAction: String {
    case pleaseWait = "PLEASE WAIT...",
         swipeTapOrInsert = "PLEASE SWIPE, TAP, OR INSERT",
         swipeInsert = "INSERT/SWIPE CARD",
         pressReaderButton = "PRESS BUTTON ON READER",
         removeCard = "CARD READ OK, REMOVE CARD",
         tryICCAgain = "TRY ICC AGAIN",
         goingOnline = "GOING ONLINE",
         cardSecured = "CARD SECURED",
         cardHasChip = "CARD HAS CHIP. TRY INSERT",
         tryMSRAgain = "TRY MSR AGAIN",
         useMagstripe = "USE MAGSTRIPE",
         transactionStarted = "TRANSACTION STARTED",
         tapFailed = "TAP FAILED. INSERT/SWIPE",
         connectionTimeout = "CONNECTION TIMEOUT",
         noInternet = "NO INTERNET",
         noBluetooth = "Bluetooth on this device is currently powered off.",
         noBluetoothPermission = "This app is not authorized to use Bluetooth Low Energy.",
         amountNotAllowedForTap = "Amount is over maximum limit allowed for tap.",
         chipNotRecognized = "Chip not recognized. Pull card out, wait for green led, try swipe.",
         failedToStartSwipe = "Failed to start swipe. Try again but this time pull card out when instructed.",
         cardUnsupported = "Card unsupported"
}

public enum UserInfo: String {
    case authorizing = "AUTHORIZING...",
         processing = "PROCESSING...",
         goingOnline = "GOING ONLINE"
}

public enum TransactionError {
    case networkError, insuficientFunds, duplicateTransaction, generalError
}

public protocol ClearentWrapperProtocol : AnyObject {
    func didStartPairing()
    func didFinishPairing()
    func didReceiveSignalStrength()
    func didFindReaders(readers:[ReaderInfo])
    func deviceDidDisconnect()
    func didNotFindReaders()
    func startedReaderConnection(with reader:ReaderInfo)
    func didFindRecentlyUsedReaders(readers:[ReaderInfo])
    func didNotFindRecentlyUsedReaders()
    func didBeginContinuousSearching()
    func didEncounteredGeneralError()
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?)
    func userActionNeeded(action: UserAction)
    func didReceiveInfo(info: UserInfo)
}

public final class ClearentWrapper : NSObject {
    
    private var baseURL: String = ""
    private var apiKey: String = ""
    private var publicKey: String = ""
    public var previouslyPairedReaders: [ReaderInfo] {
        ClearentWrapperDefaults.recentlyPairedReaders ?? []
    }
    public static let shared = ClearentWrapper()
    public var flowType: ProcessType?
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    weak var delegate: ClearentWrapperProtocol?
    private var connection  = ClearentConnection(bluetoothSearch: ())
    lazy var clearentVP3300: Clearent_VP3300 = {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        return Clearent_VP3300.init(connectionHandling: self, clearentVP3300Configuration: config)
    }()
    private var transactionAmount: String?
    private var tipAmount: String?
    private var bleManager : BluetoothScanner?
    private let monitor = NWPathMonitor()
    private var isInternetOn = false
    private lazy var httpClient: ClearentHttpClient = {
        ClearentHttpClient(baseURL: baseURL, apiKey: apiKey)
    }()
    internal var isBluetoothOn = false
    internal var tipEnabled: Bool? = nil
    internal var shouldSendPressButton = false
    private var continuousSearchingTimer: Timer?
    private var connectToReaderTimer: Timer?
    private var shouldStopUpdatingReadersListDuringContinuousSearching: Bool? = false
    internal var shouldBeginContinuousSearchingForReaders: ((_ searchingEnabled: Bool) -> Void)?
    
    // MARK: Init
    
    private override init() {
        super.init()
        
        createLogFile()
        self.startConnectionListener()
        bleManager = BluetoothScanner.init(udid: nil, delegate: self)
        
        shouldBeginContinuousSearchingForReaders = { searchingEnabled in
            if searchingEnabled {
                self.continuousSearchingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                    guard let strongSelf = self, let _ = strongSelf.shouldStopUpdatingReadersListDuringContinuousSearching else { return }
                    strongSelf.shouldStopUpdatingReadersListDuringContinuousSearching = true
                    strongSelf.startPairing(reconnectIfPossible: false)
                }
            } else {
                self.connection?.searchBluetooth = false
                self.continuousSearchingTimer?.invalidate()
                self.continuousSearchingTimer = nil
                self.shouldStopUpdatingReadersListDuringContinuousSearching = false
            }
        }
    }
    
    // MARK - Public
        
    public func startPairing(reconnectIfPossible: Bool) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            if let readerInfo = ClearentWrapperDefaults.pairedReaderInfo, reconnectIfPossible == true   {
                strongSelf.connection = ClearentConnection(bluetoothWithFriendlyName: readerInfo.readerName)
                DispatchQueue.main.async {
                    strongSelf.startConnectionTimeoutTimer()
                }
            } else {
                strongSelf.connection = ClearentConnection(bluetoothSearch: ())
                DispatchQueue.main.async {
                    guard let shouldStopUpdatingReadersListDuringContinuousSearching = strongSelf.shouldStopUpdatingReadersListDuringContinuousSearching else { return }
                    shouldStopUpdatingReadersListDuringContinuousSearching ? strongSelf.delegate?.didBeginContinuousSearching() : strongSelf.delegate?.didStartPairing()
                }
            }
            strongSelf.clearentVP3300.start(strongSelf.connection)
        }
    }
        
    public func connectTo(reader: ReaderInfo) {
        if reader.uuid != nil {
            DispatchQueue.main.async {
                self.startConnectionTimeoutTimer()
            }
            shouldStopUpdatingReadersListDuringContinuousSearching = nil
            connection  = ClearentConnection(bluetoothWithFriendlyName: reader.readerName)
            updateConnectionWithDevice(readerInfo: reader)
        }
    }
    
    public func cancelTransaction() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.clearentVP3300.emv_cancelTransaction()
            self?.clearentVP3300.device_cancelTransaction()
        }        
    }
     
    public func updateWithInfo(baseURL:String, publicKey: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
    }
    
    public func retryLastTransaction() {
        guard let amount = transactionAmount else {return}        
        startTransaction(with: amount, and: tipAmount)
    }
    
    public func startTransaction(with amount: String, and tip: String?) {

        if (amount.canBeConverted(to: String.Encoding.utf8)) {
            self.transactionAmount = amount
        }
        
        if let newTip = tip, newTip.canBeConverted(to: String.Encoding.utf8) {
            self.tipAmount = newTip
        }

        let userActionNeeded: UserAction? = isInternetOn ? (isBluetoothOn ? nil : .noBluetooth) : .noInternet
        
        if let action = userActionNeeded {
            DispatchQueue.main.async {
                  self.delegate?.userActionNeeded(action: action)
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let strongSelf = self else { return }
                ClearentWrapper.shared.startDeviceInfoUpdate()
                let payment = ClearentPayment.init(sale: ())
                payment?.amount = Double(amount) ?? 0
                strongSelf.clearentVP3300.startTransaction(payment, clearentConnection: strongSelf.connection)
            }
        }
    }
    
    public func searchRecentlyUsedReaders() {
        if let recentlyUsedReaders = ClearentWrapperDefaults.recentlyPairedReaders, recentlyUsedReaders.count > 0 {
            delegate?.didFindRecentlyUsedReaders(readers: recentlyUsedReaders)
        } else {
            delegate?.didNotFindRecentlyUsedReaders()
        }
    }
    
    public func saleTransaction(jwt: String, amount: String, tipAmount: String) {
        httpClient.saleTransaction(jwt: jwt, amount: amount, tipAmount: tipAmount) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    DispatchQueue.main.async {
                        self.delegate?.didFinishTransaction(response: decodedResponse, error: nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.delegate?.didFinishTransaction(response: decodedResponse, error: transactionError)
                }
            } catch let jsonDecodingError {
                print(jsonDecodingError)
            }
        }
    }
    
    public func refundTransaction(jwt: String, amount: String) {
        httpClient.refundTransaction(jwt: jwt, amount: amount) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    DispatchQueue.main.async {
                        self.delegate?.didFinishTransaction(response: decodedResponse, error: nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.delegate?.didFinishTransaction(response: decodedResponse, error: transactionError)
                }
            } catch let jsonDecodingError {
                print(jsonDecodingError)
            }
        }
    }
    
    public func voidTransaction(transactionID: String) {
        httpClient.voidTransaction(transactionID: transactionID) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    DispatchQueue.main.async {
                        self.delegate?.didFinishTransaction(response: decodedResponse, error: nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.delegate?.didFinishTransaction(response: decodedResponse, error: transactionError)
                }
            } catch let jsonDecodingError {
                print(jsonDecodingError)
            }
        }
    }
    
    public func fetchTipSetting(completion: @escaping () -> Void) {
        guard tipEnabled == nil else {
            completion()
            return
        }
        httpClient.merchantSettings() { data, error in
            DispatchQueue.main.async {
                do {
                    guard let data = data else { return }
                    let decodedResponse = try JSONDecoder().decode(MerchantSettings.self, from: data)
                    self.tipEnabled = decodedResponse.payload.terminalSettings.enableTip
                } catch let jsonDecodingError {
                    print(jsonDecodingError)
                }
                completion()
            }
        }
    }
    
    public func isReaderConnected() -> Bool {
        return (ClearentWrapperDefaults.pairedReaderInfo != nil && ClearentWrapperDefaults.pairedReaderInfo?.isConnected == true)
    }
    
    public func startDeviceInfoUpdate() {
        bleManager?.readRSSI()
        getBatterylevel()
        getReaderVersion()
        getSerialNumber()
    }
    
    // MARK - Private
    
    private func startConnectionListener() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.isInternetOn = true
            } else {
                if let action = UserAction(rawValue: UserAction.noInternet.rawValue) {
                    DispatchQueue.main.async {
                        self?.delegate?.userActionNeeded(action: action)
                    }
                }
                self?.isInternetOn = false
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    private func updateConnectionWithDevice(readerInfo: ReaderInfo) {
        if var currentReader =  ClearentWrapperDefaults.pairedReaderInfo {
            currentReader.isConnected = false
            addReaderToRecentlyUsed(reader: currentReader)
        }
        
        ClearentWrapperDefaults.pairedReaderInfo = readerInfo

        if let uuid = readerInfo.uuid {
            bleManager?.udid? = uuid
            bleManager?.setupDevice()
            connection?.bluetoothDeviceId = uuid.uuidString
            connection?.fullFriendlyName = readerInfo.readerName
        }
        
        connection?.searchBluetooth = false
        clearentVP3300.start(connection)
        self.delegate?.startedReaderConnection(with: readerInfo)
    }
    
    public func stopContinousSearching() {
        self.connection?.searchBluetooth = false
        shouldBeginContinuousSearchingForReaders?(false)
        invalidateConnectionTimer()
    }
        
    private func getBatterylevel() {
        var response : NSData? = NSData()
        _ = clearentVP3300.device_sendIDGCommand(0xF0, subCommand: 0x02, data: nil, response: &response)
        guard let response = response else {
            if var currentReader = ClearentWrapperDefaults.pairedReaderInfo {
                currentReader.batterylevel = nil
                ClearentWrapperDefaults.pairedReaderInfo = currentReader
            }
            return
        }
        let curentLevel = response.int
        
        if (curentLevel > 0) {
            let batteryLevel = batteryLevelPercentageFrom(level: response.int)
            if var currentReader = ClearentWrapperDefaults.pairedReaderInfo {
                currentReader.batterylevel = batteryLevel
                ClearentWrapperDefaults.pairedReaderInfo = currentReader
            }
        } else {
            if var currentReader = ClearentWrapperDefaults.pairedReaderInfo {
                currentReader.batterylevel = nil
                ClearentWrapperDefaults.pairedReaderInfo = currentReader
            }
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
    
    private func startConnectionTimeoutTimer() {
        self.shouldSendPressButton = true
        connectToReaderTimer = Timer.scheduledTimer(withTimeInterval: 17, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    if (self?.shouldSendPressButton == true) {
                        self?.delegate?.userActionNeeded(action: .connectionTimeout)
                    }
                }
            }
        }
}

extension ClearentWrapper : Clearent_Public_IDTech_VP3300_Delegate {
    
    public func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {
        guard let amount = transactionAmount else { return }
        // make sure we have two decimals otherwise the API will return an error
        var amountString = String(amount)
        let amountArray = amountString.split(separator: ".")
        
        if (amountArray.last?.count == 1) {
            amountString = amountString + "0"
        }
        
        var tipAmountString = self.tipAmount ?? "0.00"
        let tipAmountArray = tipAmountString.split(separator: ".")
        if (tipAmountArray.last?.count == 1) {
            tipAmountString = tipAmountString + "0"
        }
        
        saleTransaction(jwt: clearentTransactionToken.jwt, amount: amountString, tipAmount: tipAmountString)
    }
    
    public func disconnectFromReader() {
        clearentVP3300.device_disconnectBLE()
        bleManager?.cancelPeripheralConnection()
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
    }
    
    public func feedback(_ clearentFeedback: ClearentFeedback!) {
        
        switch clearentFeedback.feedBackMessageType {
        case .TYPE_UNKNOWN:
            DispatchQueue.main.async {
                self.delegate?.didEncounteredGeneralError()
            }
        case .USER_ACTION:
            if let action = UserAction(rawValue: clearentFeedback.message) {
                DispatchQueue.main.async {
                    self.delegate?.userActionNeeded(action: action)
                }
            }
        case .INFO:
            if let info = UserInfo(rawValue: clearentFeedback.message) {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveInfo(info: info)
                }
            }
        case .BLUETOOTH:
            if (ClearentWrapperDefaults.pairedReaderInfo != nil) {
                if (clearentFeedback.message == UserAction.noBluetooth.rawValue) {
                    if var currentReader = ClearentWrapperDefaults.pairedReaderInfo {
                        currentReader.isConnected = false
                        ClearentWrapperDefaults.pairedReaderInfo = currentReader
                    }
                }
            }
            
            if (clearentFeedback.message == "BLUETOOTH CONNECTED"){
                DispatchQueue.main.async {
                    self.shouldSendPressButton = false
                    self.invalidateConnectionTimer()
                }
            }
        case .ERROR:
            if (ClearentWrapperDefaults.pairedReaderInfo != nil && clearentFeedback.message == UserAction.noBluetooth.rawValue) {
                
                if let action = UserAction(rawValue: clearentFeedback.message) {
                    DispatchQueue.main.async {
                        self.delegate?.userActionNeeded(action: action)
                    }
                }
            } else  if let action = UserAction(rawValue: clearentFeedback.message) {
                DispatchQueue.main.async {
                    self.delegate?.userActionNeeded(action: action)
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.didEncounteredGeneralError()
                }
            }
        @unknown default:
            DispatchQueue.main.async {
                self.delegate?.didEncounteredGeneralError()
            }
        }
    }
    
    public func bluetoothDevices(_ bluetoothDevices: [ClearentBluetoothDevice]!) {
        if (bluetoothDevices.count > 0) {
            let readers = bluetoothDevices.map { readerInfo(from: $0) }
            self.delegate?.didFindReaders(readers: readers)
        } else {
            self.delegate?.didNotFindReaders()
        }
        
        shouldStopUpdatingReadersListDuringContinuousSearching = true
        shouldBeginContinuousSearchingForReaders?(true)
    }

    public func deviceMessage(_ message: String!) {
        print("Will be deprecated")
    }
    
    private func invalidateConnectionTimer() {
        DispatchQueue.main.async {
            self.connectToReaderTimer?.invalidate()
            self.connectToReaderTimer = nil
            self.shouldSendPressButton = false
            print("INVALIDATE TIMER")
        }
    }
    
    public func deviceConnected() {
        invalidateConnectionTimer()
        bleManager?.udid = ClearentWrapperDefaults.pairedReaderInfo?.uuid
        bleManager?.setupDevice()
        startDeviceInfoUpdate()
        // if there is no autojoin reader, set the current connected reader with autojoin true
        if ClearentWrapperDefaults.recentlyPairedReaders?.first(where: { $0.autojoin == true }) == nil {
            ClearentWrapperDefaults.pairedReaderInfo?.autojoin = true
        }
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = true
        self.delegate?.didFinishPairing()
    }
    
    public func deviceDisconnected() {
        DispatchQueue.main.async {
            ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
            self.bleManager?.cancelPeripheralConnection()
            self.delegate?.deviceDidDisconnect()
        }
    }
}
