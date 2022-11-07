//
//  Entities.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 14.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public struct TransactionResponse: Codable {
    var code: String
    var status: String
    var exchange_id: String
    var links: [Links]?
    var payload: Payload
    
    enum CodingKeys: String, CodingKey {
        case code, status, links, payload, exchange_id = "exchange-id"
    }
}

public struct SignatureResponse: Codable {
    var code: String
    var status: String
    var links: [Links]?
    var payload: Payload
}

public struct Links: Codable {
    var rel: String
    var href: String
    var id: String
}

public struct Payload: Codable {
    var error: ResponseError?
    var transaction: Transaction?
    var payloadType: String
}

public struct ResponseError: Codable {
    var code: String
    var message: String

    enum CodingKeys: String, CodingKey {
        case code = "result-code"
        case message = "error-message"
    }
}

public struct Transaction: Codable {
    var message: String
    var result: String
    
    enum CodingKeys: String, CodingKey {
        case message = "display-message"
        case result = "result"
    }
}

struct TransactionStatus {
    static let approved = "APPROVED"
    static let declined = "DECLINED"
}
