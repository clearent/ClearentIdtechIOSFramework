//
//  SDKWrapper.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 17.03.2022.
//

import Foundation
import CocoaLumberjack
import Network

public enum UserAction: String, CaseIterable {
    case pleaseWait,
         swipeTapOrInsert,
         swipeInsert,
         pressReaderButton,
         removeCard,
         tryICCAgain,
         goingOnline,
         cardSecured,
         cardHasChip,
         tryMSRAgain,
         useMagstripe,
         transactionStarted,
         transactionFailed,
         tapFailed,
         connectionTimeout,
         noInternet,
         noBluetooth,
         noBluetoothPermission,
         failedToStartSwipe,
         badChip,
         cardUnsupported,
         cardBlocked,
         cardExpired
    
    var description: String {
        switch self {
        case .pleaseWait:
            return CLEARENT_PLEASE_WAIT
        case .swipeTapOrInsert:
            return CLEARENT_USER_ACTION_3_IN_1_MESSAGE
        case .swipeInsert:
            return CLEARENT_USER_ACTION_2_IN_1_MESSAGE
        case .pressReaderButton:
            return CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE
        case .removeCard:
            return CLEARENT_CARD_READ_OK_TO_REMOVE_CARD
        case .tryICCAgain:
            return CLEARENT_TRY_ICC_AGAIN
        case .tryMSRAgain:
            return CLEARENT_TRY_MSR_AGAIN
        case .goingOnline:
            return CLEARENT_TRANSLATING_CARD_TO_TOKEN
        case .cardSecured:
            return CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE
        case .cardHasChip:
            return CLEARENT_CHIP_FOUND_ON_SWIPE
        case .useMagstripe:
            return CLEARENT_USE_MAGSTRIPE
        case .transactionStarted:
            return CLEARENT_RESPONSE_TRANSACTION_STARTED
        case .transactionFailed:
            return CLEARENT_RESPONSE_TRANSACTION_FAILED
        case .tapFailed:
            return CLEARENT_CONTACTLESS_FALLBACK_MESSAGE
        case .failedToStartSwipe:
            return CLEARENT_PULLED_CARD_OUT_EARLY
        case .badChip:
            return CLEARENT_BAD_CHIP
        case .cardUnsupported:
            return CLEARENT_CARD_UNSUPPORTED
        case .cardBlocked:
            return CLEARENT_CARD_BLOCKED
        case .cardExpired:
            return CLEARENT_CARD_EXPIRED
        case .connectionTimeout:
            return CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE
        case .noInternet:
            return ClearentConstants.Localized.Internet.noConnection
        case .noBluetooth:
            return ClearentConstants.Localized.Bluetooth.turnedOff
        case .noBluetoothPermission:
            return ClearentConstants.Localized.Bluetooth.noPermission
        }
    }
    
    static func action(for text: String) -> UserAction? {
        UserAction.allCases.first { $0.description == text }
    }
}

public enum UserInfo: String, CaseIterable {
    case authorizing,
         processing,
         goingOnline,
         amountNotAllowedForTap,
         chipNotRecognized
    
    var description: String {
        switch self {
        case .authorizing:
            return CLEARENT_TRANSACTION_AUTHORIZING
        case .processing:
            return CLEARENT_TRANSACTION_PROCESSING
        case .goingOnline:
            return CLEARENT_TRANSLATING_CARD_TO_TOKEN
        case .amountNotAllowedForTap:
            return CLEARENT_TAP_OVER_MAX_AMOUNT
        case .chipNotRecognized:
            return CLEARENT_CHIP_UNRECOGNIZED
        }
    }
    
    static func info(for text: String) -> UserInfo? {
        UserInfo.allCases.first { $0.description == text }
    }
}

/**
 * This protocol is used to comunicate information and results regarding the interaction with the SDK
 */
public protocol ClearentWrapperProtocol : AnyObject {
    /**
     * Method called right after a pairing process and a bluetooth search is started
     */
    func didStartPairing()
    
    /**
     * Method called right after a successful connection to a card reader was completed
     */
    func didFinishPairing()
    
    /**
     * Method called as a response to 'startDeviceInfoUpdate' method and indicates that new reader information is available
     */
    func didReceiveSignalStrength()
    
    /**
     * Method called after a pairing process is started and card readers were found nearby
     * @param readers, the list of readers available for pairing
     */
    func didFindReaders(readers:[ReaderInfo])
    
    /**
     * Method called when the currently paired device disconnects
     */
    func deviceDidDisconnect()
    
    /**
     * Method called after the 'connectTo' method was called by protocol implementing class, indicating that  a connection to the selected reader is beeing  established
     */
    func startedReaderConnection(with reader:ReaderInfo)
    
    /**
     * Method called in response to method 'searchRecentlyUsedReaders' and indicated that recently readers were found
     * @param readers. list of recently paired readers
     */
    func didFindRecentlyUsedReaders(readers:[ReaderInfo])
    
    /**
     * Method called to indicate that continuous search of nearby readers has started
     */
    func didBeginContinuousSearching()
    
    /**
     * Method called  when a general error is encountered in a payment/transaction process
     */
    func didEncounteredGeneralError()
    
    /**
     * Method called when a transaction is finished
     * @param response, transaction response as received from the API
     * @param error, if not null it will contain the error received from the API
     */
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?)
    
    /**
     * Method called  when the process of uploading the signature image has completed
     * @param response, upload response as received from the API
     * @param error, if not null it will contain the error received from the API
     */
    func didFinishedSignatureUploadWith(response: SignatureResponse, error: ResponseError?)
    
    /**
     * Method called each time the reader needs an action from the user
     * @UserAction, please check the enum for more cases
     * @action, User Action needed to be performed by the user
     */
    func userActionNeeded(action: UserAction)
    
    /**
     * Method called  each time the reader wants to inform the user
     * @UserInfo, please check the enum for more cases
     * @info, UserInfo needed to be performed by the user
     */
    func didReceiveInfo(info: UserInfo)
}

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
    
    /// Specifies what payment flow should be displayed. If true, card reader is used. Otherwise, a form where the user has to enter manually the card info is displayed.
    public var useCardReaderPaymentMethod: Bool = true
    
    weak var delegate: ClearentWrapperProtocol?

    private lazy var clearentVP3300: Clearent_VP3300 = {
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: publicKey)
        return Clearent_VP3300.init(connectionHandling: self, clearentVP3300Configuration: config)
    }()
    
    private lazy var clearentManualEntry: ClearentManualEntry = {
        return ClearentManualEntry(self, clearentBaseUrl: baseURL, publicKey: publicKey)
    }()

    private var connection  = ClearentConnection(bluetoothSearch: ())
    private var baseURL: String = ""
    private var apiKey: String = ""
    private var publicKey: String = ""
    private var saleEntity: SaleEntity?
    private var lastTransactionID: String?
    private var bleManager : BluetoothScanner?
    private let monitor = NWPathMonitor()
    private var isInternetOn = false
    private var signatureImage: UIImage?
    private var connectivityActionNeeded: UserAction? {
        isBluetoothPermissionGranted  ? (isInternetOn ? (isBluetoothOn ? nil : .noBluetooth) : .noInternet) : .noBluetoothPermission
    }
    private lazy var httpClient: ClearentHttpClient = {
        ClearentHttpClient(baseURL: baseURL, apiKey: apiKey)
    }()
    internal var isBluetoothOn = false
    internal var tipEnabled = false
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
    
    /**
     * Method that will start the pairing process by creating a new connection and starting a bluetooth search.
     * @param reconnectIfPossible, if  false  a connection that will search for bluetooth devices will be started, if true a connection with the last paired reader will be tried
     */
    public func startPairing(reconnectIfPossible: Bool) {
        if let action = connectivityActionNeeded {
            DispatchQueue.main.async {
                self.delegate?.userActionNeeded(action: action)
            }
            return
        }
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.clearentVP3300.emv_cancelTransaction()
            self?.clearentVP3300.device_cancelTransaction()
        }        
    }
     
    
    /**
     * This method will update the current SDK keys
     * @param baseURL, the backend endpoint
     * @param publicKey, publicKey used by the IDTech reader framework
     * @param apiKey, API Key used for http calls
     */
    public func updateWithInfo(baseURL:String, publicKey: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
    }
    
    
    /**
     * This method will start a transaction, if manualEntryCardInfo is not null then a manual transaction will be performed otherwise a card reader transcation will be initiated
     * @param SaleEntity,  holds informations used for the transcation
     * @param ManualEntryCardInfo,  all the information needed for a manual card transaction
     */
    public func startTransaction(with saleEntity: SaleEntity, manualEntryCardInfo: ManualEntryCardInfo? = nil) throws {
        if let error = checkForMissingKeys() { throw error }
        
        if !saleEntity.amount.canBeConverted(to: .utf8) { return }
        if let tip = saleEntity.tipAmount, !tip.canBeConverted(to: .utf8) { return }
        
        self.saleEntity = saleEntity
        
        if shouldDisplayBluetoothWarning() { return }
        
        if let manualEntryCardInfo = manualEntryCardInfo {
            manualEntryTransaction(cardNo: manualEntryCardInfo.card, expirationDate: manualEntryCardInfo.expirationDateMMYY, csc: manualEntryCardInfo.csc)
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
     * Method that will send a jpeg with client signature tot the payment gateway for storage
     * @param image, UIImage to be uploaded
     */
    public func sendSignatureWithImage(image: UIImage) throws {
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
     * @param transactionID, ID of transaction to be voided
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
     * @param transactionID, ID of transcation to be voided
     */
    public func fetchTipSetting(completion: @escaping () -> Void) {
        if shouldDisplayBluetoothWarning() { return }

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
     * return A bool indicating if there is a reader connected
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
    
    // MARK - Private
    
    private func shouldDisplayBluetoothWarning() -> Bool {
        if useCardReaderPaymentMethod {
            if let action = connectivityActionNeeded {
                DispatchQueue.main.async {
                    self.delegate?.userActionNeeded(action: action)
                }
                return true
            }
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
     * @param cardNo, card number as String
     * @param expirationDate, card expiration date as String
     * @param csc, card security code as String
     */
    private func manualEntryTransaction(cardNo: String, expirationDate: String, csc: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            let card = ClearentCard()
            card.card = cardNo
            card.expirationDateMMYY = expirationDate
            card.csc = csc
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
            if let action = UserAction.action(for: clearentFeedback.message) {
                DispatchQueue.main.async {
                    self.delegate?.userActionNeeded(action: action)
                }
            }
        case .INFO:
            if let info = UserInfo.info(for: clearentFeedback.message) {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveInfo(info: info)
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
        print("Will be deprecated")
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


extension ClearentWrapper : ClearentManualEntryDelegate {
    public func handleManualEntryError(_ message: String!) {
        DispatchQueue.main.async {
            if let action = UserAction.action(for: message) {
                self.delegate?.userActionNeeded(action: action)
            } else if let info = UserInfo.info(for: message) {
                self.delegate?.didReceiveInfo(info: info)
            } else {
                self.delegate?.didEncounteredGeneralError()
            }
        }
    }
}
