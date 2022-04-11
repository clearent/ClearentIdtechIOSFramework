//
//  ClearentEmptySpace.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

class ClearentEmptySpace: ClearentMarginableView {
    @IBOutlet var heightConstraint: NSLayoutConstraint!

    var height = 16.0 {
        didSet {
            heightConstraint?.constant = height
            updateConstraints()
        }
    }

    // MARK: - Lifecycle

    convenience init(height: CGFloat) {
        self.init()
        setHeight(height: height)
    }

    override func configure() {
        setHeight(height: height)
    }

    // MARK: - Private

    private func setHeight(height: CGFloat) {
        self.height = height
    }
}
