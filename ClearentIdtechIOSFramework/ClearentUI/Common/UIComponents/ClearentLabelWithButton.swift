//
//  ClearentLabelWithButton.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentLabelWithButton: ClearentMarginableView {

    // MARK: - IBOutlets
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet public weak var button: ClearentPrimaryButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 32, relatedViewType: ClearentPrimaryButton.self)
        ]
    }
    
    var descriptionColor: UIColor? {
        didSet {
            label.textColor = descriptionColor
        }
    }

    var descriptionFont: UIFont? {
        didSet {
            label.font = descriptionFont
        }
    }

    var descriptionText: String? {
        didSet {
            label.text = descriptionText
        }
    }
    
    var buttonTitle: String? {
        didSet {
            button.title = buttonTitle
        }
    }
    
    var buttonAction: (() -> Void)? {
        didSet {
            button.action = buttonAction
        }
    }
    
    // MARK: - Internal
    
    override func configure() {
        descriptionFont = ClearentUIBrandConfigurator.shared.fonts.settingsOfflineModeProcessLabel
        button.cornerRadius = button.bounds.height/2
        button.action = buttonAction
    }
}
