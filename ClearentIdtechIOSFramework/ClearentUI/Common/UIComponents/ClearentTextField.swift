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

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    var delegate: ClearentTextFieldProtocol?

    private var readerName: String?
        override public var margins: [BottomMargin] {
        [
            BottomMargin(constant: 80)
        ]
    }
    
    convenience init(currentReaderName: String?, inputName: String, hint: String, delegate: ClearentTextFieldProtocol) {
        self.init()
        self.readerName = currentReaderName
        self.infoLabel.text = inputName
        self.inputField.placeholder = hint
        if let readerName = self.readerName {
            self.inputField.text = readerName
        }
        self.inputField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        self.inputField.delegate = self
        self.delegate = delegate
        self.delegate?.didFinishWithResult(name: self.inputField.text)
    }

    override func configure() {
        self.infoLabel.font = ClearentUIBrandConfigurator.shared.fonts.customNameInfoLabelFont
        self.infoLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.infoLabelColor
        self.inputField.font = ClearentUIBrandConfigurator.shared.fonts.customNameInputLabelFont
    }
    
    
    @objc func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 50
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        
        return newString.count <= maxLength
    }
    
    @objc final private func textFieldDidChange(textField: UITextField) {
        
        let isValid = textField.hasText && textField.text?.count ?? 0 >= 3
        self.delegate?.didChangeValidationState(isValid: isValid)
        self.delegate?.didFinishWithResult(name: textField.text)
    }
}
