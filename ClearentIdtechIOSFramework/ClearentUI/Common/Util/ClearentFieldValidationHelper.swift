//
//  ClearentManualEntryFieldValidation.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

class ClearentFieldValidationHelper {

    static func validateCardData(_ data: String?, field: ClearentPaymentItem?) -> Bool {
        guard let field = field else { return false }
        guard let data = data else { return false }
        
        switch field.type {
        case .creditCardNo:
            return isCardNumberValid(data, field: field)
        case .date:
            return isExpirationDateValid(data, field: field)
        case .securityCode:
            return isSecurityCodeValid(data, field: field)
        case .cardholderName:
            return isCardholderNameValid(data, field: field)
        case .billingZipCode, .shippingZipCode:
            return isZipValid(data, field: field)
        case .invoiceNo, .orderNo, .companyName, .customerId:
            return hasAnyCharacherMaxLength(data, field: field)
        }
    }
    
    static func isCardNumberValid(_ cardNumber: String, field: ClearentPaymentItem) -> Bool {
        let cardNumberWithoutSpaces = cardNumber.replacingOccurrences(of: " ", with: "")
        let regex = "^[\\d]{15,\(field.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: cardNumberWithoutSpaces, regex: regex)
    }
    
    static func isExpirationDateValid(_ expirationDate: String, field: ClearentPaymentItem) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/yy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = dateFormatter.date(from: expirationDate) else { return false }
        let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: date)!
        return !(endOfMonth < Date())
    }
    
    static func isSecurityCodeValid(_ securityCode: String, field: ClearentPaymentItem) -> Bool {
        let regex = "^[\\d]{3,\(field.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: securityCode, regex: regex) || securityCode.isEmpty
    }
    
    static func isCardholderNameValid(_ name: String, field: ClearentPaymentItem) -> Bool {
        let regex = "^[A-Za-z\\s]{0,\(field.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: name, regex: regex)
    }
    
    static func isZipValid(_ zipNo: String, field: ClearentPaymentItem) -> Bool {
        let regex = "^[A-Za-z\\d\\-]{5,\(field.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: zipNo, regex: regex) || zipNo.isEmpty
    }
    
    static func hasAnyCharacherMaxLength(_ text: String, field: ClearentPaymentItem) -> Bool {
        let regex = "^.{0,\(field.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: text, regex: regex)
    }
    
    private static func evaluate(text: String, regex: String) -> Bool {
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: text)
    }
}
