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
    
    /// Singleton providing entry to the Clearent SDK Wrapper
    public static var shared = ClearentWrapper()
    
    public weak var delegate: ClearentWrapperProtocol? {
        didSet {
            readerRepository?.delegate = delegate
            transactionRepository?.delegate = delegate
        }
    }
    
    /// The list of readers stored in user defaults that were previously paired
    public var previouslyPairedReaders: [ReaderInfo] {
        ClearentWrapperDefaults.recentlyPairedReaders ?? []
    }
    
    /// Determines the current flow type
    public var flowType: (processType: ProcessType, flowFeedbackType: FlowFeedbackType?)?
    
    /// Specifies what payment flow is preferred. If true, card reader is used. Otherwise, a form where the user has to enter manually the card info is displayed.
    public var cardReaderPaymentIsPreffered: Bool = true
    
    /// If card reader payment fails, the option to use manual payment can be displayed in UI as a fallback method. If user selects this method, useManualPaymentAsFallback needs to be set to true.
    public var useManualPaymentAsFallback: Bool?
    
    /// Make sure this is set before using the SDK, otherwise the app will crash
    public static var configuration: ClearentWrapperConfiguration!
    
    // MARK: - Internal properties
    
    /// Stores the enhanced messages read from the messages bundle
    var enhancedMessagesDict: [String:String]?
    
    var tipEnabled: Bool { ClearentWrapperDefaults.terminalSettings?.tipEnabled ?? false }
    var serviceFeeEnabled: Bool {
        guard let serviceFeeState = ClearentWrapperDefaults.terminalSettings?.serviceFeeState, serviceFeeState ==  ServiceFeeState.ENABLED else { return false }
        if ClearentWrapperDefaults.terminalSettings?.serviceFeeProgram == .CONVENIENCE_FEE {
            return !useCardReaderPaymentMethod
        }
        return true
    }
    var useCardReaderPaymentMethod: Bool {
        cardReaderPaymentIsPreffered && useManualPaymentAsFallback == nil
    }
    
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
    private var VP3300Config: ClearentVP3300Config?
    private var saleEntity = SaleEntity(amount: "")
    private let monitor = NWPathMonitor()
    private var readerRepository: ReaderRepositoryProtocol?
    private var transactionRepository: TransactionRepositoryProtocol?
    
    // MARK: - Init
    
    override init() {
        super.init()
        
        createLogFile()
    }
    
    // MARK: - Public
    
    /**
     * This method updates the SDK with the necessary configuration to work properly.
     */
    public func initialize(with config: ClearentWrapperConfiguration) {
        ClearentWrapper.configuration = config
      
        IDT_VP3300.disableAudioDetection()
        IDT_Device.disableAudioDetection()
        VP3300Config = ClearentVP3300Config(noContactlessNoConfiguration: ClearentWrapper.configuration.baseURL, publicKey: ClearentWrapper.configuration.publicKey)
        clearentVP3300 = Clearent_VP3300(connectionHandling: self, clearentVP3300Configuration: VP3300Config)
        
        readerRepository = ReaderRepository(clearentVP3300: clearentVP3300)
        
        if config.enableEnhancedMessaging {
            readEnhancedMessages()
        }
        
        transactionRepository = TransactionRepository(baseURL: config.baseURL, publicKey: config.publicKey, apiKey: config.apiKey, clearentVP3300: clearentVP3300, clearentManualEntryDelegate: self)
        
        if let offlineModeEncryptionKey = ClearentWrapper.configuration.offlineModeEncryptionKey {
            transactionRepository?.offlineManager = OfflineModeManager(storage: KeyChainStorage(serviceName: ClearentConstants.KeychainService.serviceName, account: ClearentConstants.KeychainService.account, encryptionKey: offlineModeEncryptionKey))
        }
        startConnectionListener()
        setupOfflineMode()
    }
    
    /**
     * Updates the authorization for the gateway, should be called each time the token is refreshed
     * Do not use unless you have a vt-token from the web side
     */
    public func updateWebAuth(with auth: ClearentWebAuth) {
        self.transactionRepository?.updateWebAuth(auth: auth)
    }
    
    /**
     * Updates the authorization for the gateway, should be called each time the token is refreshed
     * Do not use unless you have a vt-token from the web side
     */
    public func hasWebAuth() -> Bool {
        transactionRepository?.hasWebAuthentication() ?? false
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
     * Method that starts a transaction
     * @param SaleEntity,  holds informations used for the transcation
     * @param isManualTransaction, if true, a manual transaction will be performed, otherwise a card reader transaction will be initiated
     * @param completion, the closure that will be called when a missing key error is detected
     */
    public func startTransaction(with saleEntity: SaleEntity, isManualTransaction: Bool, completion: @escaping((ClearentError?) -> Void)) {
        transactionRepository?.fetchHppSetting(processTransactionsOnline: processTransactionOnline) { [weak self] error in
            guard let strongSelf = self else { return }

            if let error = strongSelf.checkForMissingKeys() ?? error?.type {
                completion(.init(type: error))
                return
            }
            
            if !saleEntity.amount.canBeConverted(to: .utf8), let tip = saleEntity.tipAmount, !tip.canBeConverted(to: .utf8) { return }
            
            strongSelf.saleEntity = saleEntity
            
            if ClearentWrapperDefaults.enableOfflineMode {
                if isManualTransaction {
                    if strongSelf.processTransactionOnline {
                        strongSelf.transactionRepository?.manualEntryTransaction(saleEntity: saleEntity)
                    } else {
                        strongSelf.transactionRepository?.saveOfflineTransaction(paymentData: PaymentData(saleEntity: saleEntity))
                    }
                } else {
                    if let userAction = strongSelf.getBluetoothConnectivityStatus() {
                        strongSelf.delegate?.userActionNeeded(action: userAction)
                        return
                    }
                    strongSelf.readerRepository?.cardReaderTransaction()
                }
            } else if strongSelf.isInternetOn {
                if isManualTransaction {
                    strongSelf.transactionRepository?.manualEntryTransaction(saleEntity: saleEntity)
                } else {
                    if let userAction = strongSelf.getBluetoothConnectivityStatus() {
                        strongSelf.delegate?.userActionNeeded(action: userAction)
                        return
                    }
                    strongSelf.readerRepository?.cardReaderTransaction()
                }
            } else {
                strongSelf.delegate?.userActionNeeded(action: .noInternet)
                return
            }
        }
    }
    
    /**
     * Method that sends a transaction to the payment gateway for processing.
     * @param jwt, token received from the card reader
     * @param SaleEntity, information about the transaction
     * @param completion, the closure that will be called after a sale response is received. This is dispatched onto the main queue
     */
    public func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        transactionRepository?.saleTransaction(jwt: jwt, saleEntity: saleEntity, isOfflineTransaction: false) { (response, error) in
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
            transactionRepository?.signatureImage = image
            if checkForConnectivityWarning(for: .payment) {
                completion(nil, .init(type: .connectivityError))
                return
            }
            transactionRepository?.sendSignatureRequest(image: image) { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        } else if ClearentWrapperDefaults.enableOfflineMode {
            transactionRepository?.saveSignatureImageForTransaction(image: image)
        }
    }
    
    /**
     * Method that sends a transaction receipt to an email recipient. If offline mode is enabled, the email will be stored locally
     * @param emailAddress, the emai address to which the transaction receipt will be sent
     * @param completion, the closure that will be called after a response from the request is received. This is dispatched onto the main queue
     */
    
    public func sendReceipt(emailAddress: String, completion: @escaping (ReceiptResponse?, ClearentError?) -> Void) {
        if processTransactionOnline {
            if checkForConnectivityWarning(for: .payment) {
                completion(nil, .init(type: .connectivityError))
                return
            }
            transactionRepository?.sendReceiptRequest(emailAddress: emailAddress) { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        } else if ClearentWrapperDefaults.enableOfflineMode {
            transactionRepository?.saveEmailForTransaction(emailAddress: emailAddress)
        }
    }
    
    /**
     * Method that marks a transaction for refund.
     * @param jwt, token generated by te card reader
     * @param saleEntity, holds information used for the transaction
     * @param completion, the closure that will be called after refund response is received. This is dispatched onto the main queue
     */
    public func refundTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(nil, .init(type: error))
        }
        transactionRepository?.refundTransaction(jwt: jwt, saleEntity: saleEntity) { (response, error) in
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
    public func fetchTerminalSetting(completion: @escaping (ClearentError?) -> Void) {
        if let error = checkForMissingKeys() {
            completion(.init(type: error))
            return
        }
        
        if processTransactionOnline, checkForConnectivityWarning(for: .payment) { return }
    
        if isInternetOn {
            transactionRepository?.fetchTerminalSetting() {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /**
     * Method that uploads all the transactions that were made in offline mode
     * @param completion, the closure that is called after all the offline transactions are processed. This is dispatched onto the main queue.
     */
    public func processOfflineTransactions(completion: @escaping ((ClearentError?) -> Void)) {
        transactionRepository?.fetchHppSetting(processTransactionsOnline: true) { [weak self] error in
            if error != nil {
                completion(ClearentError(type: .httpError))
                return
            }
            self?.transactionRepository?.processOfflineTransactions() {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /**
     * Method that checks if there are terminal settings already fetched
     */
    public func areTerminalSettingsCached() -> Bool {
        return ClearentWrapperDefaults.terminalSettings != nil
    }
    
    // MARK: - Internal
    
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
    func serviceFeeProgramType() -> ServiceFeeProgramType? {
        ClearentWrapperDefaults.terminalSettings?.serviceFeeProgram
    }
    
    /**
     * Method that resends the last client signature image to the payment gateway for storage.
     * @param completion, the closure that will be called after a send signature response is received. This is dispatched onto the main queue
     */
    func resendSignature(completion: @escaping (SignatureResponse?, ClearentError?) -> Void) {
        if processTransactionOnline {
            if checkForConnectivityWarning(for: .payment) {
                completion(nil, .init(type: .connectivityError))
                return
            }
            transactionRepository?.resendSignature() { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            }
        } else if ClearentWrapperDefaults.enableOfflineMode {
            transactionRepository?.resaveSignatureImageForTransaction()
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
    
    /**
     * Checks if a apiKey or webAuth were provided
     * Returns true or false
     */
    private func transactionRepoHasAPIAuth() -> Bool {
        return transactionRepository?.hasAuthentication() ?? false
    }
    
    private func setupOfflineMode() {
        if ClearentWrapperDefaults.enableOfflineMode {
            do {
                try enableOfflineMode()
            } catch {
                print("Error: \(error)")
            }
            // Default value on
            ClearentWrapperDefaults.enableOfflinePromptMode = true
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
            if useCardReaderPaymentMethod {
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
        return nil
    }
    
    func currentSDKVersion() -> String? {
        let bundle = ClearentConstants.bundle  // Get a reference to the bundle from your framework (not the bundle of the app itself
        return bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
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
