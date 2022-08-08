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
    private var previousText: String = ""
    
    override func configure() {
        titleLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.paymentFieldTitleColor
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.paymentFieldTitleLabelFont
        
        errorImageView.image = UIImage(named: ClearentConstants.IconName.exclamationMark, in: ClearentConstants.bundle, compatibleWith: nil)
        errorImageView.isHidden = true
        
        errorLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.errorMessageTextColor
        errorLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        errorLabel.isHidden = true

        configureTextField()
        
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
    
    private func configureTextField() {
        textField.addTarget(self, action: #selector(textFieldDidCompleteEditing), for: .editingDidEnd)
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.borderColor.cgColor
        textField.layer.cornerRadius = 4
        textField.layer.masksToBounds = true
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
        textField.text = item.enteredValue
        
        if item.isValid {
            disableErrorState()
        } else {
            enableErrorState(errorMessage: item.errorMessage)
        }
    }
    
    func setupTextField(placeholder: String?, isFirstCell: Bool, isLastCell: Bool) {
        guard let item = item else { return }

        textField.keyboardType = (item.type == .creditCardNo || item.type == .date || item.type == .securityCode) ? .numberPad : .default
        textField.addNavigationAndDoneToKeyboard(previousAction: (target: self, action: #selector(previousButtonTapped), isEnabled: !isFirstCell), nextAction: (target: self, action: #selector(nextButtonTapped), isEnabled: !isLastCell))
        if let placeholder = placeholder {
            let attributes: [NSAttributedString.Key: Any] = [.font: ClearentUIBrandConfigurator.shared.fonts.textfieldPlaceholder,
                                                             .foregroundColor: ClearentUIBrandConfigurator.shared.colorPalette.paymentTextFieldPlaceholder]
            textField.attributedPlaceholder =  NSAttributedString(string: placeholder, attributes: attributes)
        } else {
            textField.placeholder = ""
        }
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
        guard let text = sender.text, let item = item else { return }
        
        switch item.type {
        case .creditCardNo:
            handleCreditCardNo(enteredText: text, sender: sender)
        case.date:
            handleExpirationDate(enteredText: text, sender: sender)
        default:
            sender.text = String(text.prefix(item.maxNoOfChars))
        }

    }
    
    private func handleCreditCardNo(enteredText: String, sender: UITextField) {
        guard let item = item else { return }
        // insert an empty space every 4 digits and force a max number of entered digits
        let textWithoutSpaces = enteredText.replacingOccurrences(of: " ", with: "")
        let maxText = String(textWithoutSpaces.prefix(item.maxNoOfChars))
        let regex = try? NSRegularExpression(pattern: "([0-9]{4})(?!$)", options: .caseInsensitive)
        let formattedText = regex?.stringByReplacingMatches(in: maxText,
                                  options: .reportProgress,
                                  range: NSMakeRange(0, maxText.count),
                                  withTemplate: "$0 ")
        sender.text = formattedText
    }

    private func handleExpirationDate(enteredText: String, sender: UITextField) {
        // insert a '/' after 2 digits
        var dateWithoutSlash = enteredText.replacingOccurrences(of: "/", with: "")
    
        if dateWithoutSlash.count >= 2 && previousText.last != "/" {
            dateWithoutSlash.insert("/", at: enteredText.index(enteredText.startIndex, offsetBy: 2))
        }
        sender.text = String(dateWithoutSlash.prefix(5))
        previousText = enteredText
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
