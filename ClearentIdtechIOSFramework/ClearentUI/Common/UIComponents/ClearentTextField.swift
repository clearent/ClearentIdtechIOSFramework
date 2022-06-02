//
//  ClearentTextField.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 02.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentTextField: ClearentMarginableView {

    @IBOutlet weak var infoLabel: UILabel!
    
    override public var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16, relatedViewType: ClearentSubtitleLabel.self),
            BottomMargin(constant: 80)
        ]
    }
    
    var hintName: String? {
        didSet {
            guard let hintName = hintName else { return }
            infoLabel.text = hintName
        }
    }
    
    convenience init(inputName: String) {
        self.init()
        self.hintName = inputName
    }

    override func configure() {
       
    }
}
