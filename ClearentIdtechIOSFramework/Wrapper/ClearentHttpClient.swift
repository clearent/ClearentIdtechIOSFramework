//
//  HttpClient.swift
//  IntegrationTest
//
//  Created by Ovidiu Rotaru on 23.03.2022.
//

import Foundation

private struct ClientInfo {
    static let softwareType = "Xplor Mobile"
    static let softwareTypeVersion = "1"
}

private struct ClearentEndpoints {
    static let sale: String = "/rest/v2/mobile/transactions/sale"
    static let refund: String = "/rest/v2/mobile/transactions/refund"
    static let void: String = "/rest/v2/transactions/void"
    static let signature: String = "/rest/v2/signature"
    static let settings = "/rest/v2/settings/terminal"
}

enum TransactionType : String {
    case sale = "SALE", refund = "REFUND", void = "VOID"
}

class ClearentHttpClient {
    
    var httpClient: HttpClient? = nil
    let baseURL: String
    let apiKey: String
    
    // MARK: Init
    
    public init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        guard let url = URL(string: baseURL) else { return }
        
        self.httpClient = HttpClient(baseURL: url)
    }
    
    // MARK - Public
    
    public func saleTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void) {
        let saleURL = URL(string: baseURL + ClearentEndpoints.sale)
        let headers = headers(jwt: jwt, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: saleURL!, method: transactionMethod(type: TransactionType.sale.rawValue, saleEntity: saleEntity), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    public func refundTransaction(jwt: String, saleEntity: SaleEntity, completion: @escaping (Data?, Error?) -> Void) {
        let refundURL = URL(string: baseURL + ClearentEndpoints.refund)
        let headers = headers(jwt: jwt, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: refundURL!, method: transactionMethod(type: TransactionType.refund.rawValue, saleEntity: saleEntity), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    public func sendSignature(base64Image: String, transactionID: Int, completion: @escaping (Data?, Error?) -> Void) {
        let created = DateFormatter().string(from: Date())
        let signatureURL = URL(string: baseURL + ClearentEndpoints.signature)
        let headers = headers(jwt: nil, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: signatureURL!, method: signatureHTTPMethod(base64Image: baseURL, created: created, transactionID: transactionID), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    public func voidTransaction(transactionID: String, completion: @escaping (Data?, Error?) -> Void) {
        let voidURL = URL(string: baseURL + ClearentEndpoints.void)
        let headers = headers(jwt: nil, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: voidURL!, method: voidHTTPMethod(transactionID: transactionID), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    public func merchantSettings(completion: @escaping (Data?, Error?) -> Void) {
        let settingsURL = URL(string: baseURL + ClearentEndpoints.settings)
        let headers = headers(jwt: nil, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: settingsURL!,  headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    // MARK - Private
    
    private func transactionMethod(type: String, saleEntity: SaleEntity) -> HttpClient.HTTPMethod {
        let method = HttpClient.HTTPMethod.POST(transactionBody(type: type, saleEntity: saleEntity))
        return method
    }
    
    private func transactionBody(type:String, saleEntity: SaleEntity) -> HttpClient.HTTPBody {
        saleEntity.softwareType = ClientInfo.softwareType
        saleEntity.softwareTypeVersion = ClientInfo.softwareTypeVersion
        let body = HttpClient.HTTPBody.codableObject(saleEntity, HttpClient.ParameterEncoding.json)
        return body
    }
    
    private func headers(jwt: String?, apiKey:String) -> Dictionary<String, String> {
        var headers = ["Content-Type": "application/json", "Accept": "application/json", "api-key" : apiKey]
        if let jwt = jwt {
            headers["mobilejwt"] = jwt
        }
        return headers
    }
    
    private func voidHTTPMethod(transactionID:String) -> HttpClient.HTTPMethod {
        let paramsDictionary = ["id":transactionID, "type":TransactionType.void.rawValue, "software-type": ClientInfo.softwareType, "software-type-version":ClientInfo.softwareTypeVersion]
        let body = HttpClient.HTTPBody.parameters(paramsDictionary, HttpClient.ParameterEncoding.json)
        return HttpClient.HTTPMethod.POST(body)
    }
    
    private func signatureHTTPMethod(base64Image: String, created: String, transactionID: Int) -> HttpClient.HTTPMethod {
        let signatureEntity = SignatureEntity(base64Image: base64Image, created: created, transactionID: transactionID)
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
