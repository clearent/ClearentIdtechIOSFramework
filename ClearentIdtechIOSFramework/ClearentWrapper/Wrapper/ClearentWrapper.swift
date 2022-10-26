//
//  SDKWrapper.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 17.03.2022.
//

import Foundation
import CocoaLumberjack
import Network
import CryptoKit

public final class ClearentWrapper : NSObject {
    
    public static let shared = ClearentWrapper()
    
    /// The list of readers  stored in user defaults, that were previoulsy paired
    public var previouslyPairedReaders: [ReaderInfo] {
        ClearentWrapperDefaults.recentlyPairedReaders ?? []
    }
    
    /// Determines the current flow type
    public var flowType: (processType: ProcessType, flowFeedbackType: FlowFeedbackType?)?
    
    /// Closure called when reader info (signal, battery, reader name, connection status) is received
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    
    /// Specifies what payment flow is preferred. If true, card reader is used. Otherwise, a form where the user has to enter manually the card info is displayed.
    public var cardReaderPaymentIsPreffered: Bool = true
    
    /// If card reader payment fails, the option to use manual payment can be displayed in UI as a fallback method. If user selects this method, useManualPaymentAsFallback needs to be set to true.
    public var useManualPaymentAsFallback: Bool?
    
    /// Enables or disables the use of enhanced messages
    public var enableEnhancedMessaging: Bool = false
    
    /// Enables or disables the use of the store & forward feature
    internal var enableOfflineMode: Bool = false {
        didSet {
            clearentVP3300.setOfflineMode(enableOfflineMode)
        }
    }
    
    /// The state of the store & forward feature
    public var offlineModeState: OfflineModeState = .off
    
    /// Stores the enhanced messages read from the messages bundle
    internal var enhancedMessagesDict: [String:String]?
    
    public weak var delegate: ClearentWrapperProtocol?

    private lazy var clearentVP3300: Clearent_VP3300 = {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        return Clearent_VP3300.init(connectionHandling: self, clearentVP3300Configuration: config)
    }()
    
    var offlineManager: OfflineModeManager?
    
    private lazy var clearentManualEntry: ClearentManualEntry = {
        return ClearentManualEntry(self, clearentBaseUrl: baseURL, publicKey: publicKey)
    }()

    private var offlineTransaction: OfflineTransaction? = nil
    private var connection  = ClearentConnection(bluetoothSearch: ())
    private var baseURL: String = ""
    public var apiKey: String = ""
    private var publicKey: String = ""
    private var saleEntity: SaleEntity?
    private var lastTransactionID: String?
    private var bleManager : BluetoothScanner?
    private let monitor = NWPathMonitor()
    private var isInternetOn = false
    private var signatureImage: UIImage?
    private var shouldAskForOfflineModePermission: Bool {
        if !enableOfflineMode {
            return false
        } else {
            switch offlineModeState {
            case .off, .on:
                return false
            case .prompted:
                return !isInternetOn ? (isNewPaymentProcess ? true : false) : false
            }
        }
    }
    private lazy var httpClient: ClearentHttpClient = {
        ClearentHttpClient(baseURL: baseURL, apiKey: apiKey)
    }()
    internal var isBluetoothOn = false
    internal var tipEnabled = false
    internal var isOfflineModeConfirmed = false
    internal var offlineModeWarningDisplayed = false
    internal var shouldSendPressButton = false
    internal var isNewPaymentProcess = true
    private var continuousSearchingTimer: Timer?
    private var connectToReaderTimer: Timer?
    private var shouldStopUpdatingReadersListDuringContinuousSearching: Bool? = false
    internal var shouldBeginContinuousSearchingForReaders: ((_ searchingEnabled: Bool) -> Void)?
    
    // MARK: Init
    
    private override init() {
        super.init()

        createLogFile()
        startConnectionListener()
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
    
    /**
     * Method that should be called to enableOfflineMode
     * @param key, encryption key usedf for encypting offline transactions
     */
    public func enableOfflineMode(key: SymmetricKey) {
        enableOfflineMode = true
        offlineManager = OfflineModeManager(storage: KeyChainStorage(serviceName: ClearentConstants.KeychainService.serviceName, account: ClearentConstants.KeychainService.account, encryptionKey: key))
    }
    
    /**
     * Method that should be called to disableOfflineMode
     */
    public func disableOfflineMode() {
        enableOfflineMode = false
        offlineManager = nil
    }
    
    /**
     * Method that will start the pairing process by creating a new connection and starting a bluetooth search.
     * @param reconnectIfPossible, if  false  a connection that will search for bluetooth devices will be started, if true a connection with the last paired reader will be tried
     */
    public func startPairing(reconnectIfPossible: Bool) {
        if shouldDisplayConnectivityWarning(for: .pairing()) { return }
        
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
        
    
    /**
     * Method that will try to initiate a connection to a specific reader
     * @param reader, the card reader to connect to
     */
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
    
    /**
     * Method that will cancel a transaction
     */
    public func cancelTransaction() {
        useManualPaymentAsFallback = nil
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.clearentVP3300.device_cancelTransaction()
        }        
    }
     
    /**
     * This method will update the current SDK keys
     * @param baseURL, the backend endpoint
     * @param publicKey, publicKey used by the IDTech reader framework
     * @param apiKey, API Key used for http calls
     */
    public func updateWithInfo(baseURL:String, publicKey: String, apiKey: String, enableEnhancedMessaging: Bool) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
        self.enableEnhancedMessaging = enableEnhancedMessaging
        
        if enableEnhancedMessaging {
            readEnhancedMessages()
        }
    }
    
    /**
     * This method will start a transaction, if manualEntryCardInfo is not null then a manual transaction will be performed otherwise a card reader transaction will be initiated
     * @param SaleEntity,  holds informations used for the transcation
     * @param isManualTransaction,  specifies if the transaction is manual
     */
    public func startTransaction(with saleEntity: SaleEntity, isManualTransaction: Bool) throws {
        if let error = checkForMissingKeys() { throw error }
        
        if !saleEntity.amount.canBeConverted(to: .utf8) { return }
        if let tip = saleEntity.tipAmount, !tip.canBeConverted(to: .utf8) { return }
        
        self.saleEntity = saleEntity
        if shouldDisplayConnectivityWarning(for: .payment) { return }
        
        if isManualTransaction {
            // If offline mode is on
            let offtr = OfflineTransaction(paymentData: PaymentData(saleEntity: saleEntity))
            saveOfflineTransaction(transaction: offtr)
            
            // else
            manualEntryTransaction()
        } else {
            cardReaderTransaction()
        }
    }
    
    /**
     * Method that will search for currently used readers and call the delegate methods with the results
     */
    public func searchRecentlyUsedReaders() {
        if let recentlyUsedReaders = ClearentWrapperDefaults.recentlyPairedReaders, recentlyUsedReaders.count > 0 {
            delegate?.didFindRecentlyUsedReaders(readers: recentlyUsedReaders)
        } else {
            delegate?.didFindRecentlyUsedReaders(readers: [])
        }
    }
    
    /**
     * Method that will send a transaction to the payment gateway for processing
     * @param jwt, Token received from the card reader
     * @param SaleEntity, information about the transaction
     */
    public func saleTransaction(jwt: String, saleEntity: SaleEntity) {
        httpClient.saleTransaction(jwt: jwt, saleEntity: saleEntity) { data, error in
            guard let responseData = data else { return }
        
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    DispatchQueue.main.async {
                        if let linksItem = decodedResponse.links?.first {
                            self.lastTransactionID = linksItem.id
                        }
                        
                        self.delegate?.didFinishTransaction(response: decodedResponse, error: nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.delegate?.didFinishTransaction(response: decodedResponse, error: transactionError)
                }
            } catch let jsonDecodingError {
                self.delegate?.didFinishTransaction(response: nil, error: ResponseError.init(code: "xsdk_response_parsing_error".localized,
                                                                                             message: "xsdk_http_response_parsing_error_message".localized))
                print(jsonDecodingError)
            }
        }
    }
    
    public func resendSignature(completion: (CompletionResult) -> Void) {
        guard let signatureImage = signatureImage else { return }
        
        do {
            try sendSignatureWithImage(image: signatureImage)
        } catch {
            if let error = error as? ClearentResult {
                completion(.failure(error))
            }
        }
    }

    /**
     * Method that will send a jpeg with client signature to the payment gateway for storage
     * @param image, UIImage to be uploaded
     */
    public func sendSignatureWithImage(image: UIImage) throws {
        
        // if offline mode on
        if let transactionID = offlineTransaction?.transactionID {
            saveSignatureImageForTransaction(transactionID: transactionID, image: image)
        }
        
        // else
        if shouldDisplayConnectivityWarning(for: .payment) { return }

        if let error = checkForMissingKeys() { throw error }
        
        if let id = lastTransactionID {
            if let tid = Int(id) {
                 signatureImage = image
                 let base64Image =  image.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
                 httpClient.sendSignature(base64Image: base64Image, transactionID: tid) { data, error in
                     guard let responseData = data else { return }
                     
                     do {
                         let decodedResponse = try JSONDecoder().decode(SignatureResponse.self, from: responseData)
                         DispatchQueue.main.async {
                             guard let signatureError = decodedResponse.payload.error else {
                                 self.signatureImage = nil
                                 self.delegate?.didFinishedSignatureUploadWith(response: decodedResponse, error: nil)
                                 return
                             }
                             self.delegate?.didFinishedSignatureUploadWith(response: decodedResponse, error: signatureError)
                         }
                         // error call delegate
                     } catch let jsonDecodingError {
                         self.delegate?.didFinishedSignatureUploadWith(response:nil ,
                                                                       error: ResponseError.init(code: "xsdk_response_parsing_error".localized,
                                                                                                 message: "xsdk_http_response_parsing_error_message".localized))
                         print(jsonDecodingError)
                     }
                 }
            }
        }
    }
    
    /**
     * Method that will mark a transaction for refund
     * @param jwt, Token generated by te card reader
     * @param amount, Amount to be refunded
     */
    public func refundTransaction(jwt: String, amount: String) throws {
        if let error = checkForMissingKeys() { throw error }
        
        httpClient.refundTransaction(jwt: jwt, saleEntity: SaleEntity(amount: amount)) { data, error in
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
    
    /**
     * Method that will void a transaction
     * @param transactionID, ID of the transaction to be voided
     */
    public func voidTransaction(transactionID: String) throws {
        if let error = checkForMissingKeys() { throw error }
        
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
    
    /**
     * Method that will fetch the tip settings for current mechant
     * @param completion, the closure that will be called after receiving the data
     */
    public func fetchTipSetting(completion: @escaping () -> Void) {
        if shouldDisplayOfflineModePermission() { return }
        if shouldDisplayConnectivityWarning(for: .payment) { return }

        httpClient.merchantSettings() { data, error in
            DispatchQueue.main.async {
                do {
                    guard let data = data else {
                        completion()
                        return
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(MerchantSettingsEntity.self, from: data)
                    self.tipEnabled = decodedResponse.payload.terminalSettings.enableTip
                } catch let jsonDecodingError {
                    print(jsonDecodingError)
                }
                completion()
            }
        }
    }
    
    /**
     * Method that checks if a reader is already paired and connected
     * returns a bool indicating if there is a reader connected
     */
    public func isReaderConnected() -> Bool {
        return (ClearentWrapperDefaults.pairedReaderInfo != nil && ClearentWrapperDefaults.pairedReaderInfo?.isConnected == true)
    }
    
    /**
     * Method that triggers a fetch of data about the reader
     */
    public func startDeviceInfoUpdate() {
        bleManager?.readRSSI()
        getBatterylevel()
        getReaderVersion()
        getSerialNumber()
    }
    
    public func stopContinousSearching() {
        connection?.searchBluetooth = false
        shouldBeginContinuousSearchingForReaders?(false)
        invalidateConnectionTimer()
    }
    
    public func isReaderEncrypted() -> Bool? {
        var response: NSData? = NSData()
        _ = clearentVP3300.device_sendIDGCommand(0xC7, subCommand: 0x37, data: nil, response: &response)
        
        guard let response = response else { return nil }
        
        return response.int == 3
    }
    
    // MARK - Private
    
    private func shouldDisplayOfflineModePermission() -> Bool {
        if let action = UserAction(rawValue: UserAction.offlineMode.rawValue), shouldAskForOfflineModePermission {
            DispatchQueue.main.async {
                self.delegate?.userActionNeeded(action: action)
            }
            return true
        }
        return false
    }
    
    private func getConnectivityStatus(for processType: ProcessType) -> UserAction? {
        if processType == .payment {
            if cardReaderPaymentIsPreffered && useManualPaymentAsFallback == nil {
                return isBluetoothPermissionGranted ? (isInternetOn ? (isBluetoothOn ? nil : .noBluetooth) : ((isOfflineModeConfirmed || offlineModeState == .on) ? nil : .noInternet)) : .noBluetoothPermission
            } else {
                return isInternetOn ? nil : ((isOfflineModeConfirmed || offlineModeState == .on) ? nil : .noInternet)
            }
        } else {
            return isBluetoothPermissionGranted ? (isBluetoothOn ? nil : .noBluetooth) : .noBluetoothPermission
        }
    }
    
    private func shouldDisplayConnectivityWarning(for processType: ProcessType) -> Bool {
        if let action = getConnectivityStatus(for: processType) {
            DispatchQueue.main.async {
                self.delegate?.userActionNeeded(action: action)
            }
            return true
        }
        return false
    }
    
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
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
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
    
    private func startConnectionTimeoutTimer() {
        self.shouldSendPressButton = true
        connectToReaderTimer = Timer.scheduledTimer(withTimeInterval: 17, repeats: false) { [weak self] _ in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if strongSelf.shouldSendPressButton && strongSelf.isBluetoothOn && strongSelf.isInternetOn {
                    self?.delegate?.userActionNeeded(action: .connectionTimeout)
                }
            }
        }
    }
    
    private func checkForMissingKeys() -> ClearentResult? {
        guard !baseURL.isEmpty else { return ClearentResult.baseURLNotProvided }
        guard !apiKey.isEmpty else { return ClearentResult.apiKeyNotProvided }
        guard !publicKey.isEmpty else { return ClearentResult.publicKeyNotProvided }
        
        return nil
    }
    
    /**
     * Method that performs a manual card transaction
     */
    private func manualEntryTransaction() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self, let saleEntity = strongSelf.saleEntity else { return }
            let card = ClearentCard()
            card.card = saleEntity.card
            card.expirationDateMMYY = saleEntity.expirationDateMMYY
            card.csc = saleEntity.csc
            strongSelf.clearentManualEntry.createTransactionToken(card)
        }
    }
    
    /**
     * Method that will start a card reader transaction
     */
    private func cardReaderTransaction() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self, let saleEntity = strongSelf.saleEntity else { return }
            ClearentWrapper.shared.startDeviceInfoUpdate()
            let payment = ClearentPayment.init(sale: ())
            payment?.amount = Double(saleEntity.amount) ?? 0
            strongSelf.clearentVP3300.startTransaction(payment, clearentConnection: strongSelf.connection)
        }
    }
    
    /**
     * Saves and validates offline transactions, calls a delegate method with the result
     *  @param transaction, represents an offline transaction
     */
    private func saveOfflineTransaction(transaction: OfflineTransaction) {
        offlineTransaction = transaction
        guard let status = offlineManager?.saveOfflineTransaction(transaction: transaction) else { return  }
        self.delegate?.didAcceptOfflineTransaction(err: status)
    }
    
    /**
     * Saves  the image represnting the user's signature
     *  @param transactionID, the id of the transcation for wich we save the signature
     *  @param the actual  image contianing the signature
     */
    private func saveSignatureImageForTransaction(transactionID:String, image: UIImage) {
        guard let status = offlineManager?.saveSignatureForTransaction(transactionID: transactionID, image: image) else { return }
        self.delegate?.didAcceptOfflineSignature(err: status, transactionID: transactionID)
    }
}

extension ClearentWrapper : Clearent_Public_IDTech_VP3300_Delegate {
    
    public func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {
        guard let saleEntity = saleEntity else { return }
        // make sure we have two decimals otherwise the API will return an error
        let amountArray = saleEntity.amount.split(separator: ".")
        if (amountArray.last?.count == 1) {
            saleEntity.amount = saleEntity.amount + "0"
        }
        
        if let tipAmount = saleEntity.tipAmount {
            let tipAmountArray = tipAmount.split(separator: ".")
            if tipAmountArray.last?.count == 1 {
                saleEntity.tipAmount = tipAmount + "0"
            }
        }

        saleTransaction(jwt: clearentTransactionToken.jwt, saleEntity: saleEntity)
    }
    
    public func successOfflineTransactionToken(_ clearentTransactionTokenRequestData: Data?) {
        guard let saleEntity = saleEntity, let cardToken = clearentTransactionTokenRequestData else { return }
        
        let paymentData = PaymentData(saleEntity: saleEntity, cardToken: cardToken)
        let offtr = OfflineTransaction(paymentData: paymentData)
        saveOfflineTransaction(transaction: offtr)
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
        case .USER_ACTION, .INFO:
            if let action = UserAction.action(for: clearentFeedback.message) {
                DispatchQueue.main.async {
                    self.delegate?.userActionNeeded(action: action)
                }
            }
        case .BLUETOOTH:
            if (ClearentWrapperDefaults.pairedReaderInfo != nil) {
                if (clearentFeedback.message == UserAction.noBluetooth.rawValue) {
                    ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
                }
            }
            
            if (clearentFeedback.message == "BLUETOOTH CONNECTED"){
                DispatchQueue.main.async {
                    self.invalidateConnectionTimer()
                }
            }
        case .ERROR:
            if (ClearentWrapperDefaults.pairedReaderInfo != nil && clearentFeedback.message == UserAction.noBluetooth.rawValue) {
                
                if let action = UserAction.action(for: clearentFeedback.message) {
                    DispatchQueue.main.async {
                        self.delegate?.userActionNeeded(action: action)
                    }
                }
            } else  if let action = UserAction.action(for: clearentFeedback.message) {
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
            self.delegate?.didFindReaders(readers: [])
        }
        
        shouldStopUpdatingReadersListDuringContinuousSearching = true
        shouldBeginContinuousSearchingForReaders?(true)
    }

    public func deviceMessage(_ message: String!) {
        /// It appears this is the only feedback we get if the public key is not valid
        ///  This method is deprecated
        
        DispatchQueue.main.async {
            if (message == "xsdk_token_generation_failed_message".localized) {
                self.delegate?.didFinishTransaction(response: nil, error: ResponseError.init(code: "xsdk_general_error_title".localized, message: "xsdk_token_generation_failed_message".localized))
            }
        }
    }
    
    private func invalidateConnectionTimer() {
        DispatchQueue.main.async {
            self.connectToReaderTimer?.invalidate()
            self.connectToReaderTimer = nil
            self.shouldSendPressButton = false
        }
    }
    
    public func deviceConnected() {
        invalidateConnectionTimer()
        bleManager?.udid = ClearentWrapperDefaults.pairedReaderInfo?.uuid
        bleManager?.setupDevice()
        startDeviceInfoUpdate()
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
