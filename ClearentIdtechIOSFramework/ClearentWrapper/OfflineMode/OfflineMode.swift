//
//  OfflineMode.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 22.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import CryptoKit

enum OfflineTransactionType :String, Codable {
    case cardReaderTransaction
    case manualTransaction
    case none
}

struct ErrorStatus: Codable {
    var message: String
    var updatedDate: Date
}


/**
 * PaymentData class represents a manual or card reader payment data, basicly card information and sum/tips/client info.
 * Can be encoded/decoded as json in order to be saved/retrived/processed.
*/
class PaymentData : CodableProtocol {
    var saleEntity: SaleEntity
    var cardToken: Data?
    
    init(saleEntity: SaleEntity, cardToken: Data? = nil) {
        self.cardToken = cardToken
        self.saleEntity = saleEntity
    }
}


/**
 * OfflineTransaction class represents an offline transaction.
 * Can be encoded/decoded as json in order to be saved/retrived/processed.
*/
struct OfflineTransaction: CodableProtocol  {
    var createdDate: Date?
    var transactionID: String?
    var paymentData: PaymentData
    var errorStatus: ErrorStatus?
    
    init(transactionID: String? = nil, createdDate: Date? = nil, errorStatus: ErrorStatus? = nil, paymentData: PaymentData) {
        self.createdDate = Date()
        self.transactionID  = (transactionID == nil) ? UUID().uuidString : transactionID
        self.paymentData = paymentData
        self.errorStatus = errorStatus
    }
        
    enum CodingKeys: String, CodingKey {
        case transactionID, paymentData, createdDate, errorStatus
    }
    
    func transactionType() -> OfflineTransactionType {
        if (paymentData.cardToken != nil) {
            return .cardReaderTransaction
        } else if (paymentData.saleEntity.card != nil && paymentData.cardToken == nil) {
            return .manualTransaction
        }
        
        return .none
    }
}

/**
 * Offline Manager, handles the offlline transactions, saves, updates, deletes, retrives, processing and reporting.
 */
class OfflineModeManager {
    
    static let encryptionKey = SymmetricKey(data:SHA256.hash(data: "some_secret_key_here".data(using: .utf8)!))
    public var storage: TransactionStorageProtocol
    
    init(storage: TransactionStorageProtocol) {
        self.storage = storage
    }
    
    func saveOfflineTransaction(transaction:OfflineTransaction) -> TransactionStoreStatus {
        var result: TransactionStoreStatus = .success
        
        if (transaction.transactionType() == .manualTransaction) {
            result = validateManualOfflineTransaction(saleEntity: transaction.paymentData.saleEntity)
            if (result != .success) {
                return result
            }
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
    
    func validateManualOfflineTransaction(saleEntity: SaleEntity) -> TransactionStoreStatus {
        if let cardNo = saleEntity.card, let csc = saleEntity.csc, let expirationDate = saleEntity.expirationDateMMYY {
            
            let cardnoItem = CreditCardNoItem()
            cardnoItem.enteredValue = cardNo
            
            let securityCodeItem = SecurityCodeItem()
            securityCodeItem.enteredValue = csc
            
            let expirationDateItem = DateItem()
            expirationDateItem.enteredValue = expirationDate
            
            if (ClearentFieldValidationHelper.isCardNumberValid(item: cardnoItem) &&
                ClearentFieldValidationHelper.isSecurityCodeValid(item: securityCodeItem) &&
                ClearentFieldValidationHelper.isExpirationDateValid(item: expirationDateItem)) {
                return .success
            }
        }
        
        return .validationError
    }
}

/**
 * Cryptor Manager, handles the encryption and decryption
 */

class ClearentCryptor {
    
    static func encrypt(encryptionKey: SymmetricKey, contentData: Data) throws -> Data? {
        var result : Data? = nil
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

class KeyChainStorage: TransactionStorageProtocol {

    var serviceName: String
    var account: String
    let helper = KeychainHelper.standard
    
    init(serviceName: String, account: String) {
        self.serviceName = serviceName
        self.account = account
    }
    
    func save(transaction: OfflineTransaction) -> TransactionStoreStatus {
        let oftr = transaction.encode()
        guard let encodedTransaction = oftr else { return .parsingError }
        
        var currentSavedItems = NSMutableArray()
        
        // Retrive the current saved data
        let savedData = helper.read(service: serviceName, account: account)
        
        // Encrypt
        let symmetricKey = OfflineModeManager.encryptionKey
        guard let encryptedData = try? ClearentCryptor.encrypt(encryptionKey:symmetricKey , contentData: encodedTransaction) else { return .encryptionError }
        
        if let savedData = savedData {
            let current = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
            if let current = current {
                currentSavedItems = NSMutableArray.init(array: current)
                currentSavedItems.addObjects(from: [encryptedData])
            }
        }
       
        return saveOfflineTransactionArray(offlineTransactions: currentSavedItems)
    }
    
    func retriveAll() -> [OfflineTransaction] {
        var result : [OfflineTransaction] = []
        var currentSavedItems: NSArray? = nil

        // Decryption
        let symmetricKey = OfflineModeManager.encryptionKey
        
        // Retrive the current saved data
        let savedData = helper.read(service: serviceName, account: account)
      
        // Unarachive, decode, decrypt the data and add it to the result array
        if let savedData = savedData {
            currentSavedItems = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
            currentSavedItems?.forEach({ item in
                let data = item as? Data
                if let newData = data {
                    if let decryptedData = try? ClearentCryptor.decrypt(encryptionKey: symmetricKey, encryptedContent: newData) {
                        let decodedResponse = try? JSONDecoder().decode(OfflineTransaction.self, from: decryptedData)
                        if let decodedResponse = decodedResponse {
                            result.append(decodedResponse)
                        }
                    }
                }
            })
        }
        
        return result
    }
    
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus {
        // Retrive the current saved data
        guard let savedData = helper.read(service: serviceName, account: account) else { return .genericError }
        
        var result : [OfflineTransaction] = []
        var currentSavedItems: NSArray? = nil
        
        do {
            currentSavedItems = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
        } catch {
            return .genericError
        }
        
        let symmetricKey = OfflineModeManager.encryptionKey
        
        var response : TransactionStoreStatus = .success
        currentSavedItems?.forEach({ item in
            let data = item as? Data
            if let newData = data {
                if let decryptedData = try? ClearentCryptor.decrypt(encryptionKey: symmetricKey, encryptedContent: newData) {
                    let decodedResponse = try? JSONDecoder().decode(OfflineTransaction.self, from: decryptedData)
                    if let decodedResponse = decodedResponse {
                        result.append(decodedResponse)
                    }
                }
            }
        })
                
        let count = result.count
        result.removeAll(where: {$0.transactionID! == transaction.transactionID})
        
        if count == result.count {
            response = .transactionDoesNotExist
        } else {
            result.append(transaction)
            let currentSavedItems: NSMutableArray = NSMutableArray.init(array: [])
            result.forEach { oftr in
                if let transaction = oftr.encode() {
                    let encryptedData = try? ClearentCryptor.encrypt(encryptionKey:symmetricKey , contentData: transaction)
                        if let encryptedData = encryptedData {
                            currentSavedItems.add(encryptedData)
                        }
                }
            }
            
            return saveOfflineTransactionArray(offlineTransactions: currentSavedItems)
        }
        
        return response
    }
    
    func deleteTransactionWith(id: String) -> TransactionStoreStatus {
        // Retrive the current saved data
        guard let savedData = helper.read(service: serviceName, account: account) else { return .genericError }
      
        var result : [OfflineTransaction] = []
        var currentSavedItems: NSArray? = nil
        
        do {
            currentSavedItems = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
        } catch {
            return .genericError
        }
        
        let encryptionKey = Data(base64Encoded: ClearentWrapper.shared.apiKey)
        guard let key = encryptionKey else { return .encryptionError}
        let symmetricKey = SymmetricKey(data: key)
        
        var response : TransactionStoreStatus = .success
        currentSavedItems?.forEach({ item in
            let data = item as? Data
            if let newData = data {
                do {
                    if let decryptedData = try? ClearentCryptor.decrypt(encryptionKey: symmetricKey, encryptedContent: newData) {
                        let decodedResponse = try JSONDecoder().decode(OfflineTransaction.self, from: decryptedData)
                        result.append(decodedResponse)
                    }
                } catch {
                    response = .parsingError
                }
            }
        })
        
        let count = result.count
        result.removeAll(where: {$0.transactionID! == id})
        
        if count == result.count {
            response = .transactionDoesNotExist
        } else {
            let currentSavedItems: NSMutableArray = NSMutableArray.init(array: [])
            result.forEach { oftr in
                if let transaction = oftr.encode() {
                    currentSavedItems.add(transaction)
                }
            }
            
            return saveOfflineTransactionArray(offlineTransactions: currentSavedItems)
        }
        
        return response
    }
    
    
    private func saveOfflineTransactionArray(offlineTransactions:NSArray) -> TransactionStoreStatus {
        var data = Data()
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: offlineTransactions as Any, requiringSecureCoding: true)
        } catch {
            return .genericError
        }
        
        let result =  helper.save(data, service: serviceName, account: account)
        if result != errSecSuccess {
            return .genericError
        } else {
            return .success
        }
    }
}

/// Posible errors when saving data
public enum TransactionStoreStatus: String {
    case parsingError
    case success
    case genericError
    case fullDiskError
    case validationError
    case encryptionError
    case transactionDoesNotExist
}


/// Defines a protocol for the transactions storage
protocol TransactionStorageProtocol {
    
    /// Saves a offline transaction
    func save(transaction: OfflineTransaction) -> TransactionStoreStatus
    
    /// Retrives all transactions
    func retriveAll() -> [OfflineTransaction]
    
    /// Updates a transaction
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus
    
    /// Deletes a transaction
    func deleteTransactionWith(id: String) -> TransactionStoreStatus
}
