//
//  ClearentTitleLabel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

@IBDesignable
public class ClearentTitleLabel: ClearentMarginableView {
    // MARK: - Properties

    @IBOutlet var label: UILabel!

    override public var margins: [BottomMargin] {
        [RelativeBottomMargin(constant: 16, relatedViewType: ClearentSubtitleLabel.self)]
    }

    var textColor: UIColor? {
        didSet {
            label.textColor = textColor
        }
    }

    public var font: UIFont? {
        didSet {
            label.font = font
        }
    }

    convenience init(text: String?) {
        self.init()
        label.text = text
    }

    override func configure() {
        label.textAlignment = .center
        font = ClearentConstants.Font.boldNormal
        textColor = ClearentConstants.Color.base01
    }
}
