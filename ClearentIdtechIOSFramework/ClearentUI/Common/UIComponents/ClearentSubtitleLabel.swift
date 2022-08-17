//
//  ClearentSubtitleLabel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class ClearentSubtitleLabel: ClearentTitleLabel {
    public override var nibName: String? {
        String(describing: ClearentTitleLabel.self)
    }

    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentIcon.self),
            BottomMargin(constant: 80)
        ]
    }

    public override func configure() {
        label.textAlignment = .center
        font = ClearentUIBrandConfigurator.shared.fonts.modalSubtitleFont
        textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
}
