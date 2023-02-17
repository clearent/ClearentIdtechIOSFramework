//
//  ClearentServiceFeeView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 02.12.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentServiceFeeView: ClearentMarginableView {

    // MARK: - IBOutlets
    
    @IBOutlet weak var stackView: ClearentAdaptiveStackView!
    @IBOutlet weak var basePriceTitle: ClearentSubtitleLabel!
    @IBOutlet weak var basePriceAmount: ClearentTitleLabel!
    @IBOutlet weak var adjustedPriceTitle: ClearentSubtitleLabel!
    @IBOutlet weak var adjustedPriceAmount: ClearentTitleLabel!
    @IBOutlet weak var descriptionLabel: ClearentSubtitleLabel!
    
    // MARK: - Init
    
    convenience init(serviceFeeType: ServiceFeeProgramType, amountWithTip: String, amountWithTipAndServiceFee: String) {
        self.init()
        setupTitles(for: serviceFeeType, amountWithTip: amountWithTip, amountWithTipAndServiceFee: amountWithTipAndServiceFee)
        if serviceFeeType.description == nil {
            descriptionLabel.isHidden = true
        }
    }
    
    // MARK: - Internal
    
    override func configure() {
        basePriceAmount.font = ClearentUIBrandConfigurator.shared.fonts.screenTitleFont
        adjustedPriceAmount.font = ClearentUIBrandConfigurator.shared.fonts.screenTitleFont
    }
    
    // MARK: - Private
    
    private func setupTitles(for serviceFeeType: ServiceFeeProgramType, amountWithTip: String, amountWithTipAndServiceFee: String) {
        basePriceTitle.title = serviceFeeType.basePriceTitle
        basePriceAmount.title = amountWithTip
        adjustedPriceTitle.title = serviceFeeType.adjustedPriceTitle
        adjustedPriceAmount.title = amountWithTipAndServiceFee
        descriptionLabel.title = serviceFeeType.description
    }
}
