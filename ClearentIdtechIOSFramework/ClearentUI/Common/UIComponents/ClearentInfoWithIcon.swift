//
//  ClearentInfoWithIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentInfoWithIcon: ClearentMarginableView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var secondaryButton: UIButton!

    @IBOutlet var separatorView: UIView!
    public var editButtonPressed: (() -> Void)?
    public var deleteButtonPressed: (() -> Void)?

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

    public var iconName: String? {
        didSet {
            guard let iconName = iconName else { return }
            button.setBackgroundImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
            button.setTitle(nil, for: .normal)
        }
    }

    public var secondIconName: String? {
        didSet {
            guard let iconName = secondIconName else { return }
            secondaryButton.setBackgroundImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
            secondaryButton.setTitle(nil, for: .normal)
        }
    }

    override public func configure() {
        titleFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemTitleFont
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentUIBrandConfigurator.shared.fonts.detailScreenItemSubtitleFont
        descriptionTextColor = ClearentConstants.Color.base01
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary02
    }

    @IBAction func buttonAction(_: Any) {
        editButtonPressed?()
    }

    @IBAction func secondaryButtonAction(_: Any) {
        deleteButtonPressed?()
    }
}
