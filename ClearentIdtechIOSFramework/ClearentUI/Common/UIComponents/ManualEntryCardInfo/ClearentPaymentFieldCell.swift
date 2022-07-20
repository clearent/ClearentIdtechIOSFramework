//
//  ClearentPaymentFieldCell.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentPaymentFieldCell: UITableViewCell {

    static let identifier = "ClearentPaymentFieldCellIdentifier"
    static let nib = "ClearentPaymentFieldCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var fieldButton: UIButton!
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure()
    }
    
    static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentPaymentFieldCell.nib, bundle: Bundle(for: ClearentPaymentFieldCell.self)),
                           forCellReuseIdentifier: ClearentPaymentFieldCell.identifier)
    }
    
    func setup(with row: ClearentPaymentItem) {
        titleLabel.text = row.title
        textField.placeholder = row.placeholder
        errorMessageLabel.text = row.errorMessage
        
        if let iconName = row.iconName {
            fieldButton.setImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
        }
    }
    
    // MARK: - Private
    
    private func configure() {
        titleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.paymentFieldTitleColor
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentFieldTitleLabelFont

        errorMessageLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.errorMessageTextColor
        errorMessageLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        
        errorImageView.image = UIImage(named: ClearentConstants.IconName.exclamationMark, in: ClearentConstants.bundle, compatibleWith: nil)
        errorImageView.isHidden = true
        errorMessageLabel.isHidden = true
    }
}
