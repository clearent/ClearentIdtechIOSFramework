//
//  ClearentManualEntryFieldValidation.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

class ClearentFieldValidationHelper {
    private static var previousText: String = ""
    
    static func validateCardData(item: ClearentPaymentItem?) -> Bool {
        guard let item = item else { return false }

        switch item.type {
        case .creditCardNo:
            return isCardNumberValid(item: item)
        case .date:
            return isExpirationDateValid(item: item)
        case .securityCode:
            return isSecurityCodeValid(item: item)
        case .cardholderName:
            return isCardholderNameValid(item: item)
        case .billingZipCode, .shippingZipCode:
            return isZipValid(item: item)
        case .invoiceNo, .orderNo, .companyName, .customerId:
            return hasAnyCharacherMaxLength(item: item)
        }
    }
    
    static func isCardNumberValid(item: ClearentPaymentItem) -> Bool {
        let cardNumberWithoutSpaces = item.enteredValue.replacingOccurrences(of: " ", with: "")
        let regex = "^[\\d]{15,\(item.maxNoOfChars)}"
        
        return ClearentFieldValidationHelper.evaluate(text: cardNumberWithoutSpaces, regex: regex)
    }
    
    static func isExpirationDateValid(item: ClearentPaymentItem) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM\(item.separator ?? "")yy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = dateFormatter.date(from: item.enteredValue),
              let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: date) else { return false }
        return !(endOfMonth < Date())
    }
    
    static func isSecurityCodeValid(item: ClearentPaymentItem) -> Bool {
        let regex = "^[\\d]{3,\(item.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: item.enteredValue, regex: regex)
    }
    
    static func isCardholderNameValid(item: ClearentPaymentItem) -> Bool {
        let regex = "^[A-Za-z\\s]{0,\(item.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: item.enteredValue, regex: regex)
    }
    
    static func isZipValid(item: ClearentPaymentItem) -> Bool {
        let regex = "^[A-Za-z\\d\\-]{5,\(item.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: item.enteredValue, regex: regex) || item.enteredValue.isEmpty
    }
    
    static func hasAnyCharacherMaxLength(item: ClearentPaymentItem) -> Bool {
        let regex = "^.{0,\(item.maxNoOfChars)}"
        return ClearentFieldValidationHelper.evaluate(text: item.enteredValue, regex: regex)
    }
    
    static func hideCardNumber(text: String, sender: UITextField, item: ClearentPaymentItem) {
        guard let regex = try? NSRegularExpression(pattern: "(\\d)(?=\\d{4})", options: .caseInsensitive), item.isValid else { return }
        let textWithoutSpaces = text.replacingOccurrences(of: " ", with: "")
        let hiddenText = regex.stringByReplacingMatches(in: textWithoutSpaces,
                                  options: .reportProgress,
                                  range: NSMakeRange(0, textWithoutSpaces.count),
                                  withTemplate: "*")
        formatCreditCardNo(text: hiddenText, sender: sender, item: item)
        var item = item
        item.hiddenValue = sender.text ?? nil
    }
    
    
    static func hideSecurityCode(text: String, sender: UITextField, item: ClearentPaymentItem) {
        guard let regex = try? NSRegularExpression(pattern: "\\d", options: .caseInsensitive), item.isValid else { return }
        let formattedText = regex.stringByReplacingMatches(in: text,
                                  options: .reportProgress,
                                  range: NSMakeRange(0, text.count),
                                  withTemplate: "*")
        sender.text = formattedText
        var item = item
        item.hiddenValue = formattedText
    }
    
    // insert an empty space every 4 digits and force a max number of entered digits
    static func formatCreditCardNo(text: String, sender: UITextField, item: ClearentPaymentItem) {
        let separator = item.separator ?? ""
        let textWithoutSpaces = text.replacingOccurrences(of: separator, with: "")
        let maxText = String(textWithoutSpaces.prefix(item.maxNoOfChars))
        let regex = try? NSRegularExpression(pattern: "(.{4})(?!$)", options: .caseInsensitive)
        let formattedText = regex?.stringByReplacingMatches(in: maxText,
                                  options: .reportProgress,
                                  range: NSMakeRange(0, maxText.count),
                                  withTemplate: "$0\(separator)")
        sender.text = formattedText
    }
    
    // insert a separator ('/') after 2 digits
    static func formatExpirationDate(sender: UITextField, item: ClearentPaymentItem) {
        guard let text = sender.text else { return }
        let separator = item.separator ?? ""
        let separatorChar = Character(separator)
        var date = text.replacingOccurrences(of: separator, with: "")
    
        if date.count >= 2 && previousText.last != separatorChar {
            date.insert(separatorChar, at: text.index(text.startIndex, offsetBy: 2))
        }
        sender.text = String(date.prefix(item.maxNoOfChars + separator.count))
        previousText = text
    }
    
    private static func evaluate(text: String, regex: String) -> Bool {
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: text)
    }
}
