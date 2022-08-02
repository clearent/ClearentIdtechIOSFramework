//
//  ClearentPaymentTextField.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 29.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

class ClearentPaymentTextField: ClearentXibView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var fieldButton: UIButton!

    var action: ((ClearentPaymentItem, String?) -> Void)?
    var item: ClearentPaymentItem?
    
    override func configure() {
        titleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.paymentFieldTitleColor
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentFieldTitleLabelFont
        
        errorImageView.image = UIImage(named: ClearentConstants.IconName.exclamationMark, in: ClearentConstants.bundle, compatibleWith: nil)
        errorImageView.isHidden = true
        
        errorLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.errorMessageTextColor
        errorLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        errorLabel.isHidden = true
        
        textField.addTarget(self, action: #selector(textFieldDidCompleteEditing), for: .editingDidEnd)
        textField.addDoneToKeyboard(barButtonTitle: "xsdk_keyboard_done".localized)
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
        textField.layer.cornerRadius = 4
        textField.layer.masksToBounds = true
        
        fieldButton.isHidden = true
        fieldButton.setImage(UIImage(named: ClearentConstants.IconName.calendar, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
    }
    
    // MARK: - Private
    
    @objc private func textFieldDidCompleteEditing() {
        guard let item = item else {
            return
        }

        action?(item, textField.text)
    }
    
    // MARK: - Public
    
    func setup(with item: ClearentPaymentItem) {
        self.item = item
        titleLabel.text = item.title
        textField.placeholder = item.placeholder
        textField.keyboardType = (item.type == .creditCardNo || item.type == .date || item.type == .securityCode) ? .numberPad : .default
        errorLabel.text = item.errorMessage
        fieldButton.isHidden = item.type != .date
    }
    
    func enableErrorState(errorMessage: String?) {
        errorImageView.isHidden = false
        errorLabel.isHidden = false
        errorLabel.text = errorMessage
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.errorMessageTextColor.cgColor
    }
    
    func disableErrorState() {
        errorImageView.isHidden = true
        errorLabel.isHidden = true
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
    }
    
    // MARK: - Actions
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard var text = sender.text else { return }
        
        if text.count > 0 && text.count % 5 == 0 && text.last != " " {
            text.insert(" ", at: text.index(text.startIndex, offsetBy: text.count - 1))
        }
        sender.text = text
    }
}
