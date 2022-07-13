//
//  SaleEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public struct ManualEntryCardInfo {
    let card: String
    let expirationDateMMYY: String
    let csc: String
}

public class SaleEntity: CodableProtocol {
    var amount: String
    var tipAmount, softwareType, softwareTypeVersion: String?
    let billing, shipping: ClientInformation?
    let card, csc, customerID, invoice, orderID: String?

    init(amount: String, tipAmount: String? = nil, softwareType: String? = nil, softwareTypeVersion: String? = nil, billing: ClientInformation? = nil, shipping: ClientInformation? = nil, card: String? = nil, clientIP: String? = nil, csc: String? = nil, customerID: String? = nil, invoice: String? = nil, orderID: String? = nil) {
        self.amount = amount
        self.tipAmount = tipAmount
        self.softwareType = softwareType
        self.softwareTypeVersion = softwareTypeVersion
        self.billing = billing
        self.shipping = shipping
        self.card = card
        self.csc = csc
        self.customerID = customerID
        self.invoice = invoice
        self.orderID = orderID
    }

    enum CodingKeys: String, CodingKey {
        case shipping, amount, billing, card, csc, invoice
        case customerID = "customer-id"
        case orderID = "order-id"
        case tipAmount = "tip-amount"
        case softwareType = "software-type"
        case softwareTypeVersion = "software-type-version"
    }
}


// MARK: - ClientInformation

struct ClientInformation: Codable {
    let company, firstName, fromZip, lastName, zip: String?

    enum CodingKeys: String, CodingKey {
        case company
        case firstName = "first-name"
        case fromZip = "from-zip"
        case lastName = "last-name"
        case zip
    }
    
    init(company: String? = nil, firstName: String? = nil, fromZip: String? = nil, lastName: String? = nil, zip: String? = nil) {
        self.company = company
        self.firstName = firstName
        self.fromZip = fromZip
        self.lastName = lastName
        self.zip = zip
    }
}
