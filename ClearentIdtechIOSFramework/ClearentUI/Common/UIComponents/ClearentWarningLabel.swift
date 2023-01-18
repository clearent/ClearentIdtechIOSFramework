//
//  ClearentWarningLabel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 09.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation


class ClearentWarningLabel: ClearentTitleLabel {
    public override var nibName: String? {
        String(describing: ClearentTitleLabel.self)
    }

    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentReadersTableView.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentListView.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentLoadingView.self),
            BottomMargin(constant: 80)
        ]
    }

    public override func configure() {
        label.textAlignment = .center
        font = ClearentUIBrandConfigurator.shared.fonts.statusLabelFont
        textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleWarningLabelColor
    }
}
