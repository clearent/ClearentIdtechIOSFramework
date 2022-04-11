//
//  ClearentReaderConnectivityStatusView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 06.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReaderConnectivityStatusView: ClearentXibView {

    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Public
    
    public func setup(image: UIImage, status: String) {
        statusImageView.image = image
        statusLabel.text = status
    }
}
