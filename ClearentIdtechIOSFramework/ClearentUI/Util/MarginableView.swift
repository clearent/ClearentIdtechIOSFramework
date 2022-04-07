//
//  MarginableView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

class MarginableView: XibView, Marginable {
    @IBOutlet public var bottomLayoutConstraint: NSLayoutConstraint?
    
    var viewType: UIView.Type { type(of: self) }
    
    var margings: [RelativeMargin] { [] }
    
    func setBottomMargin(value: RelativeMargin) {
        bottomLayoutConstraint?.constant = value.constant
    }
}
