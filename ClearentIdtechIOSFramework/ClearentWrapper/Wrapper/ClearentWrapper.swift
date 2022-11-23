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
    
    // MARK: - Public properties
    
    public static let shared = ClearentWrapper()
    
    public weak var delegate: ClearentWrapperProtocol? {
        didSet {
            readerRepository?.delegate = delegate
            transactionRepository?.delegate = delegate
        }
    }
    
    /// The list of readers stored in user defaults that were previously paired.
    public var previouslyPairedReaders: [ReaderInfo] {
        ClearentWrapperDefaults.recentlyPairedReaders ?? []
    }
    
    /// Determines the current flow type
    public var flowType: (processType: ProcessType, flowFeedbackType: FlowFeedbackType?)?
    
    /// Specifies what payment flow is preferred. If true, card reader is used. Otherwise, a form where the user has to enter manually the card info is displayed.
    public var cardReaderPaymentIsPreffered: Bool = true
    
    /// If card reader payment fails, the option to use manual payment can be displayed in UI as a fallback method. If user selects this method, useManualPaymentAsFallback needs to be set to true.
    public var useManualPaymentAsFallback: Bool?
    
    public static var configuration: ClearentWrapperConfiguration!
    
    // MARK: - Internal properties
    
    /// Stores the enhanced messages read from the messages bundle
    var enhancedMessagesDict: [String:String]?
    
    var tipEnabled: Bool { ClearentWrapperDefaults.terminalSettings?.tipEnabled ?? false }
    var isNewPaymentProcess = true
    var isInternetOn: Bool = false {
        didSet {
            readerRepository?.isInternetOn = isInternetOn
        }
    }
    
    /// Force the transaction to be processed online in case the internet connection is enabled and the state of the offline mode is set to prompted.
    var processTransactionOnline = true {
        didSet {
            clearentVP3300.setOfflineMode(!processTransactionOnline)
        }
    }
    
    // MARK: - Private properties
    
    private var clearentVP3300: Clearent_VP3300!
    private var saleEntity = SaleEntity(amount: "")
    private let monitor = NWPathMonitor()
    private var readerRepository: ReaderRepositoryProtocol?
    private var transactionRepository: TransactionRepositoryProtocol?
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        createLogFile()
    }
    
    // MARK: - Public
    
    /**
     * This method updates the SDK with the necessary configuration to work properly.
     */
    public func initialize(with config: ClearentWrapperConfiguration) {
        ClearentWrapper.configuration = config
        
        let VP3300Config = ClearentVP3300Config(noContactlessNoConfiguration: ClearentWrapper.configuration.baseURL, publicKey: ClearentWrapper.configuration.publicKey)
        clearentVP3300 = Clearent_VP3300(connectionHandling: self, clearentVP3300Configuration: VP3300Config)
        readerRepository = ReaderRepository(clearentVP3300: clearentVP3300)
        
        let manualEntry = ClearentManualEntry(self, clearentBaseUrl: config.baseURL, publicKey: config.publicKey)
        transactionRepository = TransactionRepository(baseURL: config.baseURL, apiKey: config.apiKey, clearentVP3300: clearentVP3300, clearentManualEntry: manualEntry)
        
        if config.enableEnhancedMessaging {
            readEnhancedMessages()
        }
        
        if let offlineModeEncryptionKey = ClearentWrapper.configuration.offlineModeEncryptionKey {
            transactionRepository?.offlineManager = OfflineModeManager(storage: KeyChainStorage(serviceName: ClearentConstants.KeychainService.serviceName, account: ClearentConstants.KeychainService.account, encryptionKey: offlineModeEncryptionKey))
        }
        startConnectionListener()
        setupOfflineMode()
    }
    
    /**
     * Method that should be called to enable offline mode.
     */
    public func enableOfflineMode() throws {
        guard transactionRepository?.offlineManager != nil else { throw ClearentErrorType.offlineModeEncryptionKeyNotProvided }
        clearentVP3300.setOfflineMode(true)
        ClearentWrapperDefaults.enableOfflineMode = true
    }
    
    /**
     * Method that should be called to disable offline mode.
     */
    public func disableOfflineMode() {
        clearentVP3300.setOfflineMode(false)
        ClearentWrapperDefaults.enableOfflineMode = false
    }
    
    /**
     * Method retrieves all saved offline transactions if the encryption key provided is valid and can decrypt them.
     */
    public func retrieveAllOfflineTransactions() -> [OfflineTransaction]? {
        transactionRepository?.fetchOfflineTransactions()
    }
    
    /**
     * Method that starts the pairing process by creating a new connection and starting a bluetooth search.
     * @param reconnectIfPossible, if  false  a connection that will search for bluetooth devices will be started, if true a connection with the last paired reader will be tried
     */
    public func startPairing(reconnectIfPossible: Bool) {
        if checkForConnectivityWarning(for: .pairing()) { return }
        
        readerRepository?.startPairing(reconnectIfPossible: reconnectIfPossible)
    }
    
    /**
     * Method that tries to initiate a connection to a specific reader.
     * @param reader, the card reader to connect to
     */
    public func connectTo(reader: ReaderInfo) {
        readerRepository?.connectTo(reader: reader)
    }
    
    /**
     * Method that cancels a transaction.
     */
    public func cancelTransaction() {
        useManualPaymentAsFallback = nil
        readerRepository?.cancelTransaction()
    }
    
    /**
     * Method that searches for currently used readers and calls the delegate methods with the results.
     */
    public func searchRecentlyUsedReaders() {
        readerRepository?.searchRecentlyUsedReaders()
    }
    
    /**
     * Method that checks if a reader is already paired and connected.
     * returns a bool indicating if there is a reader connected
     */
    public func isReaderConnected() -> Bool {
        guard let readerRepository = readerRepository else { return false }
        return readerRepository.isReaderConnected()
    }
    
    public func disconnectFromReader() {
        readerRepository?.disconnectFromReader()
    }
    
    public func stopContinousSearching() {
        readerRepository?.stopContinousSearching()
    }
    
    public func isReaderEncrypted() -> Bool? {
        readerRepository?.isReaderEncrypted()
    }
    
    /**
     * Method that starts a transaction. If manualEntryCardInfo is not null then a manual transaction will be performed otherwise a card reader transaction will be initiated.
     * @param SaleEntity,  holds informations used for the transcation
     * @param isManualTransaction,  specifies if the transaction is manual
     * @param completion, the closure that will be called when a missing key error is detected
     */
    public func startTransaction(with saleEntity: SaleEntity, isManualTransaction: Bool, completion: @escaping((ClearentError?) -> Void)) {
        if let error = checkForMissingKeys() {
            completion(.init(type: error))
        }
        
        if !saleEntity.amount.canBeConverted(to: .utf8) { return }
        if let tip = saleEntity.tipAmount, !tip.canBeConverted(to: .utf8) { return }
        
        self.saleEntity = saleEntity
        
        if ClearentWrapperDefaults.enableOfflineMode {
            if isManualTransaction {
                if processTransactionOnline {
                    transactionRepository?.manualEntryTransaction(saleEntity: saleEntity)
                } else {
                    transactionRepository?.saveOfflineTransaction(paymentData: PaymentData(saleEntity: saleEntity))
                }
            } else {
                if let userAction = getBluetoothConnectivityStatus() {
                    self.delegate?.userActionNeeded(action: userAction)
                    return
                }
                readerRepository?.cardReaderTransaction()
            }
        } else if isInternetOn {
            if isManualTransaction {
                transactionRepository?.manualEntryTransaction(saleEntity: saleEntity)
            } else {
                if let userAction = getBluetoothConnectivityStatus() {
                    self.delegate?.userActionNeeded(action: userAction)
                    return
                }
                readerRepository?.cardReaderTransaction()
            }
        } else {
            self.delegate?.userActionNeeded(action: .noInternet)
            return
        }
    }
    
    /**
     * Method that sends a transaction to the payment gateway for processing.
     * @param jwt, token received from the card reader
     * @param SaleEntity, information about the transaction
     * @param completion, the closure that will be called after a sale response is received. This is dispatched onto the main queue
     */
    public func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        transactionRepository?.saleTransaction(jwt: jwt, saleEntity: saleEntity) { (response, error) in
            DispatchQueue.main.async {
                completion(response, error)
            }
        }
    }
    
    /**
     * Method that sends a jpeg with client signature to the payment gateway for storage.
     * @param image, UIImage to be uploaded
     * @param completion, the closure that will be called after a send signature response is received. This is dispatched onto the main queue
     */
    
    public func sendSignatureWithImage(image: UIImage, completion: @escaping (SignatureResponse?, ClearentError?) -> Void) {
        if processTransactionOnline {
            transactionRepository?.sendSignatureRequest(image: image) { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        } else if ClearentWrapperDefaults.enableOfflineMode {
            transactionRepository?.saveSignatureImageForTransaction(image: image)
        } else if checkForConnectivityWarning(for: .payment) {
            completion(nil, .init(type: .connectivityError))
            return
        } else {
            transactionRepository?.sendSignatureRequest(image: image) { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        }
    }
    
    /**
     * Method that marks a transaction for refund.
     * @param jwt, token generated by te card reader
     * @param amount, Amount to be refunded
     * @param completion, the closure that will be called after refund response is received. This is dispatched onto the main queue
     */
    public func refundTransaction(jwt: String, amount: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(nil, .init(type: error))
        }
        transactionRepository?.refundTransaction(jwt: jwt, amount: amount) { (response, error) in
            DispatchQueue.main.async {
                completion(response, error)
            }
        }
    }
    
    /**
     * Method that voids a transaction.
     * @param transactionID, ID of the transaction to be voided
     * @param completion, the closure that will be called after void response is received. This is dispatched onto the main queue
     */
    public func voidTransaction(transactionID: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(nil, .init(type: error))
        }
        transactionRepository?.voidTransaction(transactionID: transactionID) { (response, error) in
            DispatchQueue.main.async {
                completion(response, error)
            }
        }
    }
    
    /**
     * Method that fetches the tip settings for the current mechant.
     * @param completion, the closure that will be called after receiving the data. This is dispatched onto the main queue
     */
    public func fetchTipSetting(completion: @escaping (ClearentError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(.init(type: error))
            return
        }
        
        if processTransactionOnline, checkForConnectivityWarning(for: .payment) { return }
    
        if isInternetOn {
            transactionRepository?.fetchTipSetting() {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /**
     * Method that returns the offline manager instance
     */
    
    func retrieveOfflineManager() -> OfflineModeManager? {
        transactionRepository?.offlineManager
    }
    
    /**
     * Method that returns the amount of service fee calculated based on the current terminal settings
     * @param amount, the amount that service  will be applied to
     * If there are no terminal settings fetched or the service fee is disabled it will return nil
     */
    func serviceFeeAmount(amount: Double) -> Double? {
        transactionRepository?.serviceFeeForAmount(amount: amount)
    }
    
    /**
     * Method that returns the service fee program type if available
     */
    func serviceFeeProgramName() -> String? {
        transactionRepository?.serviceFeeProgramType()
    }
    
    /**
     * Method that uploads all the transactions that were made in offline mode
     * @param completion, the closure that is called after all the offline transactions are processed. This is dispatched onto the main queue.
     */
    public func processOfflineTransactions(completion: @escaping (() -> Void)) {
        transactionRepository?.processOfflineTransactions() {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    // MARK: - Internal
    
    /**
     * Method that resends the last client signature image to the payment gateway for storage.
     * @param completion, the closure that will be called after a send signature response is received. This is dispatched onto the main queue
     */
    func resendSignature(completion: @escaping (SignatureResponse?, ClearentError?) -> Void) {
        if processTransactionOnline {
            transactionRepository?.resendSignature() { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        } else if ClearentWrapperDefaults.enableOfflineMode {
            transactionRepository?.resaveSignatureImageForTransaction()
        } else if checkForConnectivityWarning(for: .payment) {
            completion(nil, .init(type: .connectivityError))
            return
        } else {
            transactionRepository?.resendSignature() { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        }
    }
    
    func updateReaderInRecentlyUsed(reader: ReaderInfo) {
        readerRepository?.updateReaderInRecentlyUsed(reader: reader)
    }
    
    func removeReaderFromRecentlyUsed(reader: ReaderInfo) {
        readerRepository?.removeReaderFromRecentlyUsed(reader: reader)
    }
    
    func addReaderToRecentlyUsed(reader: ReaderInfo) {
        readerRepository?.addReaderToRecentlyUsed(reader: reader)
    }
    
    // MARK: - Private
    
    private func setupOfflineMode() {
        if ClearentWrapperDefaults.enableOfflineMode {
            do {
                try enableOfflineMode()
            } catch {
                print("Error: \(error)")
            }
        } else {
            disableOfflineMode()
        }
    }
    
    private func getBluetoothConnectivityStatus() -> UserAction? {
        let isBluetoothPermissionGranted = readerRepository?.isBluetoothPermissionGranted ?? false
        let isBluetoothOn = readerRepository?.isBluetoothOn ?? false
        
        return isBluetoothPermissionGranted ? (isBluetoothOn ? nil : .noBluetooth) : .noBluetoothPermission
    }
    
    private func getConnectivityStatus(for processType: ProcessType) -> UserAction? {
        if processType == .payment {
            if cardReaderPaymentIsPreffered && useManualPaymentAsFallback == nil {
                return isInternetOn ? getBluetoothConnectivityStatus() : .noInternet
            } else {
                return isInternetOn ? nil : .noInternet
            }
        } else {
            return getBluetoothConnectivityStatus()
        }
    }
    
    private func checkForConnectivityWarning(for processType: ProcessType) -> Bool {
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
    
    private func checkForMissingKeys() -> ClearentErrorType? {
        guard !ClearentWrapper.configuration.baseURL.isEmpty else { return ClearentErrorType.baseURLNotProvided }
        guard !ClearentWrapper.configuration.apiKey.isEmpty else { return ClearentErrorType.apiKeyNotProvided }
        guard !ClearentWrapper.configuration.publicKey.isEmpty else { return ClearentErrorType.publicKeyNotProvided }
        
        return nil
    }
}

extension ClearentWrapper: Clearent_Public_IDTech_VP3300_Delegate {
    
    public func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {
        // make sure we have two decimals otherwise the API will return an error
        saleEntity.amount = saleEntity.amount.setTwoDecimals()
        saleEntity.tipAmount = saleEntity.tipAmount?.setTwoDecimals()
        
        saleTransaction(jwt: clearentTransactionToken.jwt, saleEntity: saleEntity) { [weak self] (response, error) in
            DispatchQueue.main.async {
                self?.delegate?.didFinishTransaction(response: response, error: error)
            }
        }
    }
    
    public func successOfflineTransactionToken(_ clearentTransactionTokenRequestData: Data?, isTransactionEncrypted isEncrypted: Bool) {
        guard let cardToken = clearentTransactionTokenRequestData else { return }
        
        ClearentWrapperDefaults.pairedReaderInfo?.encrypted = isEncrypted
        if (!isEncrypted) {
            self.delegate?.showEncryptionWarning()
            disableOfflineMode()
            return
        }
        
        let paymentData = PaymentData(saleEntity: saleEntity, cardToken: cardToken)
        transactionRepository?.saveOfflineTransaction(paymentData: paymentData)
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
                    self.readerRepository?.invalidateConnectionTimer()
                }
            }
        case .ERROR:
            if (ClearentWrapperDefaults.pairedReaderInfo != nil && clearentFeedback.message == UserAction.noBluetooth.rawValue) {
                
                if let action = UserAction.action(for: clearentFeedback.message) {
                    DispatchQueue.main.async {
                        self.delegate?.userActionNeeded(action: action)
                    }
                }
            } else if let action = UserAction.action(for: clearentFeedback.message) {
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
        readerRepository?.bluetoothDevices(bluetoothDevices)
    }
    
    public func deviceMessage(_ message: String!) {
        /// It appears this is the only feedback we get if the public key is not valid
        /// This method is deprecated
        if (message == "xsdk_token_generation_failed_message".localized) {
            DispatchQueue.main.async {
                self.delegate?.didFinishTransaction(response: nil, error: ClearentError(type: .missingToken, code: "xsdk_general_error_title".localized, message: "xsdk_token_generation_failed_message".localized))
            }
        }
    }
    
    public func deviceConnected() {
        readerRepository?.deviceConnected()
    }
    
    public func deviceDisconnected() {
        readerRepository?.deviceDisconnected()
    }
}
