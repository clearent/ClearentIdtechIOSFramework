//
//  PrimaryButtonView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit


public enum ButtonStyleType {
    case bordered, filled
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

    public var filledBackgroundColor = ClearentUIBrandConfigurator.shared.colorPalette.filledBackgroundColor
    public var filledButtonTextColor = ClearentUIBrandConfigurator.shared.colorPalette.filledButtonTextColor
    
    public var filledDisabledBackgroundColor = ClearentUIBrandConfigurator.shared.colorPalette.filledDisabledBackgroundColor
    public var filledDisabledButtonTextColor = ClearentUIBrandConfigurator.shared.colorPalette.filledDisabledButtonTextColor
    
    public var borderColor: UIColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor
    public var borderedBackgroundColor = ClearentUIBrandConfigurator.shared.colorPalette.borderedBackgroundColor
    public var borderedButtonTextColor = ClearentUIBrandConfigurator.shared.colorPalette.borderedButtonTextColor

    public var buttonStyle: ButtonStyleType = .filled {
        didSet {
            switch buttonStyle {
            case .bordered:
                setBorderedButton()
            case .filled:
                setFilledButton()
            }
        }
    }
    
    public var isEnabled: Bool {
        set { button.isEnabled = newValue }
        
        get { button.isEnabled }
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

    public override func configure() {
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
    
    // MARK: - Internal
    
    internal func setFilledButton() {
        button.backgroundColor = filledBackgroundColor
        button.setTitleColor(filledButtonTextColor, for: .normal)
        button.setTitleColor(filledDisabledButtonTextColor, for: .disabled)
        button.layer.borderWidth = 0
    }
    
    internal func setDisabledButton() {
        button.backgroundColor = filledDisabledBackgroundColor
    }
    
    internal func setEnabledButton() {
        button.backgroundColor = filledBackgroundColor
    }
}
