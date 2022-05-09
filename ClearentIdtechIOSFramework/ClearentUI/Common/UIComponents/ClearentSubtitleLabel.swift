//
//  ClearentSubtitleLabel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class ClearentSubtitleLabel: ClearentTitleLabel {
    override public var nibName: String? {
        String(describing: ClearentTitleLabel.self)
    }

    override public var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 80)
        ]
    }

    override func configure() {
        label.textAlignment = .center
        font = ClearentConstants.Font.mediumSmall
        textColor = ClearentConstants.Color.base02
    }
}
