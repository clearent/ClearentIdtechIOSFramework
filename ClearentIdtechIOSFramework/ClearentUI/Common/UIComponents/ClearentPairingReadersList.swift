//
//  ClearentPairingReadersList.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentPairingReadersList: ClearentMarginableView {
    @IBOutlet weak var stackView: ClearentAdaptiveStackView!
    
    convenience init(items: [ClearentPairingReaderItem]) {
        self.init()
        items.forEach {
            stackView.addArrangedSubview($0)
        }
    }
    
    public override var margins: [BottomMargin] {
        [RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self)]
    }
}
