//
//  OfflineModeManagerTests.swift
//  XplorPayMobileTests
//
//  Created by Ovidiu Rotaru on 12.10.2022.
//

@testable import ClearentIdtechIOSFramework
import CryptoKit
import XCTest

class OfflineModeManagerTests: XCTestCase {
    var sut: OfflineModeManager!

    override func setUp() {
        super.setUp()
        sut = OfflineModeManager(storage: KeyChainStorage(serviceName: "test_service_name1", account: "test_account_name2", encryptionKey: SymmetricKey(data: SHA256.hash(data: "some_secret_here".data(using: .utf8)!))))
    }
    
    override func tearDown() {
        sut.clearStorage()
        sut = nil
        super.tearDown()
    }

    func testOfflineTransactionType() {
        /// Card Transaction
        let saleEntity = SaleEntity(amount: "20.00")
        let cardReaderPaymentData = PaymentData(saleEntity: saleEntity, cardToken: "some_secret_token_here".data(using: .utf8))
        let cardReaderOfflineTransaction = OfflineTransaction(paymentData: cardReaderPaymentData)
        XCTAssertTrue(cardReaderOfflineTransaction.transactionType() == .cardReaderTransaction)

        /// Manual  Transaction
        let manualCardSaleEntity = SaleEntity(amount: "20.0", card: "4761340000000019", csc: "946", expirationDateMMYY: "122")
        let paymentDataWitManualCard = PaymentData(saleEntity: manualCardSaleEntity, cardToken: nil)
        let manualcardTransaction = OfflineTransaction(paymentData: paymentDataWitManualCard)
        XCTAssertTrue(manualcardTransaction.transactionType() == .manualTransaction)

        /// Invalid Transaction , has both card and manual
        let invalidPaymentData = PaymentData(saleEntity: manualCardSaleEntity, cardToken: "some_secret_token_here".data(using: .utf8))
        let invalidOfflineTransaction = OfflineTransaction(paymentData: invalidPaymentData)
        XCTAssertTrue(invalidOfflineTransaction.transactionType() == .none)
    }

    func testManualOfflineValidationForCardData() {
        
        /// Valid format for all card details
        var manualTransactionPaymentData = PaymentData(saleEntity: SaleEntity(amount: "20.0", card: "4761340000000019", csc: "946", expirationDateMMYY: "1223"))
        var manualTransaction = OfflineTransaction(paymentData: manualTransactionPaymentData)
        XCTAssertTrue(sut.validateOfflineTransaction(transaction: manualTransaction) == .success)

        /// Invalid format for card no
        manualTransactionPaymentData = PaymentData(saleEntity: SaleEntity(amount: "20.0", card: "476134", csc: "946", expirationDateMMYY: "1299"))
        manualTransaction = OfflineTransaction(paymentData: manualTransactionPaymentData)
        XCTAssertTrue(sut.validateOfflineTransaction(transaction: manualTransaction) == .validationError)

        /// Invalid format for csc
        manualTransactionPaymentData = PaymentData(saleEntity: SaleEntity(amount: "20.0", card: "476134", csc: "94w6", expirationDateMMYY: "1299"))
        manualTransaction = OfflineTransaction(paymentData: manualTransactionPaymentData)
        XCTAssertTrue(sut.validateOfflineTransaction(transaction: manualTransaction) == .validationError)

        /// Invalid format for expiration date
        manualTransactionPaymentData = PaymentData(saleEntity: SaleEntity(amount: "20.0", card: "476134", csc: "94w6", expirationDateMMYY: "12-99"))
        manualTransaction = OfflineTransaction(paymentData: manualTransactionPaymentData)
        XCTAssertTrue(sut.validateOfflineTransaction(transaction: manualTransaction) == .validationError)
        
        /// Invalid amount
        manualTransactionPaymentData = PaymentData(saleEntity: SaleEntity(amount: "020.."), cardToken: "some_secret_here".data(using: .utf8))
        manualTransaction = OfflineTransaction(paymentData: manualTransactionPaymentData)
        XCTAssertTrue(sut.validateOfflineTransaction(transaction: manualTransaction) == .validationError)
        
        /// Invalid tip
        manualTransactionPaymentData = PaymentData(saleEntity: SaleEntity(amount: "20.0", tipAmount: "0a"), cardToken: "some_secret_here".data(using: .utf8))
        manualTransaction = OfflineTransaction(paymentData: manualTransactionPaymentData)
        XCTAssertTrue(sut.validateOfflineTransaction(transaction: manualTransaction) == .validationError)
    }

    func testSaveInvalidOfflineManualTransaction() {
        /// Invalid format for card no
        let invalidCardSaleEntity = SaleEntity(amount: "20.0", card: "47613400000000", csc: "946", expirationDateMMYY: "1222")
        let paymentData = PaymentData(saleEntity: invalidCardSaleEntity, cardToken: nil)
        let oftr = OfflineTransaction(paymentData: paymentData)

        XCTAssertTrue(.validationError == sut.saveOfflineTransaction(transaction: oftr))
    }

    func testSaveOfflineTransaction_manualEntry() {
        sut.generateOfflineTransactions(count: 1, cardReaderTransactions: false)
        XCTAssertTrue(sut.retrieveAll().count == 1)
        
        let savedOfflineTransaction = sut.retrieveAll().first
        XCTAssertTrue(savedOfflineTransaction?.paymentData.saleEntity.amount == "1.00")

        sut.generateOfflineTransactions(count: 1, cardReaderTransactions: false)
        XCTAssertTrue(sut.retrieveAll().count == 2)
    }
    
    func testSaveOfflineTransaction_cardReader() {
        sut.generateOfflineTransactions(count: 1, cardReaderTransactions: true)
        XCTAssertTrue(sut.retrieveAll().count == 1)

        let savedOfflineTransaction = sut.retrieveAll().first
        XCTAssertTrue(savedOfflineTransaction?.paymentData.saleEntity.amount == "1.00")

        sut.generateOfflineTransactions(count: 1, cardReaderTransactions: true)
        XCTAssertTrue(sut.retrieveAll().count == 2)
    }

    func testDeleteOfflineTransaction() {
        let saleEntity = SaleEntity(amount: "2123.00")
        let paymentData = PaymentData(saleEntity: saleEntity, cardToken: "some_secret_token_here".data(using: .utf8))
        let oftr = OfflineTransaction(paymentData: paymentData)
        let oftr2 = OfflineTransaction(paymentData: paymentData)
        let oftr3 = OfflineTransaction(paymentData: paymentData)

        XCTAssertTrue(.success == sut.saveOfflineTransaction(transaction: oftr))
        XCTAssertTrue(.success == sut.saveOfflineTransaction(transaction: oftr2))
        XCTAssertTrue(.success == sut.saveOfflineTransaction(transaction: oftr3))
        
        var all = sut.retrieveAll()
        XCTAssertTrue(all.count == 3)

        let savedOfflineTransaction = sut.retrieveAll().first
        XCTAssertTrue(savedOfflineTransaction != nil)

        var deleteStatus = sut.storage.deleteTransactionWith(id: (savedOfflineTransaction?.transactionID)!)
        XCTAssertTrue(deleteStatus == .success)

        // Try to delete the same transaction again
        deleteStatus = sut.storage.deleteTransactionWith(id: (savedOfflineTransaction?.transactionID)!)

        all = sut.retrieveAll()
        XCTAssertTrue(all.count == 2)
        XCTAssertTrue(deleteStatus == .transactionDoesNotExist)
    }

    func testUpdateOfflineTransaction() {
        let saleEntity = SaleEntity(amount: "1234563.00")
        let paymentData = PaymentData(saleEntity: saleEntity, cardToken: "some_secret_token_here".data(using: .utf8))
        let oftr = OfflineTransaction(paymentData: paymentData)

        let saveStatus = sut.saveOfflineTransaction(transaction: oftr)
        XCTAssertTrue(saveStatus == .success)
        
        if var savedOfflineTransaction = sut.retrieveAll().first {
            savedOfflineTransaction.errorStatus = ErrorStatus(error: ClearentError(type: .httpError), updatedDate:Date().dateAndTimeToString())
            let status = sut.storage.updateTransaction(transaction: savedOfflineTransaction)
            
            XCTAssertTrue(status == .success)
            XCTAssertTrue(sut.retrieveAll().count == 1)
        } else {
            XCTAssertTrue(false)
        }
        
        let firstTransaction = sut.retrieveAll().first!
        XCTAssertTrue(firstTransaction.errorStatus?.error.type == .httpError)
    }
    

    func testEncryption() {
        let saleEntity = SaleEntity(amount: "1234563.00")
        let paymentData = PaymentData(saleEntity: saleEntity, cardToken: "some_secret_token_here".data(using: .utf8))
        let oftr = OfflineTransaction(paymentData: paymentData)
        
        let encodedTransaction = oftr.encode()
        let encryptedData = try? ClearentCryptor.encrypt(encryptionKey:SymmetricKey(data: SHA256.hash(data: "some_secret_here".data(using: .utf8)!)), contentData: encodedTransaction!)
        XCTAssertTrue(encryptedData != nil)
        
        let decodedResponse = try? JSONDecoder().decode(OfflineTransaction.self, from: encryptedData!)
        XCTAssertTrue(decodedResponse == nil)
        
        let decryptedData = try? ClearentCryptor.decrypt(encryptionKey: SymmetricKey(data: SHA256.hash(data: "some_secret_here".data(using: .utf8)!)), encryptedContent: encryptedData!)
        XCTAssertTrue(decryptedData != nil)
        
        let offlineTransaction = try? JSONDecoder().decode(OfflineTransaction.self, from: decryptedData!)
        XCTAssertTrue(offlineTransaction != nil)
        XCTAssertTrue(offlineTransaction!.paymentData.saleEntity.amount == "1234563.00")
        
        // decrypt with the wrong key
        let invalidDecryptedData = try? ClearentCryptor.decrypt(encryptionKey: SymmetricKey(data: SHA256.hash(data: "some_invalid_secret_here".data(using: .utf8)!)), encryptedContent: XCTUnwrap(encryptedData))
        XCTAssertTrue(invalidDecryptedData == nil)
    }
}
