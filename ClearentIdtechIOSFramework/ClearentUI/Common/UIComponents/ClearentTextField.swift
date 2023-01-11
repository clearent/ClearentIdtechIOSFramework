//
//  ClearentTextField.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 02.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearentTextFieldProtocol {
    func didFinishWithResult(name: String?)
    func didChangeValidationState(isValid: Bool)
}

class ClearentTextField: ClearentMarginableView, UITextFieldDelegate {

    @IBOutlet var inputField: UITextField!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var errorLabel: UILabel!
    
    var delegate: ClearentTextFieldProtocol?

    override public var margins: [BottomMargin] {
        [
            BottomMargin(constant: 80)
        ]
    }
    
    var errorLabelText: String? {
        didSet {
            errorLabel.isHidden = errorLabelText?.isEmpty ?? true || errorLabel == nil
            errorLabel.text = errorLabelText
        }
    }
    
    var infoLabelText: String? {
        didSet {
            infoLabel.text = infoLabelText
        }
    }
    
    convenience init(inputText: String?, inputTitle: String, hint: String, delegate: ClearentTextFieldProtocol) {
        self.init()
        self.infoLabel.text = inputTitle
        self.inputField.placeholder = hint
        if let inputText = inputText {
            self.inputField.text = inputText
        }
        self.inputField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        self.inputField.delegate = self
        self.delegate = delegate
        self.delegate?.didFinishWithResult(name: self.inputField.text)
    }

    override func configure() {
        infoLabel.font = ClearentUIBrandConfigurator.shared.fonts.customNameInfoLabelFont
        infoLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.infoLabelColor
        inputField.font = ClearentUIBrandConfigurator.shared.fonts.customNameInputLabelFont
        errorLabel.font = ClearentUIBrandConfigurator.shared.fonts.errorMessageLabelFont
        errorLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.fieldValidationErrorMessageColor
        errorLabel.isHidden = true
    }
    
    @objc func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 50
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        
        return newString.count <= maxLength
    }
    
    // MARK: - Private
     
    @objc final private func textFieldDidChange(textField: UITextField) {
        
        let isValid = textField.hasText && textField.text?.count ?? 0 >= 3
        self.delegate?.didChangeValidationState(isValid: isValid)
        self.delegate?.didFinishWithResult(name: textField.text)
    }
}
