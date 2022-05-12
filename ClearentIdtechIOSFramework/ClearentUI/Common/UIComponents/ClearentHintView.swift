//
//  ClearentHintView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentHintView: ClearentTitleLabel {
    override public var nibName: String? {
        String(describing: ClearentTitleLabel.self)
    }

    override public var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 40, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 29, relatedViewType: ClearentLoadingView.self),
            RelativeBottomMargin(constant: 64, relatedViewType: ClearentSubtitleLabel.self),
            RelativeBottomMargin(constant: 45, relatedViewType: ClearentPairingReadersList.self)
        ]
    }
    
    public var containerBackgroundColor: UIColor? {
        didSet {
            label.backgroundColor = containerBackgroundColor
        }
    }

    override func configure() {
        super.configure()
        font = ClearentConstants.Font.mediumSmall
    }
}
