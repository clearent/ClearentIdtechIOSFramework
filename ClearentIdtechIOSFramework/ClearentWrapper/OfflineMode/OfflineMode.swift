//
//  OfflineMode.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 22.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

enum OfflineTransactionType {
    case cardTransaction
    case manualTransaction
}

enum OfflineTransactionStatus {
    case error
    case new
}

class BasePaymentData : CodableProtocol {
    var saleEntity: SaleEntity?
}

class ManualPaymentData : BasePaymentData {
    var request: String = ""
}

class CardPaymentData : BasePaymentData {
    var idTechToken: String = ""
}

class OfflineTransaction  {
    var transactionID: String
    var status: OfflineTransactionStatus
    var errorString: String?
    var type: OfflineTransactionType
    var paymentData: BasePaymentData
    
    init(transactionID: String, status: OfflineTransactionStatus, errorString: String? = nil, type: OfflineTransactionType, paymentData: BasePaymentData) {
        self.transactionID = transactionID
        self.status = status
        self.errorString = errorString
        self.type = type
        self.paymentData = paymentData
    }
    
    enum CodingKeys: String, CodingKey {
        case transactionID, status, errorString, type, paymentData
    }
}

class OfflineModeManager {
    private var storage: TransactionStorageProtocol
    
    init(storage: TransactionStorageProtocol) {
        self.storage = storage
    }
    
    func addOfflineTransaction(transaction:OfflineTransaction) {
        storage.save(transaction: transaction)
    }
}


class OfflineStorage : TransactionStorageProtocol {
    
    func save(transaction: OfflineTransaction) {
        // save something
    }
    
    func retriveAll() -> [OfflineTransaction] {
        return []
    }
    
    func updateTransaction(transaction: OfflineTransaction) {
        // update Something
    }
    
    func deleteTransactionWith(id: String) {
        // deleteSomething
    }
}

protocol TransactionStorageProtocol {
    func save(transaction: OfflineTransaction)
    func retriveAll() -> [OfflineTransaction]
    func updateTransaction(transaction: OfflineTransaction)
    func deleteTransactionWith(id:String)
}
