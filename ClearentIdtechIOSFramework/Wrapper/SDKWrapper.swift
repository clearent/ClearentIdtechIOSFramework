//
//  SDKWrapper.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 17.03.2022.
//

import Foundation
import CocoaLumberjack


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
         transactionStarted = "TRANSACTION STARTED"
}

public enum UserInfo: String {
    case authorizing = "AUTHORIZING...",
         processing = "PROCESSING..."
}

public enum TransactionError {
    case networkError, insuficientFunds, duplicateTransaction, generalError
}

public protocol SDKWrapperProtocol : AnyObject {
    func didStartPairing()
    func didEncounteredGeneralError()
    func didFinishPairing()
    func didFinishTransaction()
    func didReceiveTransactionError(error:TransactionError)
    func userActionNeeded(action: UserAction)
    func didReceiveInfo(info: UserInfo)
    func deviceDidDisconnect()
}

@objc public final class SDKWrapper : NSObject {
    
    public static let shared = SDKWrapper()
    weak var delegate: SDKWrapperProtocol?
    private var bleManager : BluetoothManager?
    
    private var baseURL: String = ""
    private var apiKey: String = ""
    private var publicKey: String = ""
    
    private var clearentVP3300 = Clearent_VP3300()
    private var connection  = ClearentConnection(bluetoothSearch: ())
    public var readerInfo: ReaderInfo?
    
    private var foundDevice = false
    public var friendlyName : String?
    
    
    @objc public override init() {
        super.init()
        createLogFile()
    }

    // MARK - Public
    
    @objc public func startPairing() {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        clearentVP3300 = Clearent_VP3300.init(connectionHandling: self, clearentVP3300Configuration: config)
        clearentVP3300.start(connection)
        
        self.delegate?.didStartPairing()
    }
    
    @objc public func updateWithInfo(baseURL:String, publicKey: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
    }
    
    @objc public func startTransactionWithAmount(amount: String) {
        SDKWrapper.shared.startDeviceInfoUpdate()
        
        let payment = ClearentPayment.init(sale: ())
        if (amount.canBeConverted(to: String.Encoding.utf8)) {
            payment?.amount = Double(amount) ?? 0
        }
        
        let _ : ClearentResponse = clearentVP3300.startTransaction(payment, clearentConnection: connection)
    }
    
    @objc public func sendTransaction(jwt: String, amount: String) {
        let httpClient = ClearentHttpClient(baseURL: baseURL, apiKey: apiKey)
        httpClient.saleTransaction(jwt: jwt, amount: amount) { data, error in
            DispatchQueue.main.async {
                self.delegate?.didFinishTransaction()
            }
        }
    }
    
    @objc public func isReaderConnected() -> Bool {
        return clearentVP3300.isConnected()
    }
    
    public func startDeviceInfoUpdate() {
        bleManager?.readRSSI()
        getBatterylevel()
    }
    
    public func getBatterylevel() {
        var response : NSData? = NSData()
        _ = clearentVP3300.device_sendIDGCommand(0xF0, subCommand: 0x02, data: nil, response: &response)
                
        if let response = response {
            let batteryLevel = batteryLevelPercentageFrom(level: response.int)
            self.readerInfo?.batterylevel = batteryLevel
        } else {
            self.readerInfo?.batterylevel = nil
        }
    }
        
    private func batteryLevelPercentageFrom(level: Int) -> Int {
        let minim = 192.0
        let maxim = 210.0
        let lvl = Double(level)
        let percentage: Double = Double((lvl - minim) / (maxim - minim) * 100.0)
        return Int(percentage)
    }
    
    
    // MARK - Private
    
    @objc private func updateConnectionWithDevice(bleDeviceID:String, friendly: String?) {
        readerInfo = ReaderInfo(name: friendly, batterylevel: 0, signalLevel: 0, connected: false)

        if let uuid = UUID(uuidString: bleDeviceID) {
            readerInfo?.udid = uuid
            bleManager = BluetoothManager.init(udid: uuid, delegate: self)
        }
        foundDevice = true
        connection?.bluetoothDeviceId = bleDeviceID
        if let name = friendly {
            connection?.fullFriendlyName = name
            friendlyName = name
        }
        connection?.searchBluetooth = false
        clearentVP3300.start(connection)
    }
    
    
    // MARK - Logger Related
    
    public func retriveLoggFileContents() -> String {
        var logs = ""
        let fileInfo = fetchLoggerFileInfo()
        if let newFileInfo = fileInfo {
            if let newLogs = readContentsOfFile(from: newFileInfo.filePath) {
                logs = newLogs
            }
        }
        return logs
    }
    
    public func fetchLogFileURL() -> URL? {
        if let fileInfo = fetchLoggerFileInfo() {
            let urlPath = URL(fileURLWithPath: fileInfo.filePath)
            return urlPath
        }
        return nil
    }
    
    public func clearLogFile() {
        DDLog.allLoggers.forEach { logger in
            if (logger.isKind(of: DDFileLogger.self)) {
                let fileLogger : DDFileLogger = logger as! DDFileLogger
                fileLogger.rollLogFile(withCompletion: nil)
            }
        }
    }
    
    private func createLogFile() {
        DDLog.allLoggers.forEach { logger in
            if (logger.isKind(of: DDFileLogger.self)) {
                let fl : DDFileLogger = logger as! DDFileLogger
                do {
                    if fl.currentLogFileInfo == nil {
                        try fl.logFileManager.createNewLogFile()
                    }
                } catch {
                    print("error logger")
                }
            }
        }
    }
    
    private func fetchLoggerFileInfo() -> DDLogFileInfo? {
        var resultFileInfo : DDLogFileInfo? = nil
        DDLog.allLoggers.forEach { logger in
            if (logger.isKind(of: DDFileLogger.self)) {
                let fileLogger : DDFileLogger = logger as! DDFileLogger
                let fileInfos = fileLogger.logFileManager.sortedLogFileInfos
                resultFileInfo =  (fileInfos.count > 0) ? fileInfos[0] : nil
            }
        }
        
        return resultFileInfo
    }
    
    private func readContentsOfFile(from path: String) -> String? {
        var string: String? = nil
        let urlPath = URL(fileURLWithPath: path)
        do {
            string = try String(contentsOf:urlPath, encoding: .utf8)
        } catch {
            print("Could not read log file.")
        }
        return string
    }
}

extension SDKWrapper : Clearent_Public_IDTech_VP3300_Delegate {
    
    // needs a way to transmit the amount
    public func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {
        sendTransaction(jwt: clearentTransactionToken.jwt, amount: "21.00")
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
            print("Some bluetooth Feedback")
        case .ERROR:
            DispatchQueue.main.async {
                self.delegate?.didEncounteredGeneralError()
            }
        @unknown default:
            DispatchQueue.main.async {
                self.delegate?.didEncounteredGeneralError()
            }
        }
    }
    
    public func bluetoothDevices(_ bluetoothDevices: [ClearentBluetoothDevice]!) {
        // for now we only handle the one device case
        if (bluetoothDevices.count == 1) {
            updateConnectionWithDevice(bleDeviceID: bluetoothDevices[0].deviceId,
                                       friendly: bluetoothDevices[0].friendlyName)
        } else if (bluetoothDevices.count == 0) {
            // most probably the reader is in sleep mode
           // self.delegate?.userActionNeeded(action: UserAction.pressReaderButton)
        }
    }

    public func deviceMessage(_ message: String!) {
        print("Will be deprecated")
    }
    
    public func deviceConnected() {
        readerInfo?.isConnected = true
        bleManager?.setupDevice()
        bleManager?.readRSSI()
        self.delegate?.didFinishPairing()
    }
    
    public func deviceDisconnected() {
        DispatchQueue.main.async {
            self.delegate?.deviceDidDisconnect()
        }
    }
}

extension SDKWrapper: BluetoothManagerProtocol {
    
    func didReceivedSignalStrength(level: SignalLevel) {
        readerInfo?.signalLevel = level.rawValue
    }
    
    func didFinishWithError() {
        self.delegate?.didFinishPairing()
    }
}
