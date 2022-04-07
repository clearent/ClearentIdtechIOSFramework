//
//  MarginableView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A  XibView subclass that adds custom bottom padding to the view
class MarginableView: XibView, Marginable {
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint?

    var viewType: UIView.Type { type(of: self) }
    var margings: [RelativeMargin] { [] }

    func setBottomMargin(margin: RelativeMargin) {
        bottomLayoutConstraint?.constant = margin.constant
    }
}
