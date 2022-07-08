//
//  PrimaryButtonView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit


public enum ButtonStyleType {
    case transparent, bordered, filled
}

public class ClearentPrimaryButton: ClearentMarginableView {
    
    // MARK: - Properties

    public var action: (() -> Void)?
    var type: FlowButtonType?

    @IBOutlet var button: UIButton!

    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 12, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 16)
        ]
    }

    public var filledBackgroundColor = ClearentConstants.Color.base01
    public var filledButtonTextColor = ClearentConstants.Color.backgroundSecondary01
    
    public var borderColor: UIColor = ClearentConstants.Color.backgroundSecondary02
    public var borderedBackgroundColor = ClearentConstants.Color.backgroundSecondary01
    public var borderedButtonTextColor = ClearentConstants.Color.base01
    
    public var transparentButtonTextColor = ClearentConstants.Color.base01

    public var buttonStyle: ButtonStyleType = .filled {
        didSet {
            switch buttonStyle {
            case .transparent:
                setTransparentButton()
            case .bordered:
                setBorderedButton()
            case .filled:
                setFilledButton()
            }
        }
    }

    var textFont: UIFont? {
        didSet {
            button.titleLabel?.font = textFont
        }
    }
    
    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    override func configure() {
        setFilledButton()
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.masksToBounds = true
        textFont = ClearentUIBrandConfigurator.shared.fonts.primaryButtonTextFont
    }

    @IBAction func buttonWasPressed(_: Any) {
        action?()
    }

    // MARK: - Private
    
    private func setBorderedButton() {
        button.backgroundColor = borderedBackgroundColor
        button.setTitleColor(borderedButtonTextColor, for: .normal)
        button.layer.borderColor = borderColor.cgColor
        button.layer.borderWidth = ClearentConstants.Size.defaultButtonBorderWidth
    }
    
    private func setTransparentButton() {
        button.backgroundColor = .clear
        button.setTitleColor(transparentButtonTextColor, for: .normal)
        button.layer.borderWidth = 0
    }
    
    private func setFilledButton() {
        button.backgroundColor = filledBackgroundColor
        button.setTitleColor(filledButtonTextColor, for: .normal)
        button.layer.borderWidth = 0
    }
}
