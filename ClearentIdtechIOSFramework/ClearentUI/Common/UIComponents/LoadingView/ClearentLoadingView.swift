//
//  LoginIndicatorView.swift
//  LoadingIndicator
//
//  Created by Ovidiu Pop on 14.04.2022.
//

import Foundation
import UIKit

class ClearentLoadingView: ClearentMarginableView {
    // MARK: Properties
    
    @IBOutlet var containerView: UIView!
    private var color: UIColor = ClearentUIBrandConfigurator.shared.colorPalette.loadingViewFillColor
    private var lineWidth: CGFloat = 4.0
    private lazy var shapeLayer: ProgressShapeLayer = .init(strokeColor: color, lineWidth: lineWidth)

    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 29, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 165, relatedViewType: ClearentPrimaryButton.self),
            RelativeBottomMargin(constant: 65, relatedViewType: ClearentSubtitleLabel.self),
            RelativeBottomMargin(constant: 29, relatedViewType: ClearentListView.self),
            RelativeBottomMargin(constant: 27, relatedViewType: ClearentReadersTableView.self),
            BottomMargin(constant: 104)
        ]
    }

    // MARK: Lifecycle

    convenience init(color: UIColor, lineWidth: CGFloat) {
        self.init()
        self.color = color
        self.lineWidth = lineWidth
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        animateStroke()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.layer.cornerRadius = containerView.frame.width / 2
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: containerView.bounds.width - lineWidth, height: containerView.bounds.height - lineWidth))
        shapeLayer.path = path.cgPath
    }

    // MARK: Public

    func animateStroke() {
        let startAnimation = StrokeAnimation(type: .start, beginTime: 0.25, fromValue: 0.0, toValue: 1.0, duration: 0.75)
        let endAnimation = StrokeAnimation(type: .end, fromValue: 0.0, toValue: 1.0, duration: 0.75)

        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = 1
        strokeAnimationGroup.repeatDuration = .infinity
        strokeAnimationGroup.animations = [startAnimation, endAnimation]
        shapeLayer.add(strokeAnimationGroup, forKey: nil)
        containerView.layer.addSublayer(shapeLayer)
    }
}
