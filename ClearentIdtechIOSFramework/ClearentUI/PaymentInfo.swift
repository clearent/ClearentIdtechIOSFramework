//
//  PaymentInfo.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 14.12.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

@objc public class PaymentInfo: NSObject {
    public var amount: Double
    public var customerID: String?
    public var invoice: String?
    public var orderID: String?
    public var billing: ClientInformation?
    public var shipping: ClientInformation?
    public var softwareType: String?
    
    @objc public init(amount: Double, customerID: String? = nil, invoice: String? = nil, orderID: String? = nil, billing: ClientInformation? = nil, shipping: ClientInformation? = nil, softwareType: String? = nil) {
        self.amount = amount
        self.customerID = customerID
        self.invoice = invoice
        self.orderID = orderID
        self.billing = billing
        self.shipping = shipping
        self.softwareType = softwareType
    }
}
