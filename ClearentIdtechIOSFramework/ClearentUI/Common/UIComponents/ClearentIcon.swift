//
//  ClearentIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentIcon: ClearentMarginableView {
    @IBOutlet var imageView: UIImageView!

    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 26, relatedViewType: ClearentTitleLabel.self),
            RelativeBottomMargin(constant: 26, relatedViewType: ClearentSubtitleLabel.self)
        ]
    }

    var iconName: String? {
        didSet {
            guard let iconName = iconName else { return }
            imageView.image = UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil)
        }
    }
}
