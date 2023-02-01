//
//  ClearentAbstractViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 01.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import Foundation

open class ClearentAbstractViewController: UIViewController {
    @IBOutlet public weak var containerMaxWidthConstraint: NSLayoutConstraint!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        containerMaxWidthConstraint.constant = 600
    }
}
