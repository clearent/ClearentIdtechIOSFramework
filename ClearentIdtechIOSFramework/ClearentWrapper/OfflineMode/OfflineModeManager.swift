//
//  OfflineModeManager.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 11.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CryptoKit
import Foundation

/**
 * Offline Manager, handles the offlline transactions, saves, updates, deletes, retrieves, processing and reporting.
 */

private struct UserDefaultKeys {
    static let emailAddressPrefix = "email_"
}

class OfflineModeManager {
    
    // MARK: - Properties
    
    public var storage: TransactionStorageProtocol

    // MARK: - Init
    
    init(storage: TransactionStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Internal
    
    func saveOfflineTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus {
        var result: TransactionStoreStatus = .success
        
        result = validateOfflineTransaction(transaction: transaction)
        
        if result != .success {
            return result
        }

        return storage.save(transaction: transaction)
    }

    func retrieveAll() -> [OfflineTransaction] {
        return storage.retrieveAll()
    }

    func saveSignatureForTransaction(transactionID: String, image: UIImage) -> TransactionStoreStatus {
        if let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: transactionID)
            return .success
        }

        return .genericError
    }

    func retrieveSignatureForTransaction(transactionID: String) -> UIImage? {
        if let imageData = UserDefaults.standard.value(forKey: transactionID) as? Data {
            if let signatureImage = UIImage(data: imageData) {
                return signatureImage
            }
        }

        return nil
    }
    
    func saveEmailForTransaction(transactionID: String, emailAddress: String) {
        UserDefaults.standard.set(emailAddress, forKey: "\(UserDefaultKeys.emailAddressPrefix)\(transactionID)")
    }
    
    func retrieveEmailForTransaction(transactionID: String) -> String? {
        if let email = UserDefaults.standard.value(forKey: "\(UserDefaultKeys.emailAddressPrefix)\(transactionID)") as? String {
            return email
        }
        return nil
    }
    
    func validateOfflineTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus {
        let saleEntity = transaction.paymentData.saleEntity
        
        guard Float(saleEntity.amount) != nil else { return .validationError}
        if let tip = saleEntity.tipAmount {
           guard let _ = Float(tip) else { return .validationError}
        }
       
        if transaction.transactionType() == .none {
            return .validationError
        } else if (transaction.transactionType() == .manualTransaction) {
            if let cardNo = saleEntity.card, let csc = saleEntity.csc, let expirationDate = saleEntity.expirationDateMMYY {
                let cardnoItem = CardNoItem()
                cardnoItem.enteredValue = cardNo

                let securityCodeItem = SecurityCodeItem()
                securityCodeItem.enteredValue = csc

                let expirationDateItem = DateItem()
                expirationDateItem.enteredValue = expirationDate

                if ClearentFieldValidationHelper.isCardNumberValid(item: cardnoItem),
                    ClearentFieldValidationHelper.isSecurityCodeValid(item: securityCodeItem),
                    ClearentFieldValidationHelper.isExpirationDateValidBeforeProcessing(item: expirationDateItem) {
                    return .success
                }
            }
            
            return .validationError
        }
        
        return .success
    }

    func clearStorage() {
        storage.deleteAllData()
    }
    
    func unproccesedTransactionsCount() -> Int {
        let unprocessedOfflineTransactions = retrieveAll().filter({ tr in
            return tr.errorStatus == nil
        })
        
        return unprocessedOfflineTransactions.count
    }

    // In case an error was received during the offline transactions upload, update the transaction with the error
    // Otherwise, mark the transaction with error .none so we now it was processed succesfully
    func updateOfflineTransaction(with error: ClearentError?, transaction: OfflineTransaction, transactionResponse: TransactionResponse?) -> TransactionStoreStatus {
        
        var transactionToBeUpdated = transaction
        transactionToBeUpdated.transactionResponse = transactionResponse
        if let error = error {
            transactionToBeUpdated.errorStatus = ErrorStatus(error: error, updatedDate: Date().dateAndTimeToString())
            return storage.updateTransaction(transaction: transactionToBeUpdated)
        } else {
            transactionToBeUpdated.errorStatus = ErrorStatus(error: ClearentError.init(type: .none), updatedDate:Date().dateAndTimeToString())
            return storage.updateTransaction(transaction: transactionToBeUpdated)
        }
    }
    
    func containsUploadReport() -> Bool {
        retrieveAll().first(where: { $0.errorStatus != nil }) != nil
    }
    
    func uploadReportContainsErrors() -> Bool {
        retrieveAll().first(where: { $0.errorStatus != nil && $0.errorStatus?.error.type != ClearentErrorType.none }) != nil
    }
    
    func transactionsWithErrors() -> [OfflineTransaction]? {
        return retrieveAll().filter({ $0.errorStatus != nil && $0.errorStatus?.error.type != ClearentErrorType.none})
    }
}

/**
 * Crypto Helper, handles the encryption and decryption
 */

class ClearentCryptor {
    static func encrypt(encryptionKey: SymmetricKey, contentData: Data) throws -> Data? {
        var result: Data?
        
        do {
            result = try ChaChaPoly.seal(contentData, using: encryptionKey).combined
        } catch {
            print("Unexpected error: \(error).")
        }
        return result
    }
    
    static func decrypt(encryptionKey: SymmetricKey, encryptedContent: Data) throws -> Data? {
        let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedContent)
        return try ChaChaPoly.open(sealedBox, using: encryptionKey)
    }
}
