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
}

enum TransactionType : String {
    case sale = "SALE", refund = "REFUND", void = "VOID"
}

class ClearentHttpClient {
    
    let httpClient: HttpClient?
    let baseURL: String
    let apiKey: String
    
    // MARK: Init
    
    public init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.httpClient = HttpClient(baseURL: URL(string: baseURL)!)
    }
    
    
    // MARK - Public
    
    public func saleTransaction(jwt: String, amount: String, tipAmount: String, completion: @escaping (Data?, Error?) -> Void) {
        let saleURL = URL(string: baseURL + ClearentEndpoints.sale)
        let headers = headersForTransaction(jwt: jwt, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: saleURL!, method: transactionMethod(type: TransactionType.sale.rawValue, amount: amount, tipAmount: tipAmount), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    public func refundTransaction(jwt: String, amount: String, completion: @escaping (Data?, Error?) -> Void) {
        let refundURL = URL(string: baseURL + ClearentEndpoints.refund)
        let headers = headersForTransaction(jwt: jwt, apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: refundURL!, method: transactionMethod(type: TransactionType.refund.rawValue, amount: amount, tipAmount: "0.00"), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    public func voidTransaction(transactionID: String, completion: @escaping (Data?, Error?) -> Void) {
        let voidURL = URL(string: baseURL + ClearentEndpoints.void)
        let headers = headersForVoidTransaction(apiKey: self.apiKey)
        let _ = HttpClient.makeRawRequest(to: voidURL!, method: voidHTTPMethod(transactionID: transactionID), headers: headers) { data, error in
            completion(data, error)
        }
    }
    
    // MARK - Private
    
    private func transactionMethod(type: String, amount: String, tipAmount: String) -> HttpClient.HTTPMethod {
        let method = HttpClient.HTTPMethod.POST(transactionBody(type: type, amount: amount, tipAmount: tipAmount))
        return method
    }
    
    private func transactionBody(type:String, amount: String, tipAmount: String) -> HttpClient.HTTPBody {
        var paramsDictionary = ["amount":amount, "type":type, "software-type": ClientInfo.softwareType, "software-type-version":ClientInfo.softwareTypeVersion]
        if (tipAmount != "0.00") {
            paramsDictionary["tip-amount"] = tipAmount
        }
        let body = HttpClient.HTTPBody.parameters(paramsDictionary, HttpClient.ParameterEncoding.json)
        return body
    }
    
    private func headersForTransaction(jwt: String, apiKey:String) -> Dictionary<String, String> {
        let headers = ["mobilejwt": jwt, "Content-Type": "application/json", "Accept": "application/json", "api-key" : apiKey]
        return headers
    }
    
    private func headersForVoidTransaction(apiKey:String) -> Dictionary<String, String> {
        let headers = ["Content-Type": "application/json", "Accept": "application/json", "api-key" : apiKey]
        return headers
    }
    
    private func voidHTTPMethod(transactionID:String) -> HttpClient.HTTPMethod {
        let paramsDictionary = ["id":transactionID, "type":TransactionType.void.rawValue, "software-type": ClientInfo.softwareType, "software-type-version":ClientInfo.softwareTypeVersion]
        let body = HttpClient.HTTPBody.parameters(paramsDictionary, HttpClient.ParameterEncoding.json)
        return HttpClient.HTTPMethod.POST(body)
    }
}
