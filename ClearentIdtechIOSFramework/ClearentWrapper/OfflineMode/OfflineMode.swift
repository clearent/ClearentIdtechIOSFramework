//
//  OfflineMode.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 22.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

enum OfflineTransactionType :String, Codable {
    case cardReaderTransaction
    case manualTransaction
    case none
}

struct ErrorStatus: Codable {
    var message: String
    var updatedDate: Date
}

class PaymentData : CodableProtocol {
    var saleEntity: SaleEntity
    var cardToken: String?
    
    init(saleEntity: SaleEntity, cardToken: String? = nil) {
        self.cardToken = cardToken
        self.saleEntity = saleEntity
    }
}

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
            return .cardReaderTransaction
        }
        
        return .none
    }
}

class OfflineModeManager {
    
    public var storage: TransactionStorageProtocol
    
    init(storage: TransactionStorageProtocol) {
        self.storage = storage
    }
    
    func saveOfflineTransaction(transaction:OfflineTransaction) ->TransactionStoreStatus {
        return storage.save(transaction: transaction)
    }
    
    func retriveAll() -> [OfflineTransaction] {
        return storage.retriveAll()
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
        
        var currentSavedItems: NSMutableArray
        
        // retrive the current saved data
        let savedData = helper.read(service: serviceName, account: account)
        
        if let savedData = savedData {
            do {
                let current = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
                currentSavedItems = NSMutableArray.init(array: current!)
                currentSavedItems.addObjects(from: [encodedTransaction])
            } catch {
                currentSavedItems = NSMutableArray()
                currentSavedItems.addObjects(from: [encodedTransaction])
            }
        } else {
            currentSavedItems = NSMutableArray()
            currentSavedItems.addObjects(from: [encodedTransaction])
        }
       
        return saveOfflineTransactionArray(offlineTransactions: currentSavedItems)
    }
    
    func retriveAll() -> [OfflineTransaction] {
        var result : [OfflineTransaction] = []
        var currentSavedItems: NSArray? = nil
        
        // Retrive the current saved data
        let savedData = helper.read(service: serviceName, account: account)
        
        if let savedData = savedData {
            do {
                currentSavedItems = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
                currentSavedItems?.forEach({ item in
                    let data = item as? Data
                    if let newData = data {
                        do {
                            let decodedResponse = try JSONDecoder().decode(OfflineTransaction.self, from: newData)
                            result.append(decodedResponse)
                        } catch {
                            //should cath an error here
                        }
                    }
                    
                })
            } catch {
                return []
            }
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
        
        var response : TransactionStoreStatus = .success
        currentSavedItems?.forEach({ item in
            let data = item as? Data
            if let newData = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(OfflineTransaction.self, from: newData)
                    result.append(decodedResponse)
                } catch {
                    response = .parsingError
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
                    currentSavedItems.add(transaction)
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
        
        var response : TransactionStoreStatus = .success
        currentSavedItems?.forEach({ item in
            let data = item as? Data
            if let newData = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(OfflineTransaction.self, from: newData)
                    result.append(decodedResponse)
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

enum TransactionStoreStatus: String {
    case parsingError
    case success
    case genericError
    case fullDiskError
    case validationError
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
