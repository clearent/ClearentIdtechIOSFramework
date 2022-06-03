//
//  ClearentLabelWithButton.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentLabelWithButton: ClearentMarginableView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var separator: UIView!
    public var editButtonPressed: (() -> Void)?
    
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
            actionButton.setBackgroundImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)

        }
    }
    
    override func configure() {
        titleFont = ClearentConstants.Font.proTextNormal
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentConstants.Font.proTextNormal
        descriptionTextColor = ClearentConstants.Color.base01
        separator.backgroundColor = ClearentConstants.Color.backgroundSecondary04
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        editButtonPressed?()
    }
}
