//
//  OfflineModeKeychainStorage.swift.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 22.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CryptoKit
import Foundation

/**
 * KeyChainStorage Implements the TransactionStorageProtocol
 * It saves/retrives encrypts/decrypts the saved data
 */

class KeyChainStorage: TransactionStorageProtocol {
    var serviceName: String
    var account: String
    var encryptionKey: SymmetricKey
    let helper = KeychainHelper.standard

    init(serviceName: String, account: String, encryptionKey: SymmetricKey) {
        self.serviceName = serviceName
        self.account = account
        self.encryptionKey = encryptionKey
    }

    func save(transaction: OfflineTransaction) -> TransactionStoreStatus {
        let oftr = transaction.encode()
        guard let encodedTransaction = oftr else { return .parsingError }

        var currentSavedItems = NSMutableArray()

        // Encrypt
        guard let encryptedData = try? ClearentCryptor.encrypt(encryptionKey: encryptionKey, contentData: encodedTransaction) else { return .encryptionError }

        if let savedData = helper.read(service: serviceName, account: account) {
            let current = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
            if let current = current {
                currentSavedItems = NSMutableArray(array: current)
                currentSavedItems.addObjects(from: [encryptedData])
            }
        } else {
            currentSavedItems.addObjects(from: [encryptedData])
        }

        return saveOfflineTransactionArray(offlineTransactions: currentSavedItems)
    }

    func retriveAll() -> [OfflineTransaction] {
        var result: [OfflineTransaction] = []
        var currentSavedItems: NSArray?

        // Retrive the current saved data
        let savedData = helper.read(service: serviceName, account: account)

        // Unarchive, decode, decrypt data
        if let savedData = savedData {
            currentSavedItems = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: savedData)
            currentSavedItems?.forEach({ item in
                let data = item as? Data
                if let newData = data,
                   let decryptedData = try? ClearentCryptor.decrypt(encryptionKey: encryptionKey, encryptedContent: newData),
                   let decodedResponse = try? JSONDecoder().decode(OfflineTransaction.self, from: decryptedData) {
                       result.append(decodedResponse)
                }
            })
        }

        return result
    }

    /// Fetches the saved data, searches for matching item , replaces the item  and saves the data, returns an error if the item is not found
    /// If succesfull it will overwrite the data
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus {
        var response: TransactionStoreStatus = .success
        var result: [OfflineTransaction] = retriveAll()

        let count = result.count
        result.removeAll(where: { $0.transactionID == transaction.transactionID })

        if count == result.count {
            response = .transactionDoesNotExist
        } else {
            result.append(transaction)
            return encryptAndSaveTransactions(transactions: result)
        }

        return response
    }

    func deleteTransactionWith(id: String) -> TransactionStoreStatus {
        var response: TransactionStoreStatus = .success
        var result: [OfflineTransaction] = retriveAll()

        let count = result.count
        result.removeAll(where: { $0.transactionID == id })

        if count == result.count {
            response = .transactionDoesNotExist
        } else {
            return encryptAndSaveTransactions(transactions: result)
        }

        return response
    }

    func deleteAllData() {
        helper.delete(service: serviceName, account: account)
    }

    private func encryptAndSaveTransactions(transactions: [OfflineTransaction]) -> TransactionStoreStatus {
        let currentSavedItems = NSMutableArray()
        transactions.forEach { oftr in
            if let transaction = oftr.encode() {
                if let encryptedData = try? ClearentCryptor.encrypt(encryptionKey: encryptionKey, contentData: transaction) {
                    currentSavedItems.add(encryptedData)
                }
            }
        }

        return saveOfflineTransactionArray(offlineTransactions: currentSavedItems)
    }
    
    private func saveOfflineTransactionArray(offlineTransactions: NSArray) -> TransactionStoreStatus {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: offlineTransactions as Any, requiringSecureCoding: true) {
            let result = helper.save(data, service: serviceName, account: account)
            if result != errSecSuccess {
                return .genericError
            } else {
                return .success
            }
        }

        return .encryptionError
    }
}
