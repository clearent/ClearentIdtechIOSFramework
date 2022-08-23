//
//  ClearentLabelWithIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentLabelWithIcon: ClearentTitleLabel {
    @IBOutlet var icon: UIImageView!

    var iconName: String? {
        didSet {
            guard let iconName = iconName else { return }
            icon.image = UIImage(named: iconName, in: ClearentConstants.bundle, with: nil)
        }
    }
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 14, relatedViewType: ClearentLabelWithIcon.self),
            RelativeBottomMargin(constant: 30, relatedViewType: ClearentLabelSwitch.self)
        ]
    }

    override func configure() {
        font = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemDescriptionFont
        textColor = ClearentConstants.Color.base02
    }
}
