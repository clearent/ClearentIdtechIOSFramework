//
//  ClearentPaymentModel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 18.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

enum ClearentPaymentItemType {
    case creditCardNo, date, securityCode, cardholderFirstName, cardholderLastName, billingZipCode, invoiceNo, orderNo, companyName, customerId, shippingZipCode

    var separator: String {
        switch self {
        case .creditCardNo:
            return " "
        case .date:
            return "/"
        case .billingZipCode, .shippingZipCode:
            return "-"
        default:
            return ""
        }
    }
}

protocol ClearentPaymentSection {
    var title: String? { get }
    var isCollapsable: Bool { get }
    var isCollapsed: Bool { get set }
    var rows: [ClearentPaymentRow] { get set }
}

struct ClearentPaymentRow {
    var elements: [ClearentPaymentItem]
}

typealias ItemIdentifier = (tag: Int, indexPath: IndexPath)?

protocol ClearentPaymentItem {
    var type: ClearentPaymentItemType { get }
    var title: String { get }
    var placeholder: String? { get }
    var iconName: String? { get }
    var errorMessage: String? { get }
    var maxNoOfChars: Int { get }
    var isOptional: Bool { get }
    var identifier: ItemIdentifier { get set }
    var isValid: Bool { get set }
    var enteredValue: String { get set }
    var hiddenValue: String? { get set }
}

extension ClearentPaymentItem {
    var isOptional: Bool { true }
    var placeholder: String? { nil }
    var iconName: String? { nil }
    var errorMessage: String? { nil }
}

class ClearentPaymentBaseSection: ClearentPaymentSection {
    var title: String? { nil }

    var isCollapsable: Bool { false }

    var isCollapsed: Bool = false

    var rows: [ClearentPaymentRow] = [
        ClearentPaymentRow(elements: [CreditCardNoItem()]),
        ClearentPaymentRow(elements: [DateItem(), SecurityCodeItem()]),
        ClearentPaymentRow(elements: [CardholderFirstNameItem()]),
        ClearentPaymentRow(elements: [CardholderLastNameItem()]),
        ClearentPaymentRow(elements: [BillingZipCodeItem()])
    ]
}

class ClearentPaymentAdditionalSection: ClearentPaymentSection {
    var title: String? { ClearentConstants.Localized.ManualEntry.additionalSection }
    
    var isCollapsable: Bool { true }

    var isCollapsed: Bool = true

    var rows: [ClearentPaymentRow] = [
        ClearentPaymentRow(elements: [InvoiceNoItem()]),
        ClearentPaymentRow(elements: [OrderNoItem()]),
        ClearentPaymentRow(elements: [CompanyNameItem()]),
        ClearentPaymentRow(elements: [CustomerIDItem()]),
        ClearentPaymentRow(elements: [ShippingZipCodeItem()])
    ]
}

class CreditCardNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .creditCardNo }
    
    var title: String { ClearentConstants.Localized.ManualEntry.cardNo }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.cardNoError }

    var maxNoOfChars: Int { 19 }

    var isOptional: Bool { false }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class DateItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .date }
    
    var title: String { ClearentConstants.Localized.ManualEntry.expirationDate }
    
    var placeholder: String? { ClearentConstants.Localized.ManualEntry.expirationDatePlaceholder }
    
    var iconName: String? { ClearentConstants.IconName.calendar }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.expirationDateError }
    
    var maxNoOfChars: Int { 4 }

    var isOptional: Bool { false }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class SecurityCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .securityCode }

    var title: String { ClearentConstants.Localized.ManualEntry.csc }
    
    var placeholder: String? { ClearentConstants.Localized.ManualEntry.cscPlaceholder }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.cscError }
    
    var maxNoOfChars: Int { 4 }

    var isOptional: Bool { false }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class CardholderFirstNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .cardholderFirstName }

    var title: String { ClearentConstants.Localized.ManualEntry.cardHolderFirstName }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.cardHolderFirstNameError }
    
    var maxNoOfChars: Int { 50 }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class CardholderLastNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .cardholderLastName }

    var title: String { ClearentConstants.Localized.ManualEntry.cardHolderLastName }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.cardHolderLastNameError }
    
    var maxNoOfChars: Int { 50 }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class BillingZipCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .billingZipCode }

    var title: String { ClearentConstants.Localized.ManualEntry.billingZipCode }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.billingZipCodeError }
    
    var maxNoOfChars: Int { 9 }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class InvoiceNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .invoiceNo }

    var title: String { ClearentConstants.Localized.ManualEntry.invoiceNo }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.invoiceNoError }
    
    var maxNoOfChars: Int { 50 }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class OrderNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .orderNo }
    
    var title: String { ClearentConstants.Localized.ManualEntry.orderNo }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.orderNoError }
    
    var maxNoOfChars: Int { 50 }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class CompanyNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .companyName }

    var title: String { ClearentConstants.Localized.ManualEntry.companyName }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.companyNameError }
    
    var maxNoOfChars: Int { 50 }

    var iconName: String?

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class CustomerIDItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .customerId }

    var title: String { ClearentConstants.Localized.ManualEntry.customerID }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.customerIDError }
    
    var maxNoOfChars: Int { 50 }

    var iconName: String?

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}

class ShippingZipCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .shippingZipCode }

    var title: String { ClearentConstants.Localized.ManualEntry.shippingZipCode }
    
    var errorMessage: String? { ClearentConstants.Localized.ManualEntry.shippingZipCodeError }
    
    var maxNoOfChars: Int { 9 }

    var identifier: ItemIdentifier = nil

    var isValid: Bool = true

    var enteredValue: String = ""

    var hiddenValue: String?
}
