//
//  HttpClientMock.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 25.10.2022.
//

@testable import ClearentIdtechIOSFramework

class HttpClientMock: ClearentHttpClientProtocol {
    var shouldSucceed: Bool = false
    
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void) {
        handleTransactionResponse(completion: completion)
    }
    
    func refundTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void) {
        handleTransactionResponse(completion: completion)
    }
    
    func voidTransaction(transactionID: String, completion: @escaping (Data?, Error?) -> Void) {
        handleTransactionResponse(completion: completion)
    }
    
    func sendSignature(base64Image: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void) {
        if shouldSucceed {
            let responseMock = SignatureResponse(code: "200", status: "success", links: nil, payload: Payload(error: nil, transaction: nil, payloadType: "signature"))
            guard let json = try? JSONEncoder().encode(responseMock) else { return }
            completion(json, nil)
        } else {
            completion(nil, NSError(domain: "test-domain", code: 400))
        }
    }
    
    func sendReceipt(emailAddress: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void) {
        if shouldSucceed {
            let responseMock = ReceiptResponse(code: "200", status: "success", payload: Payload(payloadType: "receipt"))
            guard let json = try? JSONEncoder().encode(responseMock) else { return }
            completion(json, nil)
        } else {
            completion(nil, NSError(domain: "test-domain", code: 400))
        }
    }
    
    func terminalSettings(completion: @escaping (Data?, Error?) -> Void) {
        if shouldSucceed {
            let responseMock = TerminalSettingsResponse(payload: PayloadSettings(terminalSettings: TerminalSettings(tipEnabled: true, serviceFeeState: .ENABLED, serviceFee: "1.00", serviceFeeType: .PERCENTAGE, serviceFeeProgram:  .CONVENIENCE_FEE)))
            guard let json = try? JSONEncoder().encode(responseMock) else { return }
            completion(json, nil)
        } else {
            completion(nil, NSError(domain: "test-domain", code: 400))
        }
    }
    
    func hppSettings(completion: @escaping (Data?, Error?) -> Void) {
        if shouldSucceed {
            let responseMock = HppSettingsResponse(payload: HppPayloadSettings(hppSettings: HppSettings(hppPublicKey: "test_public_key")))
            guard let json = try? JSONEncoder().encode(responseMock) else { return }
            completion(json, nil)
        } else {
            completion(nil, NSError(domain: "test-domain", code: 400))
        }
    }
    
    func updateWebAuth(with auth: ClearentIdtechIOSFramework.ClearentWebAuth) {
        
    }
    
    func hasAuth() -> Bool { true }
    
    private func handleTransactionResponse(completion: @escaping (Data?, Error?) -> Void) {
        if shouldSucceed {
            let linksMock = Links(rel: "test_rel", href: "test_href", id: "123")
            let responseMock = TransactionResponse(code: "200", status: "success", exchange_id: "ID-clearent-mobile-jwt-1-57d719e7-7c62-4e95-b8ee-d3a4acbada50", links: [linksMock], payload: Payload(error: nil, transaction: nil, payloadType: "transaction"))
            guard let json = try? JSONEncoder().encode(responseMock) else { return }
            completion(json, nil)
        } else {
            completion(nil, NSError(domain: "test-domain", code: 400))
        }
    }
}
