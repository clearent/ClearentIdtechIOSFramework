//
//  ClearentReaderPairingButton.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentPairingReaderItem: ClearentMarginableView {
    // MARK: - Properties

    public var action: (() -> Void)?
    @IBOutlet var container: UIView!
    @IBOutlet var label: UILabel!
    @IBOutlet var rightIcon: UIImageView!

    override var margins: [BottomMargin] {
        [RelativeBottomMargin(constant: 8, relatedViewType: ClearentPairingReaderItem.self)]
    }

    var containerBackgroundColor: UIColor? {
        didSet {
            container.backgroundColor = containerBackgroundColor
        }
    }

    var textColor: UIColor? {
        didSet {
            label.textColor = textColor
        }
    }

    var textFont: UIFont? {
        didSet {
            label.font = textFont
        }
    }

    var rightIconName: String? {
        didSet {
            guard let rightIconName = rightIconName else { return }
            rightIcon.image = UIImage(named: rightIconName, in: ClearentConstants.bundle, compatibleWith: nil)
        }
    }

    // MARK: - Methods

    convenience init(title: String, action: (() -> Void)?) {
        self.init()
        label.text = title
        self.action = action
    }

    override func configure() {
        container.layer.cornerRadius = container.bounds.height / 4
        container.layer.masksToBounds = true
        textColor = ClearentConstants.Color.base01
        textFont = ClearentUIBrandConfigurator.shared.fonts.listItemTextFont
        containerBackgroundColor = ClearentConstants.Color.backgroundSecondary03
        rightIconName = ClearentConstants.IconName.rightArrow
    }

    @IBAction func viewWasPressed(_: Any) {
        action?()
    }
}
