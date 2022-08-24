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

    var previousButtonWasTapped: ((_ identifier: ItemIdentifier) -> Void)?
    var nextButtonWasTapped: ((_ identifier: ItemIdentifier) -> Void)?
    var action: ((ClearentPaymentItem, String?) -> Void)?
    var item: ClearentPaymentItem?
    
    override func configure() {
        titleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.manualPaymentTitleColor
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentFieldTitleLabelFont
        
        errorImageView.image = UIImage(named: ClearentConstants.IconName.exclamationMark, in: ClearentConstants.bundle, compatibleWith: nil)
        errorImageView.isHidden = true
        
        errorLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.manualPaymentErrorMessageColor
        errorLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        errorLabel.isHidden = true

        configureTextField()
        
        fieldButton.isHidden = true
        fieldButton.setImage(UIImage(named: ClearentConstants.IconName.calendar, in: ClearentConstants.bundle, compatibleWith: nil), for: .normal)
    }
    
    // MARK: - Public
    
    func setup(with item: ClearentPaymentItem, isFirstCell: Bool, isLastCell: Bool) {
        self.item = item
        if let tag = item.identifier?.tag {
            textField.tag = tag
        }
        titleLabel.text = item.title
        setupTextField(placeholder: item.placeholder, isFirstCell: isFirstCell, isLastCell: isLastCell)
        fieldButton.isHidden = item.type != .date
        textField.text = item.hiddenValue ?? item.enteredValue
        
        if item.isValid {
            disableErrorState()
        } else {
            enableErrorState(errorMessage: item.errorMessage)
        }
    }
    
    func setupTextField(placeholder: String?, isFirstCell: Bool, isLastCell: Bool) {
        guard let item = item else { return }

        textField.keyboardType = [.creditCardNo, .date, .securityCode, .billingZipCode, .shippingZipCode].contains(item.type) ? .numberPad : .default
        textField.addNavigationAndDoneToKeyboard(previousAction: (target: self, action: #selector(previousButtonTapped), isEnabled: !isFirstCell), nextAction: (target: self, action: #selector(nextButtonTapped), isEnabled: !isLastCell))
        if let placeholder = placeholder {
            let attributes: [NSAttributedString.Key: Any] = [.font: ClearentUIBrandConfigurator.shared.fonts.textfieldPlaceholder,
                                                             .foregroundColor: ClearentUIBrandConfigurator.shared.colorPalette.manualPaymentTextFieldPlaceholder]
            textField.attributedPlaceholder =  NSAttributedString(string: placeholder, attributes: attributes)
        } else {
            textField.placeholder = ""
        }
        textField.clearButtonMode = (item.type == .date) ? .never : .whileEditing
    }
    
    func enableErrorState(errorMessage: String?) {
        errorImageView.isHidden = false
        errorLabel.isHidden = false
        errorLabel.text = errorMessage
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.manualPaymentErrorMessageColor.cgColor
    }
    
    func disableErrorState() {
        errorImageView.isHidden = true
        errorLabel.isHidden = true
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
    }
    
    // MARK: - Actions
    
    @IBAction private func textFieldEditingChanged(_ sender: UITextField) {
        guard let text = sender.text, let item = item else { return }
        
        switch item.type {
        case .creditCardNo, .billingZipCode, .shippingZipCode:
            let newText = ClearentFieldValidationHelper.formattedCardData(text: text, item: item)
            textField.resetCursorPosition(for: newText, separator: item.type.separator)
        case.date:
            let newText = ClearentFieldValidationHelper.formattedExpirationDate(text: text, item: item)
            textField.resetCursorPosition(for: newText)
        default:
            sender.text = String(text.prefix(item.maxNoOfChars))
        }
    }

    @objc private func textFieldDidCompleteEditing() {
        guard let item = item, let text = textField.text else { return }
        
        action?(item, text)
        
        switch item.type {
        case .creditCardNo:
            ClearentFieldValidationHelper.hideCardNumber(text: text, sender: textField, item: item)
        case .securityCode:
            ClearentFieldValidationHelper.hideSecurityCode(text: text, sender: textField, item: item)
        default:
            break
        }
    }
    
    @objc private func touchDown() {
        switch item?.type {
        case .creditCardNo, .securityCode:
            textField.text = item?.enteredValue
        default:
            break
        }
    }
    
    private func configureTextField() {
        textField.addTarget(self, action: #selector(textFieldDidCompleteEditing), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(touchDown), for: .editingDidBegin)
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
        textField.layer.cornerRadius = 4
        textField.layer.masksToBounds = true
    }
}

extension ClearentPaymentTextField {
    @objc private func previousButtonTapped() {
        previousButtonWasTapped?(item?.identifier)
        _ = resignFirstResponder()
    }
    
    @objc private func nextButtonTapped() {
        nextButtonWasTapped?(item?.identifier)
        _ = resignFirstResponder()
    }
}


