//
//  SDKWrapper.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 17.03.2022.
//

import Foundation

public enum UserAction: String {
    case pleaseWait = "PLEASE WAIT...",
         swipeInsert = "INSERT/SWIPE CARD",
         pressReaderButton = "PRESS BUTTON ON READER",
         removeCard = "CARD READ OK, REMOVE CARD",
         tryICCAgain = "TRY ICC AGAIN",
         goingOnline = "GOING ONLINE",
         cardSecured = "CARD SECURED",
         cardHasChip = "CARD HAS CHIP. TRY INSERT",
         tryMSRAgain = "TRY MSR AGAIN"
}

public enum UserInfo: String {
    case authorizing = "AUTHORIZING...",
         processing = "PROCESSING..."
}

public enum TransactionError {
    case networkError, insuficientFunds, duplicateTransaction, generalError
}

public protocol SDKWrapperProtocol : AnyObject {
    func didEncounteredGeneralError()
    func didFinishPairing()
    func didFinishTransaction()
    func didReceiveTransactionError(error:TransactionError)
    func userActionNeeded(action: UserAction)
    func didReceiveInfo(info: UserInfo)
    func deviceDidDisconnect()
    func didReceiveDeviceFriendlyName(_ name: String?)
}

@objc public final class SDKWrapper : NSObject {
    
    static let shared = SDKWrapper()
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
    }

    // MARK - Public
    
    @objc public func startPairing() {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        //config?.contactAutoConfiguration = true
        
        clearentVP3300 = Clearent_VP3300.init(connectionHandling: self, clearentVP3300Configuration: config)
        clearentVP3300.device_enableBLEDeviceSearch(nil)
        
        connection?.searchBluetooth = true
        clearentVP3300.start(connection)
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
                self.delegate?.didFinishTransaction()
            }
        }
    }
    
    @objc public func isReaderConnected() -> Bool {
        return clearentVP3300.isConnected()
    }
    
    /// Private
    
    @objc private func updateConnectionWithDevice(bleDeviceID:String, friendly: String?) {
        foundDevice = true
        connection?.bluetoothDeviceId = bleDeviceID
        if let name = friendly {
            connection?.fullFriendlyName = name
            friendlyName = name
            self.delegate?.didReceiveDeviceFriendlyName(friendlyName)
        }
        connection?.searchBluetooth = false
        connection?.readerInterfaceMode = ._2_IN_1
        clearentVP3300.start(connection)
    }
    
    private func amountToTransmit() -> String {
        return "20.0"
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
        if (message == "BLUETOOTH CONNECTED") {
            DispatchQueue.main.async {
                self.delegate?.didFinishPairing()
            }
        }
    }
    
    public func deviceConnected() {
        updateConnectionWithDevice(bleDeviceID: clearentVP3300.device_connectedBLEDevice().uuidString,
                                   friendly: clearentVP3300.device_getBLEFriendlyName())
    }
    
    public func deviceDisconnected() {
        DispatchQueue.main.async {
            self.delegate?.deviceDidDisconnect()
        }
    }
}
