//
//  ClearentMarginableView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A ClearentXibView subclass that adds custom bottom padding to the view
public class ClearentMarginableView: ClearentXibView, ClearentMarginable {
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint?

    public var viewType: UIView.Type { type(of: self) }
    public var margins: [BottomMargin] { [] }

    public func setBottomMargin(margin: BottomMargin) {
        bottomLayoutConstraint?.constant = margin.constant
    }
}
