//
//  ClearentPaymentModel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 18.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


enum ClearentPaymentItemType {
    case creditCardNo, date, securityCode, cardholderName, billingZipCode, invoiceNo, orderNo, companyName, customerId, shippingZipCode
    
    var separator: String {
        switch self {
        case .creditCardNo:
            return " "
        case .date:
            return "/"
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
        ClearentPaymentRow(elements: [CardholderNameItem()]),
        ClearentPaymentRow(elements: [BillingZipCodeItem()])
    ]
}

class ClearentPaymentAdditionalSection: ClearentPaymentSection {
    var title: String? { "xsdk_payment_manual_entry_additional_section_title".localized }
    
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
    
    var title: String { "xsdk_payment_manual_entry_card_no".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_card_no_error".localized }
    
    var maxNoOfChars: Int { 19 }

    var isOptional: Bool { false }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class DateItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .date }
    
    var title: String { "xsdk_payment_manual_entry_exp_date".localized }
    
    var placeholder: String? { "xsdk_payment_manual_entry_exp_date_placeholder".localized }
    
    var iconName: String? { ClearentConstants.IconName.calendar }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_exp_date_error".localized }
    
    var maxNoOfChars: Int { 4 }
    
    var isOptional: Bool { false }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class SecurityCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .securityCode }
    
    var title: String { "xsdk_payment_manual_entry_csc".localized }
    
    var placeholder: String? { "xsdk_payment_manual_entry_csc_placeholder".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_csc_error".localized }
    
    var maxNoOfChars: Int { 4 }
    
    var isOptional: Bool { false }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}


class CardholderNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .cardholderName }
    
    var title: String { "xsdk_payment_manual_entry_cardholder_name".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_cardholder_name_error".localized }
    
    var maxNoOfChars: Int { 50 }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class BillingZipCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .billingZipCode }
    
    var title: String { "xsdk_payment_manual_entry_billing_zip".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_billing_zip_error".localized }
    
    var maxNoOfChars: Int { 10 }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class InvoiceNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .invoiceNo }
    
    var title: String { "xsdk_payment_manual_entry_invoice_no".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_invoice_no_error".localized }
    
    var maxNoOfChars: Int { 50 }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class OrderNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .orderNo }
    
    var title: String { "xsdk_payment_manual_entry_order_no".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_order_no_error".localized }
    
    var maxNoOfChars: Int { 50 }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class CompanyNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .companyName }
    
    var title: String { "xsdk_payment_manual_entry_company_name".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_company_name_error".localized }
    
    var maxNoOfChars: Int { 50 }
    
    var iconName: String?
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class CustomerIDItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .customerId }
    
    var title: String { "xsdk_payment_manual_entry_customer_id".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_customer_id_error".localized }
    
    var maxNoOfChars: Int { 50 }
    
    var iconName: String?
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}

class ShippingZipCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .shippingZipCode }
    
    var title: String { "xsdk_payment_manual_entry_shipping_zip".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_shipping_zip_error".localized }
    
    var maxNoOfChars: Int { 10 }
    
    var identifier: ItemIdentifier = nil
    
    var isValid: Bool = true
    
    var enteredValue: String = ""
    
    var hiddenValue: String? = nil
}
