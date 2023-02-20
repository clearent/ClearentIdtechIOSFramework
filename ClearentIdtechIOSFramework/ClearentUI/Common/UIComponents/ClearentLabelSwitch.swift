//
//  ClearentSwitchWithSeparator.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentLabelSwitch: ClearentMarginableView {
    
    // MARK: - IBOutlets
    
    @IBOutlet var switchView: UISwitch!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    // MARK: - Properties
    
    var valueChangedAction: ((_ isOn: Bool) -> Void)?
    
    public var titleTextColor: UIColor? {
        didSet {
            titleLabel.textColor = titleTextColor
        }
    }

    public var titleFont: UIFont? {
        didSet {
            titleLabel.font = titleFont
        }
    }

    public var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    public var descriptionTextColor: UIColor? {
        didSet {
            descriptionLabel.textColor = descriptionTextColor
        }
    }

    public var descriptionFont: UIFont? {
        didSet {
            descriptionLabel.font = descriptionFont
        }
    }

    public var descriptionText: String? {
        didSet {
            guard let descriptionText = descriptionText else {
                descriptionLabel.removeFromSuperview()
                return
            }
            descriptionLabel.text = descriptionText
        }
    }

    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 8, relatedViewType: ClearentLabelWithIcon.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentInfoWithIcon.self),
            RelativeBottomMargin(constant: 26, relatedViewType: ClearentLabelSwitch.self),
            RelativeBottomMargin(constant: 14, relatedViewType: ClearentLabelWithButton.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self)
        ]
    }

    var isOn: Bool {
        get { switchView.isOn }
        set { switchView.isOn = newValue }
    }

    // MARK: - Configure
    
    override func configure() {
        super.configure()
        titleFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemTitleFont
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemSubtitleFont
        descriptionTextColor = ClearentConstants.Color.base01
        switchView.transform = CGAffineTransform(scaleX: 0.83, y: 0.77)
        descriptionFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemDescriptionFont
        descriptionTextColor = ClearentConstants.Color.base02
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary02
    }
    
    // MARK: - Actions
    
    @IBAction func switchValueDidChange(_ sender: UISwitch) {
        valueChangedAction?(sender.isOn)
    }
}
