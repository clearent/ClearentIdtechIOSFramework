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
    
    override func setUp() {
        let baseURL = "https://test-clearent.net"
        
        let config = ClearentVP3300Config(noContactlessNoConfiguration: baseURL, publicKey: "test_public_key")
        let vp3300Mock = ClearentVP3300Mock(connectionHandling: self, clearentVP3300Configuration: config)
        httpClientMock = HttpClientMock()
        offlineManager = OfflineModeManager(storage: KeyChainStorage(serviceName: "test_service_name1", account: "test_account_name2", encryptionKey: SymmetricKey(data: SHA256.hash(data: "some_secret_here".data(using: .utf8)!))))
        
        sut = TransactionRepository(httpClient: httpClientMock, baseURL: baseURL, apiKey: "test_api_key", clearentVP3300: vp3300Mock!, clearentManualEntry: ClearentManualEntryMock())
        sut.offlineManager = offlineManager
    }
    
    override func tearDown() {
        sut = nil
        offlineManager.clearStorage()
        offlineManager = nil
        httpClientMock = nil
        super.tearDown()
    }
    
    func testProcessOfflineTransactions_success() {
        // Given
        let exp = expectation(description: "Process offline transactions")
        offlineManager.generateOfflineTransactions(count: 1, cardReaderTransactions: true)
        offlineManager.generateOfflineTransactions(count: 2, cardReaderTransactions: false)
        httpClientMock.shouldSucceed = true
        
        // When
        sut.processOfflineTransactions() {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 2)
        
        // Then
        let allOfflineTransactions = offlineManager.retrieveAll()
        XCTAssertEqual(allOfflineTransactions.count, 3)
        allOfflineTransactions.forEach {
            XCTAssertEqual($0.errorStatus?.error.type, ClearentErrorType.none)
        }
    }
    
    func testProcessOfflineTransactions_failure() {
        // Given
        let exp = expectation(description: "Process offline transactions")
        offlineManager.generateOfflineTransactions(count: 1, cardReaderTransactions: true)
        offlineManager.generateOfflineTransactions(count: 2, cardReaderTransactions: false)
        httpClientMock.shouldSucceed = false
        
        // When
        sut.processOfflineTransactions() {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 2)
        
        // Then
        let allOfflineTransactions = offlineManager.retrieveAll()
        XCTAssertEqual(allOfflineTransactions.count, 3)
        allOfflineTransactions.forEach {
            XCTAssertNotEqual($0.errorStatus?.error.type, ClearentErrorType.none)
        }
    }
}

extension ClearentTransactionRepositoryTests: Clearent_Public_IDTech_VP3300_Delegate {
    func successOfflineTransactionToken(_ clearentTokenRequestData: Data!, isTransactionEncrypted isEncrypted: Bool) {}
    func successTransactionToken(_ clearentTransactionToken: ClearentTransactionToken!) {}
    func successOfflineTransactionToken(_ clearentTokenRequestData: Data!) {}
    func feedback(_ clearentFeedback: ClearentFeedback!) {}
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
