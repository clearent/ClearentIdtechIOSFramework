//
//  AmountInfo.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

struct AmountInfo {
    var amountWithoutTip: Double
    var availableTipPercentages: [Double]
    
    var tipOptions: [(percentageText: String, value: Double, isCustom: Bool)] {
        var tips = availableTipPercentages.map {(
             percentageText: "\($0)%",
             value: $0 / 100 * amountWithoutTip,
             isCustom: false
        )}
        let customTip = (percentageText: "xsdk_tips_custom_amount".localized, value: ClearentConstants.Tips.defaultCustomTipValue, isCustom: true)
        tips.append(customTip)
        return tips
    }
    var selectedTipValue: Double?
    var finalAmount: Double {
        if let selectedTipValue = selectedTipValue {  return amountWithoutTip + selectedTipValue }
        return amountWithoutTip
    }
}
