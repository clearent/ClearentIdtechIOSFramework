//
//  HttpClient.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 23.03.2022.
//

import Foundation


private struct ClearentEndpoints {
    static let sale: String = "/rest/v2/mobile/transactions/sale"
    static let refund: String = "/rest/v2/mobile/transactions/refund"
    static let void: String = "/rest/v2/transactions/void"
    static let signature: String = "/rest/v2/signature"
    static let receipt = "/rest/v2/receipts"
    static let terminalSettings = "/rest/v2/settings/terminal"
    static let hppSettings = "\(terminalSettings)/hpp"
}

enum TransactionType : String {
    case sale = "SALE", refund = "REFUND", void = "VOID"
}

protocol ClearentHttpClientProtocol {
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void)
    func refundTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void)
    func voidTransaction(transactionID: String, completion: @escaping (Data?, Error?) -> Void)
    func sendSignature(base64Image: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void)
    func sendReceipt(emailAddress: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void)
    func terminalSettings(completion: @escaping (Data?, Error?) -> Void)
    func hppSettings(completion: @escaping (Data?, Error?) -> Void)
    func updateWebAuth(with auth: ClearentWebAuth)
    func hasAuth() -> Bool
}

class ClearentDefaultHttpClient: ClearentHttpClientProtocol {
    
    // MARK: - Properties
    
    var httpClient: HttpClient? = nil
    let baseURL: String
    let apiKey: String?
    var webAuth: ClearentWebAuth?
    
    // MARK: Init
    
    public init(baseURL: String, apiKey: String?, webAuth: ClearentWebAuth? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.webAuth = webAuth
        guard let url = URL(string: baseURL) else { return }
        
        self.httpClient = HttpClient(baseURL: url)
    }
    
    // MARK - Public
    
    public func updateWebAuth(with auth: ClearentWebAuth) {
        self.webAuth = auth
    }
    
    public func hasAuth() -> Bool {
        return webAuth != nil || apiKey != nil
    }
    
    // MARK: - Internal
    
    func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void) {
        let saleURL = URL(string: baseURL + ClearentEndpoints.sale)
        let headers = headers(jwt: jwt)
        let _ = HttpClient.makeRawRequest(to: saleURL!, method: transactionMethod(type: TransactionType.sale.rawValue, saleEntity: saleEntity), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    func refundTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void) {
        let refundURL = URL(string: baseURL + ClearentEndpoints.refund)
        let headers = headers(jwt: jwt)
        let _ = HttpClient.makeRawRequest(to: refundURL!, method: transactionMethod(type: TransactionType.refund.rawValue, saleEntity: saleEntity), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    func sendSignature(base64Image: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void) {
        let created = Date().dateAndTimeToString()
        let signatureURL = URL(string: baseURL + ClearentEndpoints.signature)
        let headers = headers(jwt: nil)
        let _ = HttpClient.makeRawRequest(to: signatureURL!, method: signatureHTTPMethod(base64Image: base64Image, created: created, transactionID: transactionID), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    func sendReceipt(emailAddress: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void) {
        let receiptURL = URL(string: baseURL + ClearentEndpoints.receipt)
        let headers = headers(jwt: nil)
        let _ = HttpClient.makeRawRequest(to: receiptURL!, method: receiptHTTPMethod(emailAddress: emailAddress, transactionID: transactionID), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    func voidTransaction(transactionID: String, completion: @escaping (Data?, Error?) -> Void) {
        let voidURL = URL(string: baseURL + ClearentEndpoints.void)
        let headers = headers(jwt: nil)
        let _ = HttpClient.makeRawRequest(to: voidURL!, method: voidHTTPMethod(transactionID: transactionID), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    func terminalSettings(completion: @escaping (Data?, Error?) -> Void) {
        let settingsURL = URL(string: baseURL + ClearentEndpoints.terminalSettings)
        let headers = headers(jwt: nil)
        let _ = HttpClient.makeRawRequest(to: settingsURL!,  headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    func hppSettings(completion: @escaping (Data?, Error?) -> Void) {
        let settingsURL = URL(string: baseURL + ClearentEndpoints.hppSettings)
        let headers = headers(jwt: nil)
        let _ = HttpClient.makeRawRequest(to: settingsURL!,  headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    // MARK - Private
    
    private func transactionMethod(type: String, saleEntity: SaleEntity) -> HttpClient.HTTPMethod {
        HttpClient.HTTPMethod.POST(transactionBody(type: type, saleEntity: saleEntity))
    }
    
    private func transactionBody(type:String, saleEntity: SaleEntity) -> HttpClient.HTTPBody {
        let body = HttpClient.HTTPBody.codableObject(saleEntity, HttpClient.ParameterEncoding.json)
        return body
    }
    
    private func headers(jwt: String?) -> Dictionary<String, String> {
        var headers = ["Content-Type": "application/json", "Accept": "application/json"]
        if let jwt = jwt {
            headers["mobilejwt"] = jwt
        }
        
        if let webAuth = webAuth {
            headers["Authorization"] = "vt-token " + webAuth.vtToken
            headers["MerchantID"] = webAuth.merchantID
        } else if let apiKey = apiKey {
            headers["api-key"] = apiKey
        }
        
        return headers
    }
    
    private func voidHTTPMethod(transactionID:String) -> HttpClient.HTTPMethod {
        let paramsDictionary = ["id":transactionID, "type":TransactionType.void.rawValue]
        let body = HttpClient.HTTPBody.parameters(paramsDictionary, HttpClient.ParameterEncoding.json)
        return HttpClient.HTTPMethod.POST(body)
    }
    
    private func signatureHTTPMethod(base64Image: String, created: String, transactionID: Int) -> HttpClient.HTTPMethod {
        let signatureEntity = SignatureEntity(base64Image: base64Image, created: created, transactionID: transactionID)
        let body = HttpClient.HTTPBody.codableObject(signatureEntity, HttpClient.ParameterEncoding.json)
        return HttpClient.HTTPMethod.POST(body)
    }
    
    private func receiptHTTPMethod(emailAddress: String, transactionID: Int) -> HttpClient.HTTPMethod {
        let signatureEntity = ReceiptEntity(emailAddress: emailAddress, id: transactionID)
        let body = HttpClient.HTTPBody.codableObject(signatureEntity, HttpClient.ParameterEncoding.json)
        return HttpClient.HTTPMethod.POST(body)
    }
}

public protocol CodableProtocol: Codable {}

extension CodableProtocol {
    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        guard let json = try? encoder.encode(self) else { return nil }
        return json
    }
}
