//
//  OfflineMode.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 22.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

/**
 * KeyChainStorage Implements the TransactionStorageProtocol
 * It saves encrypts/decrypts the saved data
*/

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
      
        // Unarchive, decode, decrypt the data and add it to the result array
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
    
    /// Fetches the saved data, serches for matching item , replaces the item  and saves the data, return an error if the item is not found
    func updateTransaction(transaction: OfflineTransaction) -> TransactionStoreStatus {
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
        
        let symmetricKey = OfflineModeManager.encryptionKey
        
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
