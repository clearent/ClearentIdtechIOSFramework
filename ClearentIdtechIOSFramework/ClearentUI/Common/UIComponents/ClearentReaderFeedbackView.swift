//
//  ClearentReaderFeedbackView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReaderFeedbackView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: Private
    
    private func commonInit() {
        Bundle(for: ClearentReaderFeedbackView.self).loadNibNamed("ClearentReaderFeedbackView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }
}