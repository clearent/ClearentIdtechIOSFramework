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
    public var offlineModeState: OfflineModeState = .on
    
    /// Stores the enhanced messages read from the messages bundle
    internal var enhancedMessagesDict: [String:String]?
    
    public weak var delegate: ClearentWrapperProtocol?

    private lazy var clearentVP3300: Clearent_VP3300 = {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        return Clearent_VP3300(connectionHandling: self, clearentVP3300Configuration: config)
    }()
    
    var offlineManager: OfflineModeManager?
    
    private var clearentManualEntry: ClearentManualEntry!

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
            case .off:
                return false
            case .on:
                isOfflineModeConfirmed = true
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
        enableOfflineMode = false
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
        
        self.clearentManualEntry =  ClearentManualEntry(self, clearentBaseUrl: baseURL, publicKey: publicKey)

    }
    
    /**
     * This method will start a transaction, if manualEntryCardInfo is not null then a manual transaction will be performed otherwise a card reader transaction will be initiated
     * @param SaleEntity,  holds informations used for the transcation
     * @param isManualTransaction,  specifies if the transaction is manual
     */
    public func startTransaction(with saleEntity: SaleEntity, isManualTransaction: Bool, completion: @escaping((ClearentResultError?) -> Void)) {
        if let error = checkForMissingKeys() {
            completion(.init(type: error))
        }
        
        if !saleEntity.amount.canBeConverted(to: .utf8) { return }
        if let tip = saleEntity.tipAmount, !tip.canBeConverted(to: .utf8) { return }
        
        self.saleEntity = saleEntity
        if shouldDisplayConnectivityWarning(for: .payment) { return }
        
        if isManualTransaction {
            // If offline mode is on
            let offtr = OfflineTransaction(paymentData: PaymentData(saleEntity: saleEntity))
            saveOfflineTransaction(transaction: offtr)
            
            // else
            manualEntryTransaction(saleEntity: saleEntity) { error in
                completion(error)
            }
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
    public func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentResultError?) -> Void) {
        httpClient.saleTransaction(jwt: jwt, saleEntity: saleEntity) { data, error in
            guard let responseData = data else { return }
        
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    if let linksItem = decodedResponse.links?.first {
                        self.lastTransactionID = linksItem.id
                    }
                    completion(decodedResponse, nil)
                    return
                }
                completion(decodedResponse, ClearentResultError(code: transactionError.code, message: transactionError.message, type: .networkError))
            } catch let jsonDecodingError {
                completion(nil, ClearentResultError(code: "xsdk_response_parsing_error".localized, message: "xsdk_http_response_parsing_error_message".localized, type: .networkError))
                print(jsonDecodingError)
            }
        }
    }

    /**
     * Method that will send a jpeg with client signature to the payment gateway for storage
     * @param image, UIImage to be uploaded
     */

    public func sendSignatureWithImage(image: UIImage, completion: @escaping (SignatureResponse?, ClearentResultError?) -> Void) {
        
        // if offline mode on
        if let transactionID = offlineTransaction?.transactionID {
            saveSignatureImageForTransaction(transactionID: transactionID, image: image)
        }
        
        // else
        if shouldDisplayConnectivityWarning(for: .payment) {
            completion(nil, .init(type: .networkError))
            return
        }

        sendSignatureRequest(image: image, completion: completion)
    }
    
    /**
     * Method that will resend the last client signature image to the payment gateway for storage
     * @param completion, the closure that will be called after resend signature is complete. This is dispatched onto the main queue
     */
    
    public func resendSignature(completion: @escaping (SignatureResponse?, ClearentResultError?) -> Void) {
        guard let signatureImage = signatureImage else { return }

        sendSignatureWithImage(image: signatureImage) { (response, error) in
            completion(response, .init(type: .networkError))
        }
    }
    
    private func sendSignatureRequest(image: UIImage, completion: @escaping (SignatureResponse?, ClearentResultError?) -> Void) {
        print("sendSignatureWithImage")
        if let error = checkForMissingKeys() {
            completion(nil, .init(type: error))
        }
        if let id = lastTransactionID, let tid = Int(id) {
            signatureImage = image
            let base64Image = image.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
            httpClient.sendSignature(base64Image: base64Image, transactionID: tid) { data, error in
                guard let responseData = data else { return }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(SignatureResponse.self, from: responseData)
                    DispatchQueue.main.async {
                        guard let signatureError = decodedResponse.payload.error else {
                            self.signatureImage = nil
                            completion(decodedResponse, nil)
                            return
                        }
                        completion(decodedResponse, .init(code: signatureError.code, message: signatureError.message, type: .networkError))
                    }
                // error call delegate
                } catch let jsonDecodingError {
                    DispatchQueue.main.async {
                        completion(nil, ClearentResultError(code: "xsdk_response_parsing_error".localized, message: "xsdk_http_response_parsing_error_message".localized, type: .networkError))
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
     * @param completion, the closure that will be called after refund is complete. This is dispatched onto the main queue
     */
    public func refundTransaction(jwt: String, amount: String, completion: @escaping (TransactionResponse?, ClearentResultError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(nil, .init(type: error))
        }
        
        httpClient.refundTransaction(jwt: jwt, saleEntity: SaleEntity(amount: amount)) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    completion(decodedResponse, nil)
                    return
                }
                DispatchQueue.main.async {
                    completion(decodedResponse, .init(code: transactionError.code, message: transactionError.message, type: .networkError))
                }
            } catch let jsonDecodingError {
                print(jsonDecodingError)
            }
        }
    }
    
    /**
     * Method that will void a transaction
     * @param transactionID, ID of the transaction to be voided
     * @param completion, the closure that will be called after void is complete. This is dispatched onto the main queue
     */
    public func voidTransaction(transactionID: String, completion: @escaping (TransactionResponse?, ClearentResultError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(nil, .init(type: error))
        }
        
        httpClient.voidTransaction(transactionID: transactionID) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    DispatchQueue.main.async {
                        completion(decodedResponse, nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(decodedResponse, ClearentResultError(code: transactionError.code, message: transactionError.message, type: .networkError))
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
                return isBluetoothPermissionGranted ? (isInternetOn ? (isBluetoothOn ? nil : .noBluetooth) : (isOfflineModeConfirmed ? nil : .noInternet)) : .noBluetoothPermission
            } else {
                return isInternetOn ? nil : (isOfflineModeConfirmed ? nil : .noInternet)
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
    
    private func checkForMissingKeys() -> ClearentErrorType? {
        guard !baseURL.isEmpty else { return ClearentErrorType.baseURLNotProvided }
        guard !apiKey.isEmpty else { return ClearentErrorType.apiKeyNotProvided }
        guard !publicKey.isEmpty else { return ClearentErrorType.publicKeyNotProvided }
        
        return nil
    }
    
    /**
     * Method that performs a manual card transaction
     */
    private func manualEntryTransaction(saleEntity: SaleEntity, completion: @escaping ((ClearentResultError?) -> Void)) {
        let dispatchQueue = DispatchQueue(label: "xplor.UserInteractiveQueue", qos: .userInteractive, attributes: .concurrent)
        dispatchQueue.async { [weak self] in
            guard let strongSelf = self else { return }
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
        let dispatchQueue = DispatchQueue(label: "xplor.UserInteractiveQueue", qos: .userInteractive, attributes: .concurrent)
        dispatchQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            ClearentWrapper.shared.startDeviceInfoUpdate()
            let payment = ClearentPayment.init(sale: ())
            strongSelf.clearentVP3300.startTransaction(payment, clearentConnection: strongSelf.connection)
        }
    }
    
    private func uploadOfflineTransaction(offlineTransaction: OfflineTransaction, token: ClearentTransactionToken?, error: Error?, completion: @escaping ((ClearentResultError?) -> Void)) {
        guard let token = token else {
            completion(.init(type: .missingToken))
            return
        }

        // make sure we have two decimals otherwise the API will return an error
        let saleEntity = offlineTransaction.paymentData.saleEntity
        saleEntity.amount = saleEntity.amount.setTwoDecimals()
        saleEntity.tipAmount = saleEntity.tipAmount?.setTwoDecimals()
        
        saleTransaction(jwt: token.jwt, saleEntity: saleEntity) { [weak self] (response, error) in
            if let error = error {
                completion(error)
            } else {
                guard let image = self?.offlineManager?.retriveSignatureForTransaction(transactionID: offlineTransaction.transactionID) else {
                    completion(.init(type: .missingSignatureImage))
                    return
                }
                self?.sendSignatureRequest(image:image) { (_, error) in
                    completion(error)
                }
            }
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
    
    public func processOfflineTransactions() {
        
        guard let offlineTransactions = offlineManager?.retriveAll() else { return }
        var operations: [AsyncBlockOperation] = []
        
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .utility
        let startTime = CFAbsoluteTimeGetCurrent()
        for tr in offlineTransactions {
            let blockOperation = AsyncBlockOperation { [weak self] operation in
                guard let strongSelf = self else { return }
                operation.state = .executing
                let saleEntity = tr.paymentData.saleEntity
                if tr.transactionType() == .manualTransaction {
                    let card = ClearentCard()
                    card.card = saleEntity.card
                    card.expirationDateMMYY = saleEntity.expirationDateMMYY
                    card.csc = saleEntity.csc
                    strongSelf.clearentManualEntry.createOfflineTransactionToken(card) { [weak self](token, error) in
                        self?.uploadOfflineTransaction(offlineTransaction: tr, token: token, error: error) { error in
                            print("🍎 offlineSale finished manual id: \(tr.transactionID), error: \(String(describing: error?.type.rawValue))")
                            _ = self?.offlineManager?.updateOfflineTransaction(with: error, transaction: tr)
                            operation.state = .finished
                        }
                    }
                } else {
                    strongSelf.clearentVP3300.fetchTransactionToken(tr.paymentData.cardToken) { [weak self] (token, error) in
                        self?.uploadOfflineTransaction(offlineTransaction: tr, token: token, error: error) { error in
                            print("🍎 offlineSale finished card reader id: \(tr.transactionID), error: \(String(describing: error?.type.rawValue))")
                            _ = self?.offlineManager?.updateOfflineTransaction(with: error, transaction: tr)
                            operation.state = .finished
                        }
                    }
                }
            }
            operationQueue.maxConcurrentOperationCount = 3
            operations.append(blockOperation)
        }
        DispatchQueue.global(qos: .utility).async {
            Thread.sleep(forTimeInterval: 15)
            operationQueue.addOperations(operations, waitUntilFinished: true)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("---🍎 Operations finished, Time elapsed: \(timeElapsed) s.---")
        }
    }
    
    public func displayOfflineTransactions() {
        let oldItems = offlineManager?.retriveAll()
        
        print("🍎 ITEMS COUNT: \(oldItems?.count)")
        oldItems?.forEach {
            if let error = $0.errorStatus {
                print("🍎 id: \($0.transactionID), \(error.error.type.rawValue)")
            } else {
                print("🍎 id: \($0.transactionID), nil")
            }
            
        }
        generateOfflineTransactions()
        guard let offlineTransactions = offlineManager?.retriveAll() else { return }
        print("🍎 ITEMS COUNT: \(offlineTransactions.count)")
    }
    
    private func generateOfflineTransactions() {
        offlineManager?.storage.deleteAllData()
        for index in 1...10 {
            let amount = "\(index).00"
            let saleEntity1 = SaleEntity(amount: amount, card: "4111 1111 1111 1111", csc: "999", expirationDateMMYY: "1123")
            let paymentData1 = PaymentData(saleEntity: saleEntity1)
            let offlineManualTr1 = OfflineTransaction(paymentData: paymentData1)
            _ = offlineManager?.saveOfflineTransaction(transaction: offlineManualTr1)
        }
    }

}

extension ClearentWrapper : Clearent_Public_IDTech_VP3300_Delegate {
    
    public func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {
        guard let saleEntity = saleEntity else { return }
        // make sure we have two decimals otherwise the API will return an error
        saleEntity.amount = saleEntity.amount.setTwoDecimals()
        saleEntity.tipAmount = saleEntity.tipAmount?.setTwoDecimals()
        
        saleTransaction(jwt: clearentTransactionToken.jwt, saleEntity: saleEntity) { [weak self] (response, error) in
            DispatchQueue.main.async {
                self?.delegate?.didFinishTransaction(response: response, error: error)
            }
        }
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
                DispatchQueue.main.async {
                    self.delegate?.didFinishTransaction(response: nil, error: ClearentResultError(code: "xsdk_general_error_title".localized, message: "xsdk_token_generation_failed_message".localized, type: .networkError))
                }
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
