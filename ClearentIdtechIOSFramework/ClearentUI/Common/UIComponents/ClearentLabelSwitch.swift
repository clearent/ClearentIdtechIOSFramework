//
//  ClearentSwitchWithSeparator.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentLabelSwitch: ClearentInfoWithIcon {
    @IBOutlet weak var switchView: UISwitch!
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 8, relatedViewType: ClearentLabelWithIcon.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentInfoWithIcon.self)
        ]
    }
    
    var isOn: Bool {
        get {
            switchView.isOn
        }
        set {
            switchView.isOn = newValue
        }
    }

    override func configure() {
        titleFont = ClearentConstants.Font.regularMedium
        titleTextColor = ClearentConstants.Color.base02
        descriptionFont =  ClearentConstants.Font.regularSmall
        descriptionTextColor = ClearentConstants.Color.base02
        separatorView.backgroundColor = ClearentConstants.Color.backgroundSecondary04
    }

}


