//
//  MoneyFormatter.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 23.03.2022.
//

import Foundation

public struct ClearentMoneyFormatter {
    private static let localeCurrency = "en_US"

    fileprivate static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: localeCurrency)
        return formatter
    }
    
    public static func formattedText(from double: Double) -> String {
        return numberFormatter.string(for: double) ?? ""
    }

    public static func formattedText(from string: String) -> String {
        return numberFormatter.string(for: string.double) ?? ""
    }
}

private extension StringProtocol where Self: RangeReplaceableCollection {
    var digits: Self { filter { $0.isWholeNumber } }
}

public extension String {
    var double: Double {
        let digits = Double(digits) ?? 0
        let divisor = pow(10, ClearentMoneyFormatter.numberFormatter.maximumFractionDigits)
        let amount = digits / NSDecimalNumber(decimal: divisor).doubleValue
        return amount
    }
}

extension Double {
    var stringFormattedWithTwoDecimals: String? { String(ClearentMoneyFormatter.formattedText(from: self).double) }
}
