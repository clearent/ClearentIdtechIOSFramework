//
//  AmountInfo.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

struct AmountInfo {
    typealias TipOption = (percentageTextAndValue: String, value: Double, isCustom: Bool)

    var amountWithoutTip: Double
    var availableTipPercentages: [Int]

    var tipOptions: [TipOption] {
        var tips: [TipOption] = availableTipPercentages.map {
            let value = Double($0) / 100.0 * amountWithoutTip
            return
            (percentageTextAndValue: String(format: ClearentConstants.Localized.Tips.percentageAndValueFormat, $0, ClearentMoneyFormatter.formattedWithSymbol(from: value)),
                 value: value,
                 isCustom: false)
        }
        let customTip: TipOption = (percentageTextAndValue: ClearentConstants.Localized.Tips.customAmount, value: 0, isCustom: true)
        tips.append(customTip)
        return tips
    }

    var selectedTipValue: Double?
    var finalAmount: Double {
        if let selectedTipValue = selectedTipValue { return amountWithoutTip + selectedTipValue }
        return amountWithoutTip
    }
}
