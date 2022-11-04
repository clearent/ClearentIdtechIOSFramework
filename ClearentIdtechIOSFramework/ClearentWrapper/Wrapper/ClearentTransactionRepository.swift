//
//  ClearentTransactionRepository.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 21.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

protocol TransactionRepositoryProtocol {
    var delegate: ClearentWrapperProtocol? { get set }
    var tipEnabled: Bool { get set }
    var offlineManager: OfflineModeManager? { get set }
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)
    func sendSignatureRequest(image: UIImage, completion: @escaping (SignatureResponse?, ClearentError?) -> Void)
    func resendSignature(completion: @escaping (SignatureResponse?, ClearentError?) -> Void)
    func refundTransaction(jwt: String, amount: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)
    func voidTransaction(transactionID: String, completion: @escaping (TransactionResponse?, ClearentError?) -> Void)
    func fetchTipSetting(completion: @escaping () -> Void)
    func processOfflineTransactions(completion: @escaping (() -> Void))
    func manualEntryTransaction(saleEntity: SaleEntity)
    func saveOfflineTransaction(paymentData: PaymentData)
    func saveSignatureImageForTransaction(image: UIImage)
    func fetchOfflineTransactions() -> [OfflineTransaction]?
}

class TransactionRepository: NSObject, TransactionRepositoryProtocol {
    var delegate: ClearentWrapperProtocol?
    var tipEnabled = false
    var offlineManager: OfflineModeManager?
    private var lastTransactionID: String?
    private var signatureImage: UIImage?
    private var httpClient: ClearentHttpClientProtocol
    private var clearentManualEntry: ClearentManualEntry?
    private var clearentVP3300: Clearent_VP3300?
    private var offlineTransaction: OfflineTransaction? = nil
    
    init(httpClient: ClearentHttpClientProtocol? = nil, baseURL: String, apiKey: String, clearentVP3300: Clearent_VP3300, clearentManualEntry: ClearentManualEntry?) {
        self.httpClient = httpClient ?? ClearentDefaultHttpClient(baseURL: baseURL, apiKey: apiKey)
        super.init()
        self.clearentManualEntry = clearentManualEntry
        self.clearentVP3300 = clearentVP3300
    }
    
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (TransactionResponse?, ClearentError?) -> Void) {
        httpClient.saleTransaction(jwt: jwt, saleEntity: saleEntity) { data, error in
            guard let responseData = data else {
                completion(nil, ClearentError(type: .httpError))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(TransactionResponse.self, from: responseData)
                guard let transactionError = decodedResponse.payload.error else {
                    if let linksItem = decodedResponse.links?.first {
                        self.lastTransactionID = linksItem.id
                    }
                    completion(decodedResponse, nil)
                    return
                }
                completion(decodedResponse, ClearentError(type: .httpError, code: transactionError.code, message: transactionError.message))
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
            let base64Image = image.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
            httpClient.sendSignature(base64Image: base64Image, transactionID: tid) { data, error in
                guard let responseData = data else { return }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(SignatureResponse.self, from: responseData)
                    guard let signatureError = decodedResponse.payload.error else {
                        self.signatureImage = nil
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
    
    func fetchTipSetting(completion: @escaping () -> Void) {
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
    
    func processOfflineTransactions(completion: @escaping (() -> Void)) {
        guard let offlineTransactions = offlineManager?.retriveAll() else { return }
        var operations: [AsyncBlockOperation] = []
        
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .utility
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
                    strongSelf.clearentManualEntry?.createOfflineTransactionToken(card) { [weak self] token in
                        self?.sendOfflineTransaction(offlineTransaction: tr, token: token) { error in
                            _ = self?.offlineManager?.updateOfflineTransaction(with: error, transaction: tr)
                            operation.state = .finished
                        }
                    }
                } else {
                    strongSelf.clearentVP3300?.fetchTransactionToken(tr.paymentData.cardToken) { [weak self] token in
                        self?.sendOfflineTransaction(offlineTransaction: tr, token: token) { error in
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
            operationQueue.addOperations(operations, waitUntilFinished: true)
            completion()
        }
    }
    
    /**
     * Method that performs a manual card transaction
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
     * Saves and validates offline transactions, calls a delegate method with the result
     *  @param transaction, represents an offline transaction
     */
    func saveOfflineTransaction(paymentData: PaymentData) {
        let offtr = OfflineTransaction(paymentData: paymentData)
        offlineTransaction = offtr
        guard let status = offlineManager?.saveOfflineTransaction(transaction: offtr) else { return  }
        self.delegate?.didAcceptOfflineTransaction(err: status)
    }
    
    /**
     * Retrive all stored offline transactions
     */
    func fetchOfflineTransactions() -> [OfflineTransaction]? {
        return offlineManager?.retriveAll()
    }
    
    /**
     * Saves  the image represnting the user's signature
     *  @param transactionID, the id of the transcation for wich we save the signature
     *  @param the actual  image contianing the signature
     */
    func saveSignatureImageForTransaction(image: UIImage) {
        guard let transactionID = offlineTransaction?.transactionID,
             let status = offlineManager?.saveSignatureForTransaction(transactionID: transactionID, image: image) else {
            return
        }
        self.delegate?.didAcceptOfflineSignature(err: status, transactionID: transactionID)
    }
    
    // MARK: - Private
    private func sendOfflineTransaction(offlineTransaction: OfflineTransaction, token: ClearentTransactionToken?, completion: @escaping ((ClearentError?) -> Void)) {
        guard let token = token else {
            completion(.init(type: .missingToken))
            return
        }

        // make sure we have two decimals otherwise the API will return an error
        let saleEntity = offlineTransaction.paymentData.saleEntity
        saleEntity.amount = saleEntity.amount.setTwoDecimals()
        saleEntity.tipAmount = saleEntity.tipAmount?.setTwoDecimals()
        
        saleTransaction(jwt: token.jwt, saleEntity: saleEntity) { [weak self] (response, error) in
            if error != nil {
                completion(error)
            } else  {
                guard let image = self?.offlineManager?.retriveSignatureForTransaction(transactionID: offlineTransaction.transactionID) else {
                    completion(nil)
                    return
                }
                self?.sendSignatureRequest(image: image) { (_, error) in
                    completion(error)
                }
            }
        }
    }
}
