//
//  OfflineMode.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 22.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

enum OfflineTransactionType : Int, Codable {
    case cardTransaction = 0
    case manualTransaction
}

enum OfflineTransactionStatus : Int, Codable {
    case error = 0
    case new
}

class BasePaymentData : CodableProtocol {
    var saleEntity: SaleEntity?
}

class ManualPaymentData : BasePaymentData {
    var cardData: String = ""
}

class CardPaymentData : BasePaymentData {
    var token: String = ""
}

struct OfflineTransaction: CodableProtocol  {
    var transactionID: String?
    var status: OfflineTransactionStatus
    var errorString: String?
    var type: OfflineTransactionType
    var paymentData: BasePaymentData?
    
    init(transactionID: String? = nil, status: OfflineTransactionStatus, errorString: String? = nil, type: OfflineTransactionType, paymentData: BasePaymentData? = nil) {
        self.transactionID  = (transactionID == nil) ? UUID().uuidString : transactionID
        self.status = status
        self.errorString = errorString
        self.type = type
        self.paymentData = paymentData
    }
        
    enum CodingKeys: String, CodingKey {
        case transactionID, errorString, paymentData
        case status = "transaction-status"
        case type = "transaction-type"
    }
}

class OfflineModeManager {
    
    private var storage: TransactionStorageProtocol
    
    init(storage: TransactionStorageProtocol) {
        self.storage = storage
    }
    
    func saveOfflineTransaction(transaction:OfflineTransaction) {
        _ = storage.save(transaction: transaction)
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
    
    func save(transaction: OfflineTransaction) -> TransactionStorageStatus {
        let oftr = transaction.encode()
        guard let encodedTransaction = oftr else { return .parsingError }
        
        var currentSavedItems: NSMutableArray? = nil
        
        // retrive the current saved data
        let savedData = helper.read(service: serviceName, account: account)
        
        if let savedData = savedData {
            do {
                let current = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
                currentSavedItems = NSMutableArray.init(array: current!)
                currentSavedItems?.addObjects(from: [encodedTransaction])
            } catch {
                currentSavedItems = NSMutableArray()
                currentSavedItems?.addObjects(from: [encodedTransaction])
            }
        } else {
            currentSavedItems = NSMutableArray()
            currentSavedItems?.addObjects(from: [encodedTransaction])
        }
       
        var data = Data()
        do {
            if currentSavedItems != nil {
                data = try NSKeyedArchiver.archivedData(withRootObject: currentSavedItems as Any, requiringSecureCoding: true)
            } else {
                return .genericError
            }
        } catch {
            return .genericError
        }
            
        let result = helper.save(data, service: serviceName, account: account)
        if result != errSecSuccess {
            return .genericError
        } else {
            return .success
        }

    }
    
    func retriveAll() -> [OfflineTransaction] {
        var result : [OfflineTransaction] = []
        var currentSavedItems: NSArray? = nil
        
        // retrive the current saved data
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
                         
                        }
                    }
                    
                })
            } catch {
                return []
            }
        }
        
        return result
    }
    
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStorageStatus {
        return .genericError
    }
    
    func deleteTransactionWith(id: String) -> TransactionStorageStatus {
        return .genericError
    }
}

/// Posible errors when saving data

enum TransactionStorageStatus: String {
    case parsingError
    case success
    case genericError
    case fullDiskError
    case validationError
}


/// Defines a protocol for the transactions storage

protocol TransactionStorageProtocol {
    
    /// Saves a offline transaction
    func save(transaction: OfflineTransaction) -> TransactionStorageStatus
    
    /// Retrives all transactions
    func retriveAll() -> [OfflineTransaction]
    
    /// Updates a transaction
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStorageStatus
    
    
    /// Deletes a transaction
    func deleteTransactionWith(id: String) -> TransactionStorageStatus
}
