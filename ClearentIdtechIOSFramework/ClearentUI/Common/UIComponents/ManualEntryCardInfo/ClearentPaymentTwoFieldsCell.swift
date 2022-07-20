//
//  ClearentPaymentTwoFieldsCell.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentPaymentTwoFieldsCell: UITableViewCell {
    
    static let nib = "ClearentPaymentTwoFieldsCell"
    static let identifier = "ClearentPaymentTwoFieldsCellIdentifier"
    
    @IBOutlet weak var expirationDateTitleLabel: UILabel!
    @IBOutlet weak var expirationDateTextField: UITextField!
    @IBOutlet weak var calendarButton: UIButton!
    @IBOutlet weak var expirationDateErrorImageView: UIImageView!
    @IBOutlet weak var expirationDateErrorMessageLabel: UILabel!
    
    @IBOutlet weak var securityCodeTitleLabel: UILabel!
    @IBOutlet weak var securityCodeTextField: UITextField!
    @IBOutlet weak var securityCodeErrorImageView: UIImageView!
    @IBOutlet weak var securityCodeErrorMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure()
    }
    
    static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentPaymentTwoFieldsCell.nib, bundle: Bundle(for: ClearentPaymentTwoFieldsCell.self)),
                           forCellReuseIdentifier: ClearentPaymentTwoFieldsCell.identifier)
    }
    
    func setup(with row: ClearentPaymentRow) {
        setupExpirationDateField(item: row.elements[0])
        setupSecurityCodeField(item: row.elements[1])
    }
    
    // MARK: - Private
    
    private func configure() {
        expirationDateTitleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.paymentFieldTitleColor
        expirationDateTitleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentFieldTitleLabelFont
        
        expirationDateErrorImageView.image = UIImage(named: ClearentConstants.IconName.exclamationMark, in: ClearentConstants.bundle, compatibleWith: nil)
        expirationDateErrorImageView.isHidden = true
        
        expirationDateErrorMessageLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.errorMessageTextColor
        expirationDateErrorMessageLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        expirationDateErrorMessageLabel.isHidden = true
        
        securityCodeTitleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.paymentFieldTitleColor
        securityCodeTitleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentFieldTitleLabelFont
        
        securityCodeTextField.keyboardType = .numberPad
        securityCodeTextField.layer.borderWidth = 1.0
        securityCodeTextField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
        securityCodeTextField.layer.cornerRadius = 4
        securityCodeTextField.layer.masksToBounds = true
        securityCodeTextField.addDoneToKeyboard(barButtonTitle: "xsdk_keyboard_done".localized)
        
        securityCodeErrorImageView.image = UIImage(named: ClearentConstants.IconName.exclamationMark, in: ClearentConstants.bundle, compatibleWith: nil)
        securityCodeErrorImageView.isHidden = true
        
        securityCodeErrorMessageLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.errorMessageTextColor
        securityCodeErrorMessageLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        securityCodeErrorMessageLabel.isHidden = true
    }
    
    private func setupExpirationDateField(item: ClearentPaymentItem) {
        expirationDateTitleLabel.text = item.title
        
        expirationDateTextField.placeholder = item.placeholder
        expirationDateTextField.layer.borderWidth = 1.0
        expirationDateTextField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
        expirationDateTextField.layer.cornerRadius = 4
        expirationDateTextField.layer.masksToBounds = true
        expirationDateTextField.keyboardType = .numberPad
        expirationDateTextField.addDoneToKeyboard(barButtonTitle: "xsdk_keyboard_done".localized)
        
        if let iconName = item.iconName {
            calendarButton.setImage(UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
        }
        expirationDateErrorMessageLabel.text = item.errorMessage
    }
    
    private func setupSecurityCodeField(item: ClearentPaymentItem) {
        securityCodeTitleLabel.text = item.title
        securityCodeTextField.placeholder = item.placeholder
        securityCodeErrorMessageLabel.text = item.errorMessage
    }
}
