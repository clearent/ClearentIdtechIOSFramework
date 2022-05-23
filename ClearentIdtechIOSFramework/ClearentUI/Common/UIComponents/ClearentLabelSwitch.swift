//
//  ClearentSwitchWithSeparator.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentLabelSwitch: ClearentInfoWithIcon {
    @IBOutlet var switchView: UISwitch!

    var valueChangedAction: ((_ isOn: Bool) -> Void)?

    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 8, relatedViewType: ClearentLabelWithIcon.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentInfoWithIcon.self),
            RelativeBottomMargin(constant: 26, relatedViewType: ClearentLabelSwitch.self)
        ]
    }

    var isOn: Bool {
        get { switchView.isOn }
        set { switchView.isOn = newValue }
    }

    override func configure() {
        titleFont = ClearentConstants.Font.proTextNormal
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont = ClearentConstants.Font.proTextSmall
        descriptionTextColor = ClearentConstants.Color.base02
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary04
    }

    @IBAction func switchValueDidChange(_ sender: UISwitch) {
        valueChangedAction?(sender.isOn)
    }
}
