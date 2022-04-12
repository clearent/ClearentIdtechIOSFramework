//
//  ClearentUserActionView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 06.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentUserActionView: ClearentMarginableView {

    @IBOutlet weak var userActionImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override var margins: [RelativeMargin] {
        [RelativeMargin(constant: 24.0, relatedViewType: ClearentPrimaryButton.self)]
    }
    
    // MARK: Public
    
    public func setup(imageName: String, description: String) {
        userActionImageView.image = UIImage(named: imageName, in: ClearentConstants.bundle, compatibleWith: nil)
        descriptionLabel.text = description
    }
}
