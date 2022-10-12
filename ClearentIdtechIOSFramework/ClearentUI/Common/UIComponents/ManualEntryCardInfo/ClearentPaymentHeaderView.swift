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
    @IBOutlet weak var stackView: UIStackView!
    
    override func configure() {
        let titleLabel = UILabel()
        titleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.manualPaymentTitleColor
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentViewTitleLabelFont
        titleLabel.text = ClearentConstants.Localized.ManualEntry.header
        titleLabel.textAlignment = .center
        
        stackView.addArrangedSubview(titleLabel)
    }
    
    // MARK: - Public
    
    public func addOfflineModeStatus(_ value: String) {
        stackView.addArrangedSubview(ClearentSubtitleLabel(text: value))
    }
}
