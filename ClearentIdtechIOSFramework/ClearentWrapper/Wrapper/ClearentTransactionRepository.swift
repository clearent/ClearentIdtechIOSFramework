//
//  ClearentTransactionRepository.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 21.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

protocol TransactionRepositoryProtocol {
    var delegate: ClearentWrapperProtocol? { get set }
    var offlineManager: OfflineModeManager? { get set }
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)
    func sendSignatureRequest(image: UIImage, completion: @escaping (SignatureResponse?, ClearentError?) -> Void)
    func sendReceiptRequest(emailAddress: String, completion: @escaping (ReceiptResponse?, ClearentError?) -> Void)
    func resendSignature(completion: @escaping (SignatureResponse?, ClearentError?) -> Void)
    func refundTransaction(jwt: String, amount: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)
    func voidTransaction(transactionID: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)
    func fetchTerminalSetting(completion: @escaping () -> Void)
    func processOfflineTransactions(completion: @escaping (() -> Void))
    func manualEntryTransaction(saleEntity: SaleEntity)
    func saveOfflineTransaction(paymentData: PaymentData)
    func saveSignatureImageForTransaction(image: UIImage)
    func saveEmailForTransaction(emailAddress: String)
    func resaveSignatureImageForTransaction()
    func fetchOfflineTransactions() -> [OfflineTransaction]?
    func serviceFeeForAmount(amount: Double) -> Double?
}

class TransactionRepository: NSObject, TransactionRepositoryProtocol {
    var delegate: ClearentWrapperProtocol?
    var offlineManager: OfflineModeManager?
    private var lastTransactionID: String?
    private var signatureImage: UIImage?
    private var httpClient: ClearentHttpClientProtocol
    private var clearentManualEntry: ClearentManualEntry?
    private var clearentVP3300: Clearent_VP3300?
    private var offlineTransaction: OfflineTransaction? = nil
    
    // MARK: - Init
    
    init(httpClient: ClearentHttpClientProtocol? = nil, baseURL: String, apiKey: String, clearentVP3300: Clearent_VP3300, clearentManualEntry: ClearentManualEntry?) {
        self.httpClient = httpClient ?? ClearentDefaultHttpClient(baseURL: baseURL, apiKey: apiKey)
        super.init()
        self.clearentManualEntry = clearentManualEntry
        self.clearentVP3300 = clearentVP3300
    }
    
    /**
     * Calculates the amount of the service fee based on the current terminal settings
     * If there are no terminal settings fetched or the service fee is disabled it will return nil
     */
    func serviceFeeForAmount(amount: Double) -> Double? {
        // Terminal settings are cached and if we have cached values we will use it
        let terminalSettings = ClearentWrapperDefaults.terminalSettings
        if let serviceFeeState = terminalSettings?.serviceFeeState, serviceFeeState ==  ServiceFeeState.ENABLED {
            guard let feeType = terminalSettings?.serviceFeeType,
                 let serviceFee = terminalSettings?.serviceFee,
                 let serviceFeeValue = Double(serviceFee) else { return nil }
            return calculateFeeFor(amount: amount, feeType: feeType, feeValue: serviceFeeValue)
        }
        return nil
    }
    
    // MARK: - Internal
    
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        httpClient.saleTransaction(jwt: jwt, saleEntity: saleEntity) { [weak self] data, error in
            guard let strongSelf = self else { return }
            guard let responseData = data else {
                completion(nil, ClearentError(type: .httpError))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    if let linksItem = decodedResponse.links?.first {
                        strongSelf.lastTransactionID = linksItem.id
                    }
                    completion(decodedResponse, nil)
                    return
                }
                
                let errType = (decodedResponse.payload.transaction?.result == TransactionStatus.declined) ? ClearentErrorType.gatewayDeclined : ClearentErrorType.httpError
                completion(decodedResponse, ClearentError(type: errType, code: transactionError.code, message: transactionError.message))
            } catch let jsonDecodingError {
                completion(nil, ClearentError(type: .httpError, code: "xsdk_response_parsing_error".localized, message: "xsdk_http_response_parsing_error_message".localized))
                print(jsonDecodingError)
            }
        }
    }
    
    func refundTransaction(jwt: String, amount: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        httpClient.refundTransaction(jwt: jwt, saleEntity: SaleEntity(amount: amount)) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    completion(decodedResponse, nil)
                    return
                }
                completion(decodedResponse, .init(type: .httpError, code: transactionError.code, message: transactionError.message))
            } catch let jsonDecodingError {
                print(jsonDecodingError)
            }
        }
    }
    
    func voidTransaction(transactionID: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        httpClient.voidTransaction(transactionID: transactionID) { data, error in
            guard let responseData = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    completion(decodedResponse, nil)
                    return
                }
                completion(decodedResponse, ClearentError(type: .httpError, code: transactionError.code, message: transactionError.message))
            } catch let jsonDecodingError {
                print(jsonDecodingError)
            }
        }
    }
    
    func resendSignature(completion: @escaping (SignatureResponse?, ClearentError?) -> Void) {
        guard let signatureImage = signatureImage else { return }

        sendSignatureRequest(image: signatureImage, completion: completion)
    }
    
    func sendSignatureRequest(image: UIImage, completion: @escaping (SignatureResponse?, ClearentError?) -> Void) {
        if let id = lastTransactionID, let tid = Int(id) {
            signatureImage = image
            guard let dataImage = image.resize()?.jpegData(compressionQuality: 0) else {
                completion(nil, .init(type: .missingSignatureImage))
                return
            }
            let base64Image = dataImage.base64EncodedString()
            httpClient.sendSignature(base64Image: base64Image, transactionID: tid) { [weak self] data, error in
                guard let strongSelf = self else { return }
                guard let responseData = data else { return }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(SignatureResponse.self, from: responseData)
                    guard let signatureError = decodedResponse.payload.error else {
                        strongSelf.signatureImage = nil
                        completion(decodedResponse, nil)
                        return
                    }
                    completion(decodedResponse, .init(type: .httpError, code: signatureError.code, message: signatureError.message))
                // error call delegate
                } catch let jsonDecodingError {
                    completion(nil, ClearentError(type: .httpError, code: "xsdk_response_parsing_error".localized, message: "xsdk_http_response_parsing_error_message".localized))
                    print(jsonDecodingError)
                }
            }
        }
    }
    
    func sendReceiptRequest(emailAddress: String, completion: @escaping (ReceiptResponse?, ClearentError?) -> Void) {
        if let id = lastTransactionID, let tid = Int(id) {
            httpClient.sendReceipt(emailAddress: emailAddress, transactionID: tid) { data, error in
                guard let responseData = data else { return }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(ReceiptResponse.self, from: responseData)
                    guard let receiptError = decodedResponse.payload.error else {
                        completion(decodedResponse, nil)
                        return
                    }
                    completion(decodedResponse, .init(type: .httpError, code: receiptError.code, message: receiptError.message))
                // error call delegate
                } catch let jsonDecodingError {
                    completion(nil, ClearentError(type: .httpError, code: "xsdk_response_parsing_error".localized, message: "xsdk_http_response_parsing_error_message".localized))
                    print(jsonDecodingError)
                }
            }
        }
    }
    
    func fetchTerminalSetting(completion: @escaping () -> Void) {
        httpClient.terminalSettings() { data, error in
            DispatchQueue.main.async {
                do {
                    guard let data = data else {
                        completion()
                        return
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(TerminalSettingsEntity.self, from: data)
                    ClearentWrapperDefaults.terminalSettings = decodedResponse.payload.terminalSettings
                } catch let jsonDecodingError {
                    print(jsonDecodingError)
                }
                completion()
            }
        }
    }
        
    func processOfflineTransactions(completion: @escaping (() -> Void)) {
        guard let offlineTransactions = offlineManager?.retrieveAll() else { return }
        var operations: [AsyncBlockOperation] = []
        
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .utility
        for transaction in offlineTransactions {
            let blockOperation = AsyncBlockOperation { [weak self] operation in
                guard let strongSelf = self else { return }
                operation.state = .executing
                let saleEntity = transaction.paymentData.saleEntity
                
                if transaction.transactionType() == .manualTransaction {
                    let card = ClearentCard()
                    card.card = saleEntity.card
                    card.expirationDateMMYY = saleEntity.expirationDateMMYY
                    card.csc = saleEntity.csc
                    
                    strongSelf.clearentManualEntry?.createOfflineTransactionToken(card) { [weak self] token in
                        self?.sendOfflineTransaction(offlineTransaction: transaction, token: token) { error, response  in
                            _ = self?.offlineManager?.updateOfflineTransaction(with: error, transaction: transaction, transactionResponse: response)
                            operation.state = .finished
                        }
                    }
                } else {
                    strongSelf.clearentVP3300?.fetchTransactionToken(transaction.paymentData.cardToken) { [weak self] token in
                        self?.sendOfflineTransaction(offlineTransaction: transaction, token: token) { error, response  in
                            _ = self?.offlineManager?.updateOfflineTransaction(with: error, transaction: transaction, transactionResponse: response)
                            operation.state = .finished
                        }
                    }
                }
            }
            operationQueue.maxConcurrentOperationCount = 3
            operations.append(blockOperation)
        }
        
        DispatchQueue.global(qos: .utility).async {
            operationQueue.addOperations(operations, waitUntilFinished: true)
            completion()
        }
    }
    
    /**
     * Method that performs a manual card transaction.
     */
     func manualEntryTransaction(saleEntity: SaleEntity) {
        let dispatchQueue = DispatchQueue(label: "xplor.UserInteractiveQueue", qos: .userInteractive, attributes: .concurrent)
         
        dispatchQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            let card = ClearentCard()
            card.card = saleEntity.card
            card.expirationDateMMYY = saleEntity.expirationDateMMYY
            card.csc = saleEntity.csc
            strongSelf.clearentManualEntry?.createTransactionToken(card)
        }
    }
    
    /**
     * Saves and validates offline transactions, calls a delegate method with the result.
     *  @param transaction, represents an offline transaction
     */
    func saveOfflineTransaction(paymentData: PaymentData) {
        let offlineTransaction = OfflineTransaction(paymentData: paymentData, sdkVersion: ClearentWrapper.shared.currentSDKVersion())
        self.offlineTransaction = offlineTransaction
        guard let status = offlineManager?.saveOfflineTransaction(transaction: offlineTransaction) else { return  }
        delegate?.didAcceptOfflineTransaction(status: status)
    }
    
    /**
     * Retrieve all stored offline transactions
     */
    func fetchOfflineTransactions() -> [OfflineTransaction]? {
        offlineManager?.retrieveAll()
    }
    
    /**
     * Saves  the image representing the user's signature
     *  @param transactionID, the id of the transaction for wich we save the signature
     *  @param the actual image containing the signature
     */
    func saveSignatureImageForTransaction(image: UIImage) {
        signatureImage = image
        
        guard let transactionID = offlineTransaction?.transactionID,
              let status = offlineManager?.saveSignatureForTransaction(transactionID: transactionID, image: image) else {
            return
        }
        delegate?.didAcceptOfflineSignature(status: status, transactionID: transactionID)
    }
    
    func resaveSignatureImageForTransaction() {
        guard let signatureImage = signatureImage else { return }
        
        saveSignatureImageForTransaction(image: signatureImage)
    }
    
    /**
     * Saves  the image representing the user's signature
     *  @param transactionID, the id of the transaction for wich we save the signature
     *  @param the actual image containing the signature
     */
    func saveEmailForTransaction(emailAddress: String) {
        guard let transactionID = offlineTransaction?.transactionID else { return }
        offlineManager?.saveEmailForTransaction(transactionID: transactionID, emailAddress: emailAddress)
    }
    
    // MARK: - Private
    
    private func calculateFeeFor(amount: Double, feeType: ServiceFeeType, feeValue: Double) -> Double {
        switch feeType {
        case .PERCENTAGE:
            return amount * feeValue / 100
        case .FLATFEE:
            return feeValue
        }
    }
    
    private func sendOfflineTransaction(offlineTransaction: OfflineTransaction, token: ClearentTransactionToken?, completion: @escaping ((ClearentError?, TransactionResponse?) -> Void)) {

        guard let token = token else {
            completion(.init(type: .missingToken), nil)
            return
        }

        // make sure we have two decimals otherwise the API will return an error
        let saleEntity = offlineTransaction.paymentData.saleEntity
        saleEntity.amount = saleEntity.amount.setTwoDecimals()
        saleEntity.tipAmount = saleEntity.tipAmount?.setTwoDecimals()
        
        saleTransaction(jwt: token.jwt, saleEntity: saleEntity) { [weak self] (response, error) in
            if error != nil {
                completion(error, response)
            } else  {
                guard let image = self?.offlineManager?.retrieveSignatureForTransaction(transactionID: offlineTransaction.transactionID) else {
                    completion(nil, nil)
                    return
                }
                self?.sendSignatureRequest(image: image) { (_, error) in
                    guard let emailAddress = self?.offlineManager?.retrieveEmailForTransaction(transactionID: offlineTransaction.transactionID) else {
                        completion(error, nil)
                        return
                    }
                    self?.sendReceiptRequest(emailAddress: emailAddress) { (_, error) in
                        completion(error, nil)
                    }
                }
            }
        }
    }
}
