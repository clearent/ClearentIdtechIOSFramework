//
//  ClearentInfoWithIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

open class ClearentInfoWithIcon: ClearentMarginableView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var primaryButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var separatorView: UIView!
    
    public var primaryButtonPressed: (() -> Void)?
    public var deleteButtonPressed: (() -> Void)?
    public var containerWasPressed: (() -> Void)?

    override public var margins: [BottomMargin] {
        [RelativeBottomMargin(constant: 24, relatedViewType: ClearentInfoWithIcon.self)]
    }

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
    
    public var warningTextColor: UIColor? {
        didSet {
            warningLabel.textColor = warningTextColor
        }
    }

    public var warningFont: UIFont? {
        didSet {
            warningLabel.font = warningFont
        }
    }

     public var warningText: String? {
        didSet {
            guard let warningText = warningText else { return }
            warningLabel.text = warningText
        }
    }

    public var iconName: String? {
        didSet {
            guard let iconName = iconName else { return }
            primaryButton.setImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
            primaryButton.setTitle(nil, for: .normal)
        }
    }

    public var secondIconName: String? {
        didSet {
            guard let iconName = secondIconName else { return }
            deleteButton.setBackgroundImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
            deleteButton.setTitle(nil, for: .normal)
        }
    }
    
    public var shouldHideWarning: Bool = true {
        didSet {
            warningLabel.isHidden = shouldHideWarning
        }
    }
    
    override open func configure() {
        titleFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemTitleFont
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemSubtitleFont
        descriptionTextColor = ClearentConstants.Color.base01
        warningTextColor = ClearentConstants.Color.warning
        shouldHideWarning = true
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary02
    }

    @IBAction func buttonAction(_: Any) {
        primaryButtonPressed?()
    }

    @IBAction func secondaryButtonAction(_: Any) {
        deleteButtonPressed?()
    }
    
    @IBAction func containerWasPressed(_: Any) {
        containerWasPressed?()
    }
}
