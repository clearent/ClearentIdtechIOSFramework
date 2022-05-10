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
    
    @IBOutlet weak var button: UIButton!
    
    override public var margins: [BottomMargin] {
        [ BottomMargin(contant: 16) ]
    }

    public var enabledBackgroundColor = ClearentConstants.Color.base01 {
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

    public var textFont = ClearentConstants.Font.mediumSmall {
        didSet {
            button.titleLabel?.font = textFont
        }
    }
    
    public var borderColor = ClearentConstants.Color.backgroundSecondary01 {
        didSet {
            button.layer.borderColor = borderColor.cgColor
        }
    }

    public var isEnabled: Bool {
        set {
            button.isEnabled = newValue
            updateAppearence()
        }
        get { button.isEnabled }
    }
    
    public var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    override func configure() {
        updateAppearence()
        button.layer.borderWidth = 1
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.masksToBounds = true
        textFont = ClearentConstants.Font.medium
    }
    
    @IBAction func buttonWasPressed(_ sender: Any) {
        action?()
    }

    // MARK: - Private

    private func updateAppearence() {
        button.backgroundColor = isEnabled ? enabledBackgroundColor : disabledBackgroundColor
        let textColor = isEnabled ? enabledTextColor : disabledTextColor
        button.setTitleColor(textColor, for: .normal)
    }
}
