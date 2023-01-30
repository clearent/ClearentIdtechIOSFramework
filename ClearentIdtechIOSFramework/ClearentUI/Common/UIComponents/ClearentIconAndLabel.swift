//
//  ClearentIconAndLabel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 09.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentIconAndLabel: ClearentMarginableView {
    
    // MARK: - IBOutlets

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    // MARK: - Properties
    
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
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentTitleLabel.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentServiceFeeView.self)
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
    
    public var action: (() -> Void)?
    
    // MARK: - Init
    
    convenience init(icon: UIImage?, text: String) {
        self.init()
        
        if let image = icon {
            self.iconImageView.image = image
        }
        textLabel.text = text
    }
    
    // MARK: - Public
    
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
    
    // MARK: - Private
    
    @IBAction func didTapOnView(_ sender: Any) {
        action?()
    }
}
