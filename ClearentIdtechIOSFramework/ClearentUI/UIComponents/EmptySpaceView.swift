//
//  SpaceView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

class EmptySpaceView: MarginableView {
    @IBOutlet var heightConstraint: NSLayoutConstraint!

    var height = 16.0 {
        didSet {
            heightConstraint?.constant = height
            updateConstraints()
        }
    }

    // MAKR: - Lifecycle

    convenience init(height: CGFloat) {
        self.init()
        setHeight(height: height)
    }

    override func configure() {
        setHeight(height: height)
    }

    func setHeight(height: CGFloat) {
        self.height = height
    }
}
