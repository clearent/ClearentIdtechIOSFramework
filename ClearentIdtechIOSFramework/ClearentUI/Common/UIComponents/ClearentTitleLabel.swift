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

    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16, relatedViewType: ClearentSubtitleLabel.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentListView.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 80)
        ]
    }

    public var textColor: UIColor? {
        didSet {
            label.textColor = textColor
        }
    }

    public var font: UIFont? {
        didSet {
            label.font = font
        }
    }
    
    public var title: String? {
        didSet {
            label.text = title
        }
    }

    convenience init(text: String?) {
        self.init()
        label.text = text
    }

    public override func configure() {
        label.textAlignment = .center
        font = ClearentUIBrandConfigurator.shared.fonts.modalTitleFont
        textColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
    }
}
