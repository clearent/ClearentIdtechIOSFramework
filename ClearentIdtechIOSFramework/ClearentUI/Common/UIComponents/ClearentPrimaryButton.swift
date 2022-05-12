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

    public var enabledTextColor = ClearentConstants.Color.backgroundSecondary1 {
        didSet { updateAppearence() }
    }

    var disabledTextColor = ClearentConstants.Color.backgroundSecondary1 {
        didSet { updateAppearence() }
    }
    
    var borderColor: UIColor? {
        didSet {
            button.layer.borderColor = borderColor?.cgColor
        }
    }
    
    var borderWidth: CGFloat? {
        didSet {
            guard let width = borderWidth else { return }
            button.layer.borderWidth = width
        }
    }

    var textFont = ClearentConstants.Font.mediumSmall {
        didSet {
            button.titleLabel?.font = textFont
        }
    }
    
    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    var isEnabled: Bool {
        set {
            button.isEnabled = newValue
            updateAppearence()
        }
        get { button.isEnabled }
    }

    convenience init(title: String) {
        self.init()
        button.setTitle(title, for: .normal)
    }

    override func configure() {
        updateAppearence()
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.masksToBounds = true
        textFont = ClearentConstants.Font.mediumSmall
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
