//
//  ClearentPaymentHeaderView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 18.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

class ClearentPaymentHeaderView: ClearentXibView {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func configure() {
        titleLabel.textColor = UIColor(hexString: "#272431")
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentViewTitleLabelFont
        titleLabel.text = "xsdk_payment_manual_entry_title".localized
    }
}
