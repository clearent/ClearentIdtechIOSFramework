//
//  OfflineModeEntities.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 11.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public enum OfflineTransactionType :String, Codable {
    case cardReaderTransaction
    case manualTransaction
    case none
}

/**
 * ErrorStatus class represents an error received when the offline transaction is sent to the backend and fails
*/
public struct ErrorStatus: Codable {
    var error: ClearentError
    var updatedDate: Date
}

/**
 * OfflineTransaction class represents an offline transaction.
 * Can be encoded / decoded as json in order to be saved / retrieved / processed.
*/
public struct OfflineTransaction: CodableProtocol  {
    var createdDate: Date?
    var transactionID: String
    var paymentData: PaymentData
    var errorStatus: ErrorStatus?
    var transactionResponse: TransactionResponse?
    
    init(transactionID: String = UUID().uuidString, createdDate: Date? = nil, errorStatus: ErrorStatus? = nil, paymentData: PaymentData) {
        self.createdDate = Date()
        self.transactionID  = transactionID
        self.paymentData = paymentData
        self.errorStatus = errorStatus
    }
        
    enum CodingKeys: String, CodingKey {
        case transactionID, paymentData, createdDate, errorStatus, transactionResponse
    }
    
    func transactionType() -> OfflineTransactionType {
         if (paymentData.saleEntity.card != nil && paymentData.cardToken == nil) {
            return .manualTransaction
        } else if (paymentData.cardToken != nil && paymentData.saleEntity.card == nil) {
            return .cardReaderTransaction
        }
        
        return .none
    }
}

/**
 * PaymentData class represents a manual or card reader payment data, basicly card information and sum/tips/client info.
 * Can be encoded / decoded as json in order to be saved / retrieved / processed.
*/
class PaymentData : CodableProtocol {
    var saleEntity: SaleEntity
    var cardToken: Data?
    
    init(saleEntity: SaleEntity, cardToken: Data? = nil) {
        self.cardToken = cardToken
        self.saleEntity = saleEntity
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
    
    /// Saves an offline transaction
    func save(transaction: OfflineTransaction) -> TransactionStoreStatus
    
    /// Retrieves all the transactions
    func retrieveAll() -> [OfflineTransaction]
    
    /// Updates a transaction
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus
    
    /// Deletes a transaction
    func deleteTransactionWith(id: String) -> TransactionStoreStatus
    
    // Deletes a transaction
    func deleteAllData()
}
