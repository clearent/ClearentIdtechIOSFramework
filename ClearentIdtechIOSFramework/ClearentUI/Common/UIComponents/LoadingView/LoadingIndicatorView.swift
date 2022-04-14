//
//  LoginIndicatorView.swift
//  LoadingIndicator
//
//  Created by Ovidiu Pop on 14.04.2022.
//

import Foundation
import UIKit

class LoadingIndicatorView: UIView {

    var color: UIColor = .black
    var lineWidth: CGFloat = 4.0
    private lazy var shapeLayer: ProgressShapeLayer = {
        return ProgressShapeLayer(strokeColor: color, lineWidth: lineWidth)
    }()
    
    // MARK: Init
    
    init(frame: CGRect, color: UIColor, lineWidth: CGFloat) {
        self.color = color
        self.lineWidth = lineWidth
        super.init(frame: frame)
        
        self.backgroundColor = .clear
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        animateStroke()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.frame.width / 2
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
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
        
        self.layer.addSublayer(shapeLayer)
    }
}
