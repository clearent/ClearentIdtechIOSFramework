//
//  ClearentMarginableView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A ClearentXibView subclass that adds custom bottom padding to the view
class ClearentMarginableView: ClearentXibView, ClearentMarginable {

    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint?

    var viewType: UIView.Type { type(of: self) }
    var margins: [Margin] { [] }

    func setBottomMargin(margin: Margin) {
        bottomLayoutConstraint?.constant = margin.constant
    }
}
