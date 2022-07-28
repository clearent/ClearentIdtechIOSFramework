//
//  ClearentPaymentSectionHeaderView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 25.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearentPaymentSectionHeaderViewProtocol: AnyObject {
    func didTapOnSectionHeaderView(_ sender: ClearentPaymentSectionHeaderView)
}

class ClearentPaymentSectionHeaderView: ClearentXibView {
    
    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var dropdownImageView: UIImageView!
    
    weak var delegate: ClearentPaymentSectionHeaderViewProtocol?
    
    override func configure() {
        sectionTitleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.paymentSectionTitleColor
        sectionTitleLabel.font = ClearentUIBrandConfigurator.shared.fonts.sectionTitleLabelFont
        sectionTitleLabel.text = "xsdk_payment_manual_entry_additional_section_title".localized
        dropdownImageView.image = UIImage(named: ClearentConstants.IconName.expandMedium, in: ClearentConstants.bundle, compatibleWith: nil)
    }
    
    // MARK: - Public
    
    public func updateDropDownIcon(isSectionCollapsed: Bool) {
        let expandIcon = UIImage(named: ClearentConstants.IconName.expandMedium, in: ClearentConstants.bundle, compatibleWith: nil)
        
        dropdownImageView.image = isSectionCollapsed ? expandIcon : rotateDropDownIcon()
    }
    
    // MARK: - Private
    
    private func rotateDropDownIcon() -> UIImage? {
        dropdownImageView.transform = CGAffineTransform(rotationAngle: .pi)
        
        return dropdownImageView.image
    }
    
    // MARK: - Actions
    
    @IBAction func didTapOnSectionHeaderView(_ sender: Any) {
        delegate?.didTapOnSectionHeaderView(self)
    }
}
