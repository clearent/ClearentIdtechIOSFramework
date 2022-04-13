//
//  PrimaryButtonView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentPrimaryButton: ClearentMarginableView {
    // MARK: - Properties

    public var action: (() -> Void)?

    @IBOutlet weak var button: UIButton!
    
    override var margins: [BottomMargin] {
        [ BottomMargin(contant: 16) ]
    }

    var enabledBackgroundColor = ClearentConstants.Color.base01 {
        didSet { updateAppearence() }
    }

    var disabledBackgroundColor = ClearentConstants.Color.base01 {
        didSet { updateAppearence() }
    }

    var enabledTextColor = ClearentConstants.Color.backgroundSecondary01 {
        didSet { updateAppearence() }
    }

    var disabledTextColor = ClearentConstants.Color.backgroundSecondary01 {
        didSet { updateAppearence() }
    }

    var textFont = ClearentConstants.Font.regularMedium {
        didSet {
            button.titleLabel?.font = textFont
        }
    }

    var isEnabled: Bool {
        set {
            button.isEnabled = newValue
            updateAppearence()
        }
        get { button.isEnabled }
    }
    
    var title: String? {
        didSet {
            button.setTitle(title, for: .normal)
        }
    }

    override func configure() {
        updateAppearence()
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.masksToBounds = true
        textFont = ClearentConstants.Font.regularMedium
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
