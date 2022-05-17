//
//  ClearentInfoWithIcon.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentInfoWithIcon: ClearentMarginableView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var separatorView: UIView!
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentInfoWithIcon.self)
        ]
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
    
    override func configure() {
        titleFont = ClearentConstants.Font.regularMedium
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentConstants.Font.regularMedium
        descriptionTextColor = ClearentConstants.Color.base01
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary04
    }
}
