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
    //var surchargeApplied: String?
    var refID: String?
    var customerFirstName: String?
    var customerLastName: String?
    var customerID: String?
    var lastFourDigits: String?
    var epirationDate: String?
    var amount: String?
    var tipAmount: String?
    var empowerAmount: String?
    var orderID: String?
    var invoice: String?
    var billing: Address?
    var shipping : Address?
    
    enum CodingKeys: String, CodingKey {
        case message = "display-message"
        case result = "result"
        //case surchargeApplied = "surcharge-applied"
        case refID = "ref-id"
        case customerFirstName = "customer-first-name"
        case customerLastName = "customer-last-name"
        case customerID = "customer-id"
        case lastFourDigits = "last-four"
        case epirationDate = "exp-date"
        case amount = "amount"
        case tipAmount = "tip-amount"
        case empowerAmount = "service-fee"
        case orderID = "order-id"
        case invoice = "invoice"
    }
}

struct TransactionStatus {
    static let approved = "APPROVED"
    static let declined = "DECLINED"
}


public struct Address: Codable {
    var city: String
    var company: String
    var country: String
    var firstName: String
    var lastName: String
    var phone: String
    var state: String
    var street: String
    var street2: String
    var zip: String
    
    enum CodingKeys: String, CodingKey {
        case city, company, country, phone, state, street, street2, zip
        case firstName = "first-name"
        case lastName = "last-name"
    }
}
