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
    var links: [Links]?
    var payload: Payload
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
