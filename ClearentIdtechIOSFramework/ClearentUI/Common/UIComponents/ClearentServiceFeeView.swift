//
//  ClearentServiceFeeView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 02.12.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentServiceFeeView: ClearentMarginableView {

    @IBOutlet weak var titleLabel: ClearentTitleLabel!
    @IBOutlet weak var basePriceTitle: ClearentSubtitleLabel!
    @IBOutlet weak var basePriceAmount: ClearentTitleLabel!
    @IBOutlet weak var adjustedPriceTitle: ClearentSubtitleLabel!
    @IBOutlet weak var adjustedPriceAmount: ClearentTitleLabel!
    @IBOutlet weak var descriptionLabel: ClearentSubtitleLabel!
    
    convenience init(serviceFeeType: ServiceFeeProgramType, amountWithTip: String, amountWithTipAndServiceFee: String) {
        self.init()
        titleLabel.title = serviceFeeType.title
        basePriceTitle.title = serviceFeeType.basePriceTitle
        basePriceAmount.title = amountWithTip
        adjustedPriceTitle.title = serviceFeeType.adjustedPriceTitle
        adjustedPriceAmount.title = amountWithTipAndServiceFee
        descriptionLabel.title = serviceFeeType.description
        if serviceFeeType.description == nil {
            descriptionLabel.isHidden = true
        }
    }
    
    override func configure() {
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.screenTitleFont
        basePriceAmount.font = ClearentUIBrandConfigurator.shared.fonts.screenTitleFont
        adjustedPriceAmount.font = ClearentUIBrandConfigurator.shared.fonts.screenTitleFont
    }
}

extension ServiceFeeProgramType {
    var title: String {
        switch self {
        case .SURCHARGE:
            return "Surcharge"
        case .NON_CASH_ADJUSTMENT:
            return "Non Cash Adjustment"
        case .EMPOWER_LITE:
            return "ServiceFee Lite"
        case .SERVICE_FEE:
            return "Service fee"
        case .CONVENIENCE_FEE:
            return "Convenience fee"
        }
    }
    
    var basePriceTitle: String {
        switch self {
        case .NON_CASH_ADJUSTMENT, .SERVICE_FEE:
            return "Cash price"
        case .SURCHARGE, .EMPOWER_LITE:
            return "Cash or debit card"
        case .CONVENIENCE_FEE:
            return "Base price"
        }
    }
    
    var adjustedPriceTitle: String {
        switch self {
        case .NON_CASH_ADJUSTMENT, .SERVICE_FEE:
            return "Card payment price"
        case .SURCHARGE, .EMPOWER_LITE:
            return "Credit card price"
        case .CONVENIENCE_FEE:
            return "Total including convenience fee"
        }
    }
    
    var description: String? {
        switch self {
        case .CONVENIENCE_FEE:
            return "To avoid this fee, cancel the transaction and try other payment terms like face to face payment."
        default:
            return nil
        }
    }
}
