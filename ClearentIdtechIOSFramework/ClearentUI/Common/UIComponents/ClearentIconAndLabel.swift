//
//  ClearentIconAndLabel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 09.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentIconAndLabel: ClearentMarginableView {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    public override var nibName: String? {
        String(describing: ClearentIconAndLabel.self)
    }

    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentSignatureView.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentAnimationWithSubtitle.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentReadersTableView.self),
            RelativeBottomMargin(constant: 20, relatedViewType: ClearentListView.self),
            RelativeBottomMargin(constant: 43, relatedViewType: ClearentLoadingView.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentTitleLabel.self)
        ]
    }
    
    public var textColor: UIColor? {
        didSet {
            textLabel.textColor = textColor
        }
    }

    public var font: UIFont? {
        didSet {
            textLabel.font = font
        }
    }
    
    convenience init(icon: UIImage?, text: String) {
        self.init()
        if let image = icon {
            self.iconImageView.image = image
        }
        textLabel.text = text
    }
    
    public override func configure() {
        font = ClearentUIBrandConfigurator.shared.fonts.statusLabelFont
        textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleWarningLabelColor
    }
    
    public func update(icon: UIImage?, text: String) {
        if let image = icon {
            self.iconImageView.image = image
        }
        textLabel.text = text
    }
}
