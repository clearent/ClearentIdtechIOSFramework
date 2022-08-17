//
//  MoneyFormatter.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 23.03.2022.
//

import Foundation

public struct ClearentMoneyFormatter {
    private static let localeCurrency = "en_US"

    fileprivate static var numberFormatterWithSymbol: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: localeCurrency)
        return formatter
    }

    fileprivate static var numberFormatterWithoutSymbol: NumberFormatter {
        let formatter = ClearentMoneyFormatter.numberFormatterWithSymbol
        formatter.currencySymbol = ""
        return formatter
    }

    public static func formattedWithSymbol(from double: Double) -> String {
        numberFormatterWithSymbol.string(for: double) ?? ""
    }

    public static func formattedWithoutSymbol(from double: Double) -> String {
        numberFormatterWithoutSymbol.string(for: double) ?? ""
    }

    public static func formattedWithSymbol(from string: String) -> String {
        numberFormatterWithSymbol.string(for: string.double) ?? ""
    }
}

private extension StringProtocol where Self: RangeReplaceableCollection {
    var digits: Self { filter { $0.isWholeNumber } }
}

public extension String {
    var double: Double {
        let digits = Double(digits) ?? 0
        let divisor = pow(10, ClearentMoneyFormatter.numberFormatterWithoutSymbol.maximumFractionDigits)
        let amount = digits / NSDecimalNumber(decimal: divisor).doubleValue
        return amount
    }
}

extension Double {
    var stringFormattedWithTwoDecimals: String? { String(ClearentMoneyFormatter.formattedWithoutSymbol(from: self).double) }
}
