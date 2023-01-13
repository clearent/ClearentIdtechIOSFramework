//
//  ClearentMarginableView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A ClearentXibView subclass that adds custom bottom padding to the view
open class ClearentMarginableView: ClearentXibView, ClearentMarginable {
    
    // MARK: - IBOutlets
    
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint?

    // MARK: - Properties
    
    public var viewType: UIView.Type { type(of: self) }
    public var margins: [BottomMargin] { [] }

    // MARK: - Public
    
    public func setBottomMargin(margin: BottomMargin) {
        bottomLayoutConstraint?.constant = margin.constant
    }
}
