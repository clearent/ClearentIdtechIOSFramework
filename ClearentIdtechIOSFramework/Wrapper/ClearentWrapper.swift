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

public protocol ClearentWrapperProtocol : AnyObject {
    func didStartPairing()
    func didEncounteredGeneralError()
    func didFinishPairing()
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?)
    func userActionNeeded(action: UserAction)
    func didReceiveInfo(info: UserInfo)
    func deviceDidDisconnect()
}

@objc public final class ClearentWrapper : NSObject {
    
    public static let shared = ClearentWrapper()
    private var baseURL: String = ""
    private var apiKey: String = ""
    private var publicKey: String = ""
    private var clearentVP3300 = Clearent_VP3300()
    private var connection  = ClearentConnection(bluetoothSearch: ())
    private var foundDevice = false
    weak var delegate: ClearentWrapperProtocol?
    public var friendlyName : String?
    private var transactionAmount: String?
    
    private var bleManager : BluetoothScanner?
    public var readerInfo: ReaderInfo?
    
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
        ClearentWrapper.shared.startDeviceInfoUpdate()

        let payment = ClearentPayment.init(sale: ())
        if (amount.canBeConverted(to: String.Encoding.utf8)) {
            payment?.amount = Double(amount) ?? 0
            transactionAmount = amount
        }
        
        let _ : ClearentResponse = clearentVP3300.startTransaction(payment, clearentConnection: connection)
    }
    
    @objc public func saleTransaction(jwt: String, amount: String) {
        let httpClient = ClearentHttpClient(baseURL: baseURL, apiKey: apiKey)
        httpClient.saleTransaction(jwt: jwt, amount: amount) { data, error in
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
    
    @objc public func refundTransaction(jwt: String, amount: String) {
        let httpClient = ClearentHttpClient(baseURL: baseURL, apiKey: apiKey)
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
        guard let response = response else {
            self.readerInfo?.batterylevel = nil
            return
        }

        let curentLevel = response.int
        if (curentLevel > 0) {
            let batteryLevel = batteryLevelPercentageFrom(level: response.int)
            self.readerInfo?.batterylevel = batteryLevel
        } else {
            self.readerInfo?.batterylevel = nil
        }
    }
        
    private func batteryLevelPercentageFrom(level: Int) -> Int {
        let minim = 192.0
        let maxim = 216.0
        let lvl = Double(level)
        var percentage: Double = Double((lvl - minim) / (maxim - minim) * 100.0)
        // it seams that when the reader is charging we get higer values that the limit specified in the documentation
        percentage = (percentage <= 100) ? percentage : 100
        return Int(percentage)
    }
    
    
    // MARK - Private
    
    @objc private func updateConnectionWithDevice(bleDeviceID:String, friendly: String?) {
        readerInfo = ReaderInfo(name: friendly, batterylevel: 0, signalLevel: 0, connected: false)

        if let uuid = UUID(uuidString: bleDeviceID) {
            readerInfo?.udid = uuid
            bleManager = BluetoothScanner.init(udid: uuid, delegate: self)
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
}

extension ClearentWrapper : Clearent_Public_IDTech_VP3300_Delegate {
    
    // needs a way to transmit the amount
    public func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {
        guard let amount = transactionAmount else { return }
        saleTransaction(jwt: clearentTransactionToken.jwt, amount: amount)
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

extension ClearentWrapper: BluetoothScannerProtocol {
    
    func didReceivedSignalStrength(level: SignalLevel) {
        readerInfo?.signalLevel = level.rawValue
    }
    
    func didFinishWithError() {
        self.delegate?.didFinishPairing()
    }
}
