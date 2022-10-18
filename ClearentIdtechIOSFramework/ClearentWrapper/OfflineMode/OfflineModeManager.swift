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
 * Offline Manager, handles the offlline transactions, saves, updates, deletes, retrives, processing and reporting.
 */
class OfflineModeManager {
    public var storage: TransactionStorageProtocol

    init(storage: TransactionStorageProtocol) {
        self.storage = storage
    }

    func saveOfflineTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus {
        var result: TransactionStoreStatus = .success
        
        result = validateOfflineTransaction(transaction: transaction)
        if result != .success {
            return result
        }

        return storage.save(transaction: transaction)
    }

    func retriveAll() -> [OfflineTransaction] {
        return storage.retriveAll()
    }

    func saveSignatureForTransaction(transactionID: String, image: UIImage) -> TransactionStoreStatus {
        if let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: transactionID)
            UserDefaults.standard.synchronize()
            return .success
        }

        return .genericError
    }

    func retriveSignatureForTransaction(transactionID: String) -> UIImage! {
        if let imageData = UserDefaults.standard.value(forKey: transactionID) as? Data {
            if let sigantureImage = UIImage(data: imageData) {
                return sigantureImage
            }
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
