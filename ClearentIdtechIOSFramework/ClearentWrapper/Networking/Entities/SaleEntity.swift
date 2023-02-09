//
//  SaleEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class SaleEntity: CodableProtocol {
    var amount: String
    var tipAmount, softwareType, softwareTypeVersion: String?
    var billing, shipping: ClientInformation?
    var card, csc, customerID, invoice, orderID: String?
    var expirationDateMMYY: String?
    var serviceFeeAmount: String?
    var externelRefID: String?

    public init(amount: String, tipAmount: String? = nil, softwareType: String? = nil, softwareTypeVersion: String? = nil, billing: ClientInformation? = nil, shipping: ClientInformation? = nil, card: String? = nil, csc: String? = nil, customerID: String? = nil, invoice: String? = nil, orderID: String? = nil, expirationDateMMYY: String? = nil, serviceFeeAmount: String? = nil, externelRefID: String? = nil) {
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
        self.expirationDateMMYY = expirationDateMMYY
        self.serviceFeeAmount = serviceFeeAmount?.setTwoDecimals()
        self.externelRefID = externelRefID
    }

    enum CodingKeys: String, CodingKey {
        case shipping, amount, billing, card, csc, invoice, externelRefID
        case customerID = "customer-id"
        case orderID = "order-id"
        case tipAmount = "tip-amount"
        case softwareType = "software-type"
        case softwareTypeVersion = "software-type-version"
        case expirationDateMMYY = "exp-date"
        case serviceFeeAmount = "service-fee"
    }
}

extension SaleEntity {
    enum SoftwareTypeNaming {
        static let separator = "_"
        static let sdkTitle = "Xplor Pay SDK"
        static let hostAppTitle = "xplor"
        static let offlineText = "offline"
        static let platform = "iOS"
    }
    
    /**
     Updates software type based on the following scenarios:
      1. Host App is Xplor Pay Mobile ->  Xplor Pay Mobile_[offline]_iOS
      2. Integrator didn’t add anything -> Xplor Pay SDK_<sdk version>_ [offline]_iOS
      3. Otherwise -> <integrator's choice>_Xplor Pay SDK_<sdk version>_[offline]_iOS
     */
    func updateSoftwareType(isOfflineTransaction: Bool) {
        var softwareType = softwareType ?? ""
        softwareTypeVersion = ClearentWrapper.shared.currentSDKVersion()
        if !softwareType.lowercased().contains(SoftwareTypeNaming.hostAppTitle) { // checks if the Host App is Xplor app
            if !softwareType.isEmpty {
                softwareType.append(contentsOf: SoftwareTypeNaming.separator)
            }
            softwareType.append(contentsOf: SoftwareTypeNaming.sdkTitle)
            if let sdkVersion = softwareTypeVersion {
                softwareType.append(contentsOf: "\(SoftwareTypeNaming.separator)\(sdkVersion)")
            }
        }
        if isOfflineTransaction {
            softwareType.append(contentsOf: "\(SoftwareTypeNaming.separator)\(SoftwareTypeNaming.offlineText)")
        }
        softwareType.append(contentsOf: "\(SoftwareTypeNaming.separator)\(SoftwareTypeNaming.platform)")
        self.softwareType = softwareType
    }
}

// MARK: - ClientInformation

@objc public class ClientInformation: NSObject, Codable {
    let company, firstName, fromZip, lastName, zip, street, city, phone: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first-name"
        case lastName = "last-name"
        case company
        case fromZip = "from-zip"
        case zip
        case street
        case city
        case phone
    }

    init?(firstName: String? = nil, lastName: String? = nil, company: String? = nil, fromZip: String? = nil, zip: String? = nil, street: String? = nil, city: String? = nil, phone: String? = nil) {
        if firstName == nil, lastName == nil, company == nil, fromZip == nil, zip == nil {
            return nil
        }
        self.company = company
        self.firstName = firstName
        self.fromZip = fromZip
        self.lastName = lastName
        self.zip = zip
        self.street = street
        self.city = city
        self.phone = phone
    }
}
