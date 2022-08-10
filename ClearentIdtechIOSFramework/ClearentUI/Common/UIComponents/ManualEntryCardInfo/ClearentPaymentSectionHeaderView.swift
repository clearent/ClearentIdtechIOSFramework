//
//  ClearentPaymentSectionHeaderView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 25.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearentPaymentSectionHeaderViewProtocol: AnyObject {
    func didTapOnSectionHeaderView(header: ClearentPaymentSectionHeaderView, sectionIndex: Int)
}

class ClearentPaymentSectionHeaderView: ClearentXibView {
    
    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var dropdownImageView: UIImageView!
    
    weak var delegate: ClearentPaymentSectionHeaderViewProtocol?
    
    convenience init(sectionItem: ClearentPaymentSection) {
        self.init()
        self.sectionTitleLabel.text = sectionItem.title
        self.rotateDropDownIcon(isSectionCollapsed: sectionItem.isCollapsed)
    }
    
    override func configure() {
        sectionTitleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.manualPaymentTitleColor
        sectionTitleLabel.font = ClearentUIBrandConfigurator.shared.fonts.sectionTitleLabelFont
        
        dropdownImageView.image = UIImage(named: ClearentConstants.IconName.expandMedium, in: ClearentConstants.bundle, compatibleWith: nil)
    }
    
    // MARK: - Public
    
    func rotateDropDownIcon(isSectionCollapsed: Bool) {
        dropdownImageView.transform = CGAffineTransform(rotationAngle: isSectionCollapsed ? 0.0 : .pi)
    }
    
    // MARK: - Actions
    
    @IBAction func didTapOnSectionHeaderView(_ sender: Any) {
        delegate?.didTapOnSectionHeaderView(header: self, sectionIndex: 1)
    }
}
