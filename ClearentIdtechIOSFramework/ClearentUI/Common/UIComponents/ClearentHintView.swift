//
//  ClearentHintView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentHintView: ClearentMarginableView {
    
    // MARK: - Outlets
    
    @IBOutlet weak var label: PaddingLabel!
    @IBOutlet weak var bubbleTail: UIImageView!
    @IBOutlet weak var stackView: UIStackView!

    // MARK: - Properties
    
    override public var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 40, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 29, relatedViewType: ClearentLoadingView.self),
            RelativeBottomMargin(constant: 64, relatedViewType: ClearentSubtitleLabel.self),
            RelativeBottomMargin(constant: 45, relatedViewType: ClearentPairingReadersList.self)
        ]
    }
    
    public var title: String? {
        didSet {
            label.text = title
        }
    }
    
    public var highlightedTextColor = ClearentConstants.Color.backgroundSecondary01 {
        didSet {
            label.textColor = highlightedTextColor
        }
    }

    public var defaultTextColor = ClearentConstants.Color.base03 {
        didSet {
            label.textColor = defaultTextColor
        }
    }
    
    public var highlightedBackgroundColor = ClearentConstants.Color.accent03 {
        didSet {
            updateAppearance()
        }
    }
    
    public var textFont: UIFont? {
        didSet {
            label.font = textFont
        }
    }
    
    public var isHighlighted: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    public var bubbleTailIsOnTop: Bool = false {
        didSet {
            bubbleTail.transform = bubbleTail.transform.rotated(by: .pi)
            bubbleTail.removeFromSuperview()
            stackView.insertArrangedSubview(bubbleTail, at: 0)
        }
    }
    
    convenience init(text: String?) {
        self.init()
        label.text = text
    }

    override func configure() {
        super.configure()
        updateAppearance()
        backgroundColor = .clear
        setupBubbleTail()
        setupLabel()
    }
    
    // MARK: - Private
    
    private func setupLabel() {
        textFont = ClearentConstants.Font.proTextNormal
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.clipsToBounds = true
    }
    
    private func setupBubbleTail() {
        if isHighlighted {
            bubbleTail.image = UIImage(named: ClearentConstants.IconName.bubbleTail, in: ClearentConstants.bundle, with: nil)
        }
    }
    
    private func updateAppearance() {
        label.backgroundColor = isHighlighted ? highlightedBackgroundColor : .clear
        label.textColor = isHighlighted ? highlightedTextColor : defaultTextColor
        label.textEdgeInsets = isHighlighted ? UIEdgeInsets.init(top: 8, left: 12, bottom: 8, right: 12) : .zero
        bubbleTail.tintColor = highlightedBackgroundColor
        bubbleTail.isHidden = !isHighlighted
    }
}

class PaddingLabel: UILabel {
    var textEdgeInsets: UIEdgeInsets = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textEdgeInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textEdgeInsets.top, left: -textEdgeInsets.left, bottom: -textEdgeInsets.bottom, right: -textEdgeInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textEdgeInsets))
    }
}
