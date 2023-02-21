//
//  ClearentAbstractViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 01.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import Foundation

/// All screens that should have a maximum width (for iPad support) inherit from this class. The maximum width can be set by updating ClearentConstants.Size.defaultScreenMaxWidth.
/// If a screen needs a custom value, it can override containerMaxWidthConstraint.

open class ClearentAbstractViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet public weak var containerMaxWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        containerMaxWidthConstraint.constant = ClearentConstants.Size.defaultScreenMaxWidth
    }
}
