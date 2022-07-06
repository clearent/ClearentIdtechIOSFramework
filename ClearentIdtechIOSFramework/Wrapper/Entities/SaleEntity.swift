//
//  SaleEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class SaleEntity: CodableProtocol {
    let authorizationCode: String?
    let billing: ClientInformation?
    let billingIsShipping, card: String?
    let cardInquiry, checkFieldMid: Bool?
    let clientIP, comments, csc, customerID: String?
    let welcomeDescription, emailAddress, emailReceipt, invoice: String?
    let orderID: String?
    let platformFees: [PlatformFee]?
    let purchaseOrder, salesTaxAmount, salesTaxType, serviceFee: String?
    let shipping: ClientInformation?
    var softwareType, tipAmount, type: String?
    let amount: String
    var signatureBase64Image, id, softwareTypeVersion, createToken: String?
    let tokenDescription, checkField: String?

    init(authorizationCode: String? = nil, billing: ClientInformation? = nil, billingIsShipping: String? = nil, card: String? = nil, cardInquiry: Bool? = nil, checkFieldMid: Bool? = nil, clientIP: String? = nil, comments: String? = nil, csc: String? = nil, customerID: String? = nil, welcomeDescription: String? = nil, emailAddress: String? = nil, emailReceipt: String? = nil, invoice: String? = nil, orderID: String? = nil, platformFees: [PlatformFee]? = nil, purchaseOrder: String? = nil, salesTaxAmount: String? = nil, salesTaxType: String? = nil, serviceFee: String? = nil, shipping: ClientInformation? = nil, softwareType: String? = nil, tipAmount: String? = nil, type: String? = nil, amount: String, signatureBase64Image: String? = nil, id: String? = nil, softwareTypeVersion: String? = nil, createToken: String? = nil, tokenDescription: String? = nil, checkField: String? = nil) {
        
        self.authorizationCode = authorizationCode
        self.billing = billing
        self.billingIsShipping = billingIsShipping
        self.card = card
        self.cardInquiry = cardInquiry
        self.checkFieldMid = checkFieldMid
        self.clientIP = clientIP
        self.comments = comments
        self.csc = csc
        self.customerID = customerID
        self.welcomeDescription = welcomeDescription
        self.emailAddress = emailAddress
        self.emailReceipt = emailReceipt
        self.invoice = invoice
        self.orderID = orderID
        self.platformFees = platformFees
        self.purchaseOrder = purchaseOrder
        self.salesTaxAmount = salesTaxAmount
        self.salesTaxType = salesTaxType
        self.serviceFee = serviceFee
        self.shipping = shipping
        self.softwareType = softwareType
        self.tipAmount = tipAmount
        self.type = type
        self.amount = amount
        self.signatureBase64Image = signatureBase64Image
        self.id = id
        self.softwareTypeVersion = softwareTypeVersion
        self.createToken = createToken
        self.tokenDescription = tokenDescription
        self.checkField = checkField
    }

    enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization-code"
        case billing
        case billingIsShipping = "billing-is-shipping"
        case card
        case cardInquiry = "card-inquiry"
        case checkFieldMid = "check-field-mid"
        case clientIP = "client-ip"
        case comments, csc
        case customerID = "customer-id"
        case welcomeDescription = "description"
        case emailAddress = "email-address"
        case emailReceipt = "email-receipt"
        case invoice
        case orderID = "order-id"
        case platformFees = "platform-fees"
        case purchaseOrder = "purchase-order"
        case salesTaxAmount = "sales-tax-amount"
        case salesTaxType = "sales-tax-type"
        case serviceFee = "service-fee"
        case shipping
        case softwareType = "software-type"
        case tipAmount = "tip-amount"
        case type, amount
        case signatureBase64Image = "signature-base-64-image"
        case id
        case softwareTypeVersion = "software-type-version"
        case createToken = "create-token"
        case tokenDescription = "token-description"
        case checkField = "check-field"
    }
}

// MARK: - ClientInformation

struct ClientInformation: Codable {
    let city, company, country, firstName: String?
    let fromZip, lastName, phone, state: String?
    let street, street2, zip: String?

    enum CodingKeys: String, CodingKey {
        case city, company, country
        case firstName = "first-name"
        case fromZip = "from-zip"
        case lastName = "last-name"
        case phone, state, street, street2, zip
    }
}

// MARK: - PlatformFee

struct PlatformFee: Codable {
    let feeName: String?

    enum CodingKeys: String, CodingKey {
        case feeName = "fee-name"
    }
}
