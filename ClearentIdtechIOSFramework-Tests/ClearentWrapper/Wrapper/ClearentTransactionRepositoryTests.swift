//
//  ClearentTransactionRepository.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 25.10.2022.
//

import XCTest
import CryptoKit
@testable import ClearentIdtechIOSFramework

class ClearentTransactionRepositoryTests: XCTestCase {
    var sut: TransactionRepository!
    var offlineManager: OfflineModeManager!
    var httpClientMock: HttpClientMock!
    let testJwt = "eyJhbGciOiJIUzI1NiJ9.eyJtb2JpbGUtand0LWV4Y2hhbmdlLWNoYWluLWlkIjoiSU9TLUlEVEVDSC1WUDMzMDAtMjcyMjctMjAyMi0xMC0yNS0xMy0yMS00Mi04NzYtRUVTVCIsImxhc3QtZm91ciI6IjAwMTEiLCJ0cmFjay1kYXRhLWhhc2giOiIzMDU2NEE3QzVDN0UzMkI4NUQ4N0REODM3NkUyNzMwOTFFQjFEMjFEREY0M0Q5M0VGNjFFMjA0QjVEMUFCMDE1IiwiZGV2aWNlLWZvcm1hdCI6IklEVEVDSCIsImVtdi1lbnRyeS1tb2RlIjoiRU1WX0RJUCIsImN2bSI6Ik1TRyIsInR5cGUiOiJNT0JJTEUiLCJleHAiOjE2NjY3Nzk3MDMsInRva2VuIjoiMjAwMDAwMDAwMDE1MjUwOCJ9.y8dE453-nkaamGf-g_yJ3lxC4QLiYTNBZZxs8k_ezaM"
    
    override func setUp() {
        let baseURL = "https://test-clearent.net"
        
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: "test_public_key")
        let vp3300Mock = ClearentVP3300Mock(connectionHandling: self, clearentVP3300Configuration: config)
        httpClientMock = HttpClientMock()
        offlineManager = OfflineModeManager(storage: KeyChainStorage(serviceName: "test_service_name1", account: "test_account_name2", encryptionKey: SymmetricKey(data: SHA256.hash(data: "some_secret_here".data(using: .utf8)!))))
        
        sut = TransactionRepository(httpClient: httpClientMock, baseURL: baseURL, apiKey: "test_api_key", clearentVP3300: vp3300Mock!, clearentManualEntryDelegate: nil)
        sut.offlineManager = offlineManager
        sut.clearentManualEntry = ClearentManualEntryMock()
    }
    
    override func tearDown() {
        sut = nil
        offlineManager.clearStorage()
        offlineManager = nil
        httpClientMock = nil
        ClearentWrapperDefaults.removeAllValues()
        super.tearDown()
    }
    
    
    func testServiceFeeForAmount_type_percentage() {
        // Given
        ClearentWrapperDefaults.terminalSettings = TerminalSettings(tipEnabled: false, serviceFeeState: .ENABLED, serviceFee: "1.00", serviceFeeType: .PERCENTAGE, serviceFeeProgram: .NON_CASH_ADJUSTMENT)
        
        // Then
        XCTAssertEqual(sut.serviceFeeForAmount(amount: 200.00), 2)
    }
    
    func testServiceFeeForAmount_type_flatFee() {
        // Given
        ClearentWrapperDefaults.terminalSettings = TerminalSettings(tipEnabled: false, serviceFeeState: .ENABLED, serviceFee: "1.00", serviceFeeType: .FLATFEE, serviceFeeProgram: .NON_CASH_ADJUSTMENT)
        
        // Then
        XCTAssertEqual(sut.serviceFeeForAmount(amount: 200.00), 1.0)
    }
    
    func testServiceFeeForAmount_disabled() {
        // Given
        ClearentWrapperDefaults.terminalSettings = TerminalSettings(tipEnabled: false, serviceFeeState: .DISABLED, serviceFee: "1.00", serviceFeeType: .FLATFEE, serviceFeeProgram: .NON_CASH_ADJUSTMENT)
        
        // Then
        XCTAssertNil(sut.serviceFeeForAmount(amount: 200.00))
    }
    
    func testRefundTransaction_success() {
        // Given
        let exp = expectation(description: "Process offline transactions")
        
        // When
        httpClientMock.shouldSucceed = true
        
        // Then
        sut.refundTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "20.25")) { (response, error) in
            XCTAssertNil(error)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testRefundTransaction_failure() {
        // Given
        let exp = expectation(description: "Process offline transactions")
        
        // When
        httpClientMock.shouldSucceed = false
        
        // Then
        sut.refundTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "20.25")) { (response, error) in
            guard let error = error else {
                XCTFail("Error shouldn't be nil")
                return
            }
            XCTAssertEqual(error.type, ClearentErrorType.httpError)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testSendSignatureRequest_success() throws {
        // Given
        let exp = expectation(description: "`Send signature`")
        let validImage = try XCTUnwrap(emptyImage())
        
        // When
        httpClientMock.shouldSucceed = true
        sut.saleTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "20.00"), isOfflineTransaction: false) { [weak self] (transactionResponse, error) in
            self?.sut.sendSignatureRequest(image: validImage) { (signatureResponse, error) in
                // Then
                XCTAssertNil(error)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5)
        
    }
    
    func testSendSignatureRequest_failure() {
        // Given
        let exp = expectation(description: "Send signature")
        let invalidImage = UIImage()
        
        // When
        httpClientMock.shouldSucceed = true
        sut.saleTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "20.00"), isOfflineTransaction: false) { [weak self] (transactionResponse, error) in
            self?.sut.sendSignatureRequest(image: invalidImage) { (signatureResponse, signatureError) in
                // Then
                guard let signatureError = signatureError else {
                    XCTFail("Error shouldn't be nil")
                    return
                }
                XCTAssertEqual(signatureError.type, ClearentErrorType.missingSignatureImage)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testResendSignature_success() throws {
        // Given
        let exp = expectation(description: "Resend signature")
        let validImage = try XCTUnwrap(emptyImage())
        httpClientMock.shouldSucceed = true
        
        // When
        sut.saleTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "2.00"), isOfflineTransaction: false) { [weak self] (response1, error1) in
            self?.httpClientMock.shouldSucceed = false
            self?.sut.signatureImage = validImage
            self?.sut.sendSignatureRequest(image: validImage) { [weak self] (response2, error2) in
                XCTAssertNotNil(self?.sut.signatureImage)
                self?.httpClientMock.shouldSucceed = true
                self?.sut.resendSignature() { (response3, error3) in
                    // Then
                    XCTAssertNil(self?.sut.signatureImage)
                    XCTAssertNil(error3)
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testResendSignature_failure() {
        // Given
        let exp = expectation(description: "Resend signature")
        let invalidImage = UIImage()
        httpClientMock.shouldSucceed = true
        
        // When
        sut.saleTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "2.00"), isOfflineTransaction: false) { [weak self] (response1, error1) in
            self?.sut.signatureImage = invalidImage
            self?.httpClientMock.shouldSucceed = false
            self?.sut.sendSignatureRequest(image: invalidImage) { [weak self] (response2, error2) in
                XCTAssertNotNil(self?.sut.signatureImage)
                self?.httpClientMock.shouldSucceed = true
                self?.sut.resendSignature() { (response3, error3) in
                    // Then
                    XCTAssertNotNil(self?.sut.signatureImage)
                    XCTAssertNotNil(error3)
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testSendReceiptRequest_success() {
        // Given
        let exp = expectation(description: "Send receipt")
        httpClientMock.shouldSucceed = true
        
        //When
        sut.saleTransaction(jwt: testJwt, saleEntity: SaleEntity(amount: "20.00"), isOfflineTransaction: false) { [weak self] (transactionResponse, error) in
            XCTAssertNil(error)
            self?.sut.sendReceiptRequest(emailAddress: "john@hmail.com") { (receiptResponse, receiptError) in
                // Then
                XCTAssertNil(receiptError)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testSendReceiptRequest_failure_noTransactionId() {
        // Given
        let exp = expectation(description: "Send receipt")
        
        // When
        sut.sendReceiptRequest(emailAddress: "john@hmail.com") { (receiptResponse, receiptError) in
            // Then
            guard let receiptError = receiptError else {
                XCTFail("Error shouldn't be nil")
                return
            }
            XCTAssertEqual(receiptError.type, ClearentErrorType.missingData)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testFetchTerminalSetting_success() {
        // Given
        let exp = expectation(description: "Fetch terminal settings")
        ClearentWrapper.configuration = ClearentWrapperConfiguration(baseURL: "test_base_url", apiKey: nil, publicKey: nil)
        httpClientMock.shouldSucceed = true
        XCTAssertNil(sut.clearentManualEntry?.publicKey)
        
        // When
        sut.fetchTerminalSetting() { [weak self] error in
            // Then
            XCTAssertNil(error)
            XCTAssertTrue(ClearentWrapperDefaults.terminalSettings?.tipEnabled ?? false)
            XCTAssertEqual(ClearentWrapperDefaults.terminalSettings?.serviceFeeType, .PERCENTAGE)
            XCTAssertEqual(ClearentWrapperDefaults.terminalSettings?.serviceFeeProgram, .CONVENIENCE_FEE)
            XCTAssertEqual(self?.sut.clearentManualEntry?.publicKey, "test_public_key")
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
    
    func testFetchTerminalSetting_failure() {
        // Given
        let exp = expectation(description: "Fetch terminal settings")
        ClearentWrapper.configuration = ClearentWrapperConfiguration(baseURL: "test_base_url", apiKey: nil, publicKey: nil)
        httpClientMock.shouldSucceed = false
        XCTAssertNil(sut.clearentManualEntry?.publicKey)
        
        // When
        sut.fetchTerminalSetting() { [weak self] error in
            // Then
            XCTAssertEqual(error?.type, ClearentErrorType.httpError)
            XCTAssertNil(ClearentWrapperDefaults.terminalSettings)
            XCTAssertNil(self?.sut.clearentManualEntry?.publicKey)
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
    
    func testProcessOfflineTransactions_success() throws {
        // Given
        let exp = expectation(description: "Process offline transactions")
        offlineManager.generateOfflineTransactions(count: 1, cardReaderTransactions: true)
        offlineManager.generateOfflineTransactions(count: 2, cardReaderTransactions: false)
        httpClientMock.shouldSucceed = true
        
        // When
        sut.processOfflineTransactions() { [weak self] in
            // Then
            guard let strongSelf = self else {
                XCTFail("self should not be nil")
                return
            }
            let allOfflineTransactions = strongSelf.offlineManager.retrieveAll()
            XCTAssertEqual(allOfflineTransactions.count, 3)
            allOfflineTransactions.forEach {
                XCTAssertEqual($0.errorStatus?.error.type, ClearentErrorType.none)
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testProcessOfflineTransactions_failure() throws {
        // Given
        let exp = expectation(description: "Process offline transactions fail")
        offlineManager.generateOfflineTransactions(count: 1, cardReaderTransactions: true)
        offlineManager.generateOfflineTransactions(count: 2, cardReaderTransactions: false)
        httpClientMock.shouldSucceed = false
        
        // When
        sut.processOfflineTransactions() { [weak self] in
            // Then
            guard let strongSelf = self else {
                XCTFail("self should not be nil")
                return
            }
            let allOfflineTransactions = strongSelf.offlineManager.retrieveAll()
            XCTAssertEqual(allOfflineTransactions.count, 3)
            allOfflineTransactions.forEach {
                XCTAssertEqual($0.errorStatus?.error.type, ClearentErrorType.httpError)
            }
            exp.fulfill()
            
        }
        waitForExpectations(timeout: 0.5)
    }
}


extension ClearentTransactionRepositoryTests: Clearent_Public_IDTech_VP3300_Delegate {
    func successOfflineTransactionToken(_ clearentTokenRequestData: Data!, isTransactionEncrypted isEncrypted: Bool) {}
    func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {}
    func successOfflineTransactionToken(_ clearentTokenRequestData: Data!) {}
    func feedback(_ clearentFeedback: ClearentFeedback!) {}
}

// MARK: - Helper methods
extension ClearentTransactionRepositoryTests {
    private func emptyImage(size: CGSize = CGSize(width: 24.0, height: 24.0)) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class ClearentVP3300Mock: Clearent_VP3300 {
    override convenience init!(connectionHandling publicDelegate: Clearent_Public_IDTech_VP3300_Delegate!, clearentVP3300Configuration: ClearentVP3300Configuration!) {
        self.init()
    }
    
    override init() {
        super.init()
    }
    
    override func fetchTransactionToken(_ postData: Data!) async -> ClearentTransactionToken? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "ClearentTransactionToken", withExtension: "json"),
              let jsonString = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return ClearentTransactionToken(json: jsonString)
    }
}

class ClearentManualEntryMock: ClearentManualEntry {
    override func createOfflineTransactionToken(_ clearentCard: ClearentCard!) async -> ClearentTransactionToken? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "ClearentTransactionToken", withExtension: "json"),
              let jsonString = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return ClearentTransactionToken(json: jsonString)
    }
}
