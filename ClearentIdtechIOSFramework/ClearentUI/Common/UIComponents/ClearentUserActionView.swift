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
    @IBOutlet weak var loadingView: ClearentLoadingView!
    @IBOutlet weak var loadingTopLayoutConstraint: NSLayoutConstraint!
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(contant: 80)
        ]
    }
    
    var isLoading: Bool = false {
        didSet {
            loadingView.isHidden = !isLoading
            userActionImageView.isHidden = isLoading
            let priority: Float = isLoading ? 1000 : 999
            loadingTopLayoutConstraint.priority = UILayoutPriority(rawValue: priority)
        }
    }
    
    // MARK: Public
    
    public func setup(imageName: String?, description: String) {
        descriptionLabel.text = description
        isLoading = imageName == nil
        if let imageName = imageName {
            userActionImageView.image = UIImage(named: imageName, in: ClearentConstants.bundle, compatibleWith: nil)
        }
    }
}
