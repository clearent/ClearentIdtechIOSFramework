//
//  ClearentInfoWithIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentInfoWithIcon: ClearentMarginableView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var separatorView: UIView!

    override var margins: [BottomMargin] {
        [RelativeBottomMargin(constant: 24, relatedViewType: ClearentInfoWithIcon.self)]
    }

    var titleTextColor: UIColor? {
        didSet {
            titleLabel.textColor = titleTextColor
        }
    }

    var titleFont: UIFont? {
        didSet {
            titleLabel.font = titleFont
        }
    }

    var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    var descriptionTextColor: UIColor? {
        didSet {
            descriptionLabel.textColor = descriptionTextColor
        }
    }

    var descriptionFont: UIFont? {
        didSet {
            descriptionLabel.font = descriptionFont
        }
    }

    var descriptionText: String? {
        didSet {
            guard let descriptionText = descriptionText else {
                descriptionLabel.removeFromSuperview()
                return
            }
            descriptionLabel.text = descriptionText
        }
    }

    var iconName: String? {
        didSet {
            guard let iconName = iconName else { return }
            icon.image = UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil)
        }
    }

    override func configure() {
        titleFont = ClearentConstants.Font.proTextNormal
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentConstants.Font.proTextNormal
        descriptionTextColor = ClearentConstants.Color.base01
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary04
    }
}
