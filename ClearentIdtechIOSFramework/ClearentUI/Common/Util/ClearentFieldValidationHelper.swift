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
        guard let type = field?.type else { return false }
        guard let data = data else { return false }
        
        switch type {
        case .creditCardNo:
            return isCardNumberValid(data)
        case .date:
            return isExpirationDateValid(data)
        case .securityCode:
            return isSecurityCodeValid(data)
        default:
            return true
        }
    }
    
    static func isCardNumberValid(_ cardNumber: String) -> Bool {
        let cardNumberWithoutWhiteSpaces = cardNumber.replacingOccurrences(of: " ", with: "")
        guard cardNumberWithoutWhiteSpaces.count >= 15 && cardNumberWithoutWhiteSpaces.count <= 19 else { return false }
        
        return true
    }
    
    static func isExpirationDateValid(_ expirationDate: String) -> Bool {
        guard !expirationDate.isEmpty else { return false }
        
        return true
    }
    
    static func isSecurityCodeValid(_ securityCode: String) -> Bool {
        guard securityCode.count == 3 || securityCode.count == 4 else { return false }
        
        return true
    }
}
