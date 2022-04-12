//
//  ClearentReaderFeedbackView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReaderFeedbackView: ClearentMarginableView {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override var margins: [RelativeMargin] {
        [RelativeMargin(constant: 16, relatedViewType: ClearentPrimaryButton.self)]
    }
    
    // MARK: Public
    
    public func setup(image: String, title: String, description: String) {
        iconImageView.image = UIImage(named: image, in: ClearentConstants.bundle, compatibleWith: nil)
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
