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
    func deviceDidDisconnect()
    func didFinishPairing()
    func didFoundReaders(readers:[ReaderInfo])
    func didNotFoundReaders()
    
    func didEncounteredGeneralError()
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?)
    func userActionNeeded(action: UserAction)
    func didReceiveInfo(info: UserInfo)
   
}

@objc public final class ClearentWrapper : NSObject {
    
    public static let shared = ClearentWrapper()
    private var baseURL: String = ""
    private var apiKey: String = ""
    private var publicKey: String = ""
    private var clearentVP3300 = Clearent_VP3300()
    private var connection  = ClearentConnection(bluetoothSearch: ())
    weak var delegate: ClearentWrapperProtocol?
    private var transactionAmount: String?
    
    private var bleManager : BluetoothScanner?
    public var readerInfo: ReaderInfo?
    
    @objc public override init() {
        super.init()
        createLogFile()
    }

    // MARK - Public
    
    public func startPairing() {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        clearentVP3300 = Clearent_VP3300.init(connectionHandling: self, clearentVP3300Configuration: config)
        clearentVP3300.start(connection)
        
        self.delegate?.didStartPairing()
    }
    
    public func selectReader(reader: ReaderInfo) {
        if reader.uuid != nil {
            self.updateConnectionWithDevice(readerInfo: reader)
        }
    }
    
    public func cancelTransaction() {
        clearentVP3300.emv_cancelTransaction()
    }
    
    public func updateWithInfo(baseURL:String, publicKey: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
    }
    
    public func startTransactionWithAmount(amount: String) {
        ClearentWrapper.shared.startDeviceInfoUpdate()

        let payment = ClearentPayment.init(sale: ())
        if (amount.canBeConverted(to: String.Encoding.utf8)) {
            payment?.amount = Double(amount) ?? 0
            transactionAmount = amount
        }
        
        let _ : ClearentResponse = clearentVP3300.startTransaction(payment, clearentConnection: connection)
    }
    
    public func saleTransaction(jwt: String, amount: String) {
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
    
    public func refundTransaction(jwt: String, amount: String) {
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
    
    public func isReaderConnected() -> Bool {
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
        // It seams that when the reader is charging we get higer values that the limit specified in the documentation
        percentage = (percentage <= 100) ? percentage : 100
        return Int(percentage)
    }
    
    
    // MARK - Private
    
    private func updateConnectionWithDevice(readerInfo: ReaderInfo) {
        self.readerInfo = readerInfo

        if let uuid = readerInfo.uuid {
            bleManager = BluetoothScanner.init(udid: uuid, delegate: self)
            connection?.bluetoothDeviceId = uuid.uuidString
            connection?.fullFriendlyName = readerInfo.readerName
        }
        
        connection?.searchBluetooth = false
        clearentVP3300.start(connection)
    }
    
    private func readerInfo(from clearentDevice:ClearentBluetoothDevice) -> ReaderInfo {
        let uuidString: UUID? = UUID(uuidString: clearentDevice.deviceId)
        return ReaderInfo(name: clearentDevice.friendlyName, batterylevel:nil , signalLevel: nil, connected: clearentDevice.connected, uuid: uuidString)
    }
}

extension ClearentWrapper : Clearent_Public_IDTech_VP3300_Delegate {
    
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
        if (bluetoothDevices.count == 1) {
            updateConnectionWithDevice(readerInfo: readerInfo(from: bluetoothDevices[0]))
        } else if (bluetoothDevices.count > 1) {
            let readers = bluetoothDevices.map { device in
                return readerInfo(from: device)
            }
            self.delegate?.didFoundReaders(readers: readers)
        } else {
            self.delegate?.didNotFoundReaders()
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
