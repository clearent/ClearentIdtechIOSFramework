//
//  PrimaryButtonView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentPrimaryButton: ClearentMarginableView {
    
    // MARK: - Properties

    public var action: (() -> Void)?

    @IBOutlet var button: UIButton!

    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 12, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 16)
        ]
    }

    public var enabledBackgroundColor = ClearentConstants.Color.accent01 {
        didSet { updateAppearence() }
    }

    public var disabledBackgroundColor = ClearentConstants.Color.base01 {
        didSet { updateAppearence() }
    }

    public var enabledTextColor = ClearentConstants.Color.backgroundSecondary01 {
        didSet { updateAppearence() }
    }

    public var disabledTextColor = ClearentConstants.Color.backgroundSecondary01 {
        didSet { updateAppearence() }
    }

    public var isBorderedButton: Bool = false {
        didSet {
            let color = ClearentConstants.Color.self
            enabledBackgroundColor = isBorderedButton ? color.backgroundSecondary01 : color.base01
            enabledTextColor = isBorderedButton ? color.base01 : color.backgroundSecondary01
            borderColor = color.backgroundSecondary02
            borderWidth = isBorderedButton ? ClearentConstants.Size.defaultButtonBorderWidth : 0
        }
    }
    
    public var isTransparentButton: Bool = false {
        didSet {
            if isTransparentButton {
                enabledBackgroundColor = ClearentConstants.Color.backgroundSecondary01
                enabledTextColor = ClearentConstants.Color.base01
                borderWidth = 0
            }
        }
    }
    
    var type: FlowButtonType?
    
    var borderColor: UIColor? {
        didSet {
            button.layer.borderColor = borderColor?.cgColor
        }
    }

    var textFont = ClearentConstants.Font.proTextNormal {
        didSet {
            button.titleLabel?.font = textFont
        }
    }
    
    var borderWidth: CGFloat? {
        didSet {
            guard let borderWidth = borderWidth else { return }
            button.layer.borderWidth = borderWidth
        }
    }
    
    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    public var isEnabled: Bool {
        set {
            button.isEnabled = newValue
            updateAppearence()
        }
        get { button.isEnabled }
    }

    override func configure() {
        updateAppearence()
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.masksToBounds = true
        textFont = ClearentConstants.Font.proTextNormal
    }

    @IBAction func buttonWasPressed(_: Any) {
        action?()
    }

    // MARK: - Private

    private func updateAppearence() {
        button.backgroundColor = isEnabled ? enabledBackgroundColor : disabledBackgroundColor
        let textColor = isEnabled ? enabledTextColor : disabledTextColor
        button.setTitleColor(textColor, for: .normal)
    }
}
