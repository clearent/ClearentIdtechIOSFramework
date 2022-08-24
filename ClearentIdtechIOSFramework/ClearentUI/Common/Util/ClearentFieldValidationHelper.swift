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
        case .cardholderFirstName, .cardholderLastName:
            return isCardholderNameValid(item: item)
        case .billingZipCode, .shippingZipCode:
            return isZipValid(item: item)
        case .invoiceNo, .orderNo, .companyName, .customerId:
            return hasValidLength(item: item)
        }
    }

    static func isCardNumberValid(item: ClearentPaymentItem) -> Bool {
        let cardNumberWithoutSpaces = item.enteredValue.replacingOccurrences(of: item.type.separator, with: "")
        let luhnCheckPassed = luhnCheck(cardNumberWithoutSpaces)
        let regex = "\\d{15,\(item.maxNoOfChars)}"
        return luhnCheckPassed && evaluate(text: cardNumberWithoutSpaces, regex: regex)
    }

    static func isExpirationDateValid(item: ClearentPaymentItem) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM\(item.type.separator)yy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = dateFormatter.date(from: item.enteredValue),
            let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: date) else { return false }
        return !(endOfMonth < Date())
    }

    static func isSecurityCodeValid(item: ClearentPaymentItem) -> Bool {
        let regex = "\\d{3,\(item.maxNoOfChars)}"
        return evaluate(text: item.enteredValue, regex: regex)
    }

    static func isCardholderNameValid(item: ClearentPaymentItem) -> Bool {
        let regex = "[A-Za-z\\s]{0,\(item.maxNoOfChars)}"
        return evaluate(text: item.enteredValue, regex: regex)
    }

    static func isZipValid(item: ClearentPaymentItem) -> Bool {
        let zipWithoutHyphen = item.enteredValue.replacingOccurrences(of: item.type.separator, with: "")
        let regex = "\\d{5}|\\d{\(item.maxNoOfChars)}"
        return evaluate(text: zipWithoutHyphen, regex: regex) || item.enteredValue.isEmpty
    }

    static func hasValidLength(item: ClearentPaymentItem) -> Bool {
        let regex = ".{0,\(item.maxNoOfChars)}"
        return evaluate(text: item.enteredValue, regex: regex)
    }

    /**
     If the value is valid, it is masked by replacing all digits except the last 4 with '*'
     */
    static func hideCardNumber(text: String, sender: UITextField, item: ClearentPaymentItem) {
        var item = item
        guard let regex = try? NSRegularExpression(pattern: "\\d(?=\\d{4})", options: .caseInsensitive), item.isValid else {
            item.hiddenValue = nil
            return
        }
        let textWithoutSpaces = text.replacingOccurrences(of: " ", with: "")
        let hiddenText = regex.stringByReplacingMatches(in: textWithoutSpaces,
                                                        options: .reportProgress,
                                                        range: NSMakeRange(0, textWithoutSpaces.count),
                                                        withTemplate: "*")
        sender.text = formattedCardData(text: hiddenText, item: item)

        item.hiddenValue = (sender.text?.isEmpty ?? false) ? nil : sender.text
    }

    /**
     If the value is valid, it is masked by replacing all digits with '*'
     */
    static func hideSecurityCode(text: String, sender: UITextField, item: ClearentPaymentItem) {
        var item = item
        guard let regex = try? NSRegularExpression(pattern: "\\d", options: .caseInsensitive), item.isValid else {
            item.hiddenValue = nil
            return
        }
        let formattedText = regex.stringByReplacingMatches(in: text,
                                                           options: .reportProgress,
                                                           range: NSMakeRange(0, text.count),
                                                           withTemplate: "*")
        sender.text = formattedText
        item.hiddenValue = formattedText.isEmpty ? nil : formattedText
    }

    /**
     Inserts a separator (empty space) every 4 digits and force a max number of entered digits
     */
    static func formattedCardData(text: String, item: ClearentPaymentItem) -> String {
        let separator = item.type.separator
        let textWithoutSpaces = text.replacingOccurrences(of: separator, with: "")
        let maxText = String(textWithoutSpaces.prefix(item.maxNoOfChars))
        let pattern = item.type == .creditCardNo ? ".{4}(?!$)" : ".{5}(?!$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let formattedText = regex?.stringByReplacingMatches(in: maxText,
                                                            options: .reportProgress,
                                                            range: NSMakeRange(0, maxText.count),
                                                            withTemplate: "$0\(separator)")
        return formattedText ?? text
    }

    /**
     Inserts a separator ('/') after 2 digits
     */
    static func formattedExpirationDate(text: String, item: ClearentPaymentItem) -> String {
        let separator = item.type.separator
        let separatorChar = Character(separator)
        var date = text.replacingOccurrences(of: separator, with: "")

        if date.count >= 2, previousText.last != separatorChar {
            date.insert(separatorChar, at: text.index(text.startIndex, offsetBy: 2))
        }
        previousText = text
        return String(date.prefix(item.maxNoOfChars + separator.count))
    }

    // MARK: - Private

    /**
     This function uses Luhn algorithm to validate credit card by check digit.
     From the rightmost digit, which is the check digit, moving left, double the value of every second digit;
     if the product of this doubling operation is greater than 9 (e.g., 8 x 2 = 16), then
     sum the digits of the product (e.g., 16: 1 + 6 = 7, 18: 1 + 8 = 9).
     or simply subtract 9 from the product (e.g., 16: 16 - 9 = 7, 18: 18 - 9 = 9).
     Take the sum of all the digits.
     If the total modulo 10 is equal to 0 (if the total ends in zero) then the number is valid according to the Luhn formula; else it is not valid.
     */
    private static func luhnCheck(_ number: String) -> Bool {
        let reversedString = String(number.reversed())
        var temp = 0, total = 0
        for index in 0 ..< reversedString.count {
            if let digit = Int(reversedString[index]) {
                let pos = index + 1
                if pos % 2 == 0 {
                    temp = digit * 2
                    total += temp > 9 ? temp - 9 : temp
                } else {
                    total += digit
                }
            }
        }
        return total % 10 == 0
    }

    private static func evaluate(text: String, regex: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: text)
    }
}
