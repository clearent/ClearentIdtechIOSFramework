//
//  ClearentPaymentModel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 18.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


enum ClearentPaymentItemType {
    case creditCardNo, date, securityCode, cardholderName, billingZipCode, invoiceNo, orderNo, companyName, customerId, shippingZipCode
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
    var isOptional: Bool { get }
    var identifier: ItemIdentifier { get set }
}

extension ClearentPaymentItem {
    var isOptional: Bool { true }
    var placeholder: String? { nil }
    var iconName: String? { nil }
    var errorMessage: String? { nil }
}

struct ClearentPaymentBaseSection: ClearentPaymentSection {
    var title: String? { nil }
    
    var isCollapsable: Bool { false }
    
    var isCollapsed: Bool = false

    var rows: [ClearentPaymentRow] = [
        ClearentPaymentRow(elements: [CreditCardNoItem()]),
        ClearentPaymentRow(elements: [DateItem(), SecurityCodeItem()]),
        ClearentPaymentRow(elements: [CardholderNameItem()])//,
//        ClearentPaymentRow(elements: [BillingZipCodeItem()])
    ]
}

struct ClearentPaymentAdditionalSection: ClearentPaymentSection {
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

struct CreditCardNoItem: ClearentPaymentItem {
   
    var type: ClearentPaymentItemType { .creditCardNo }
    
    var title: String { "xsdk_payment_manual_entry_card_no".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_card_no_error".localized }
    
    var isOptional: Bool { false }
    
    var identifier: ItemIdentifier = nil
}

struct DateItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .date }
    
    var title: String { "xsdk_payment_manual_entry_exp_date".localized }
    
    var placeholder: String? { "xsdk_payment_manual_entry_exp_date_placeholder".localized }
    
    var iconName: String? { ClearentConstants.IconName.calendar }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_exp_date_error".localized }
    
    var isOptional: Bool { false }
    
    var identifier: ItemIdentifier = nil
}

struct SecurityCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .securityCode }
    
    var title: String { "xsdk_payment_manual_entry_csc".localized }
    
    var placeholder: String? { "xsdk_payment_manual_entry_csc_placeholder".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_csc_error".localized }
    
    var isOptional: Bool { false }
    
    var identifier: ItemIdentifier = nil
}


struct CardholderNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .cardholderName }
    
    var title: String { "xsdk_payment_manual_entry_cardholder_name".localized }
    
    var identifier: ItemIdentifier = nil
    
}
struct BillingZipCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .billingZipCode }
    
    var title: String { "xsdk_payment_manual_entry_billing_zip".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_billing_zip_error".localized }
    
    var identifier: ItemIdentifier = nil
}

struct InvoiceNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .invoiceNo }
    
    var title: String { "xsdk_payment_manual_entry_invoice_no".localized }
    
    var identifier: ItemIdentifier = nil
}

struct OrderNoItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .orderNo }
    
    var title: String { "xsdk_payment_manual_entry_order_no".localized }
    
    var identifier: ItemIdentifier = nil
}

struct CompanyNameItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .companyName }
    
    var title: String { "xsdk_payment_manual_entry_company_name".localized }
    
    var iconName: String?
    
    var identifier: ItemIdentifier = nil
}

struct CustomerIDItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .customerId }
    
    var title: String { "xsdk_payment_manual_entry_customer_id".localized }
    
    var iconName: String?
    
    var identifier: ItemIdentifier = nil
}

struct ShippingZipCodeItem: ClearentPaymentItem {
    var type: ClearentPaymentItemType { .shippingZipCode }
    
    var title: String { "xsdk_payment_manual_entry_shipping_zip".localized }
    
    var errorMessage: String? { "xsdk_payment_manual_entry_shipping_zip_error".localized }
    
    var identifier: ItemIdentifier = nil
}
