//
//  ProgressShapeLayer.swift
//  LoadingIndicator
//
//  Created by Ovidiu Pop on 14.04.2022.
//

import Foundation
import UIKit

class ProgressShapeLayer: CAShapeLayer {
    
    // MARK: Init

    init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init()
        
        self.strokeColor = strokeColor.cgColor
        self.lineWidth = lineWidth
        self.fillColor = UIColor.clear.cgColor
        self.lineCap = .round
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
