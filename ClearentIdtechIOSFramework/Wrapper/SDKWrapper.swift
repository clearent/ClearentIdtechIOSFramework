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
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?)
    func userActionNeeded(action: UserAction)
    func didReceiveInfo(info: UserInfo)
    func deviceDidDisconnect()
}

@objc public final class SDKWrapper : NSObject {
    
    public static let shared = SDKWrapper()
    private var baseURL: String = ""
    private var apiKey: String = ""
    private var publicKey: String = ""
    private var clearentVP3300 = Clearent_VP3300()
    private var connection  = ClearentConnection(bluetoothSearch: ())
    private var foundDevice = false
    weak var delegate: SDKWrapperProtocol?
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
    
    public func cancelTransaction() {
        clearentVP3300.emv_cancelTransaction()
    }
    
    @objc public func updateWithInfo(baseURL:String, publicKey: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
    }
    
    @objc public func startTransactionWithAmount(amount: String) {
        
        clearentVP3300.emv_cancelTransaction()
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
                guard let responseData = data else { return }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                    
                    guard let transactionError = decodedResponse.payload.error else {
                        self.delegate?.didFinishTransaction(response: decodedResponse, error: nil)
                        return
                    }
                    self.delegate?.didFinishTransaction(response: decodedResponse, error: transactionError)
                } catch let jsonDecodingError {
                    print(jsonDecodingError)
                }
            }
        }
    }
    
    @objc public func isReaderConnected() -> Bool {
        return clearentVP3300.isConnected()
    }
    
    // MARK - Private
    
    @objc private func updateConnectionWithDevice(bleDeviceID:String, friendly: String?) {
        foundDevice = true
        connection?.bluetoothDeviceId = bleDeviceID
        if let name = friendly {
            connection?.fullFriendlyName = name
            friendlyName = name
        }
        connection?.searchBluetooth = false
        //connection?.readerInterfaceMode = ._2_IN_1
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
            } else {
                bluetoothDevices.forEach { device in
                    if (device.friendlyName == "IDTECH-VP3300-27224") {
                        updateConnectionWithDevice(bleDeviceID: device.deviceId,
                                                   friendly: device.friendlyName)
                    }
                }
            }
        }

    public func deviceMessage(_ message: String!) {
        if (message == "BLUETOOTH CONNECTED") {
            DispatchQueue.main.async {
                self.delegate?.didFinishPairing()
            }
        }
    }
    
    public func deviceConnected() {
        DispatchQueue.main.async {
            self.delegate?.didFinishPairing()
        }
    }
    
    public func deviceDisconnected() {
        DispatchQueue.main.async {
            self.delegate?.deviceDidDisconnect()
        }
    }
}
