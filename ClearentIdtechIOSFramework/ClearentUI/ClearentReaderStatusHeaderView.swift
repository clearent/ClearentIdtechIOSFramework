//
//  ClearentReaderStatusHeaderView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReaderStatusHeaderView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var readerNameLabel: UILabel!
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle(for: ClearentReaderStatusHeaderView.self).loadNibNamed("ClearentReaderStatusHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }
}
