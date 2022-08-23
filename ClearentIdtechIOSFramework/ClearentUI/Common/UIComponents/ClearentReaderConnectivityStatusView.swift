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
    
    var textColor: UIColor? {
        didSet {
            statusLabel.textColor = textColor
        }
    }

    public var font: UIFont? {
        didSet {
            statusLabel.font = font
        }
    }

    override func configure() {
        textColor = ClearentUIBrandConfigurator.shared.colorPalette.readerStatusLabelColor
        font = ClearentUIBrandConfigurator.shared.fonts.statusLabelFont
    }
    
    // MARK: Public

    public func setup(imageName: String?, status: String) {
        statusLabel.text = status
        statusImageView.isHidden = imageName == nil
        guard let imageName = imageName else { return }
        statusImageView.image = UIImage(named: imageName, in: ClearentConstants.bundle, compatibleWith: nil)
    }
}
