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
        self.delegate = delegate
        self.delegate?.didFinishWithResult(name: self.inputField.text)
    }

    override func configure() {
        self.infoLabel.font = ClearentUIBrandConfigurator.shared.fonts.customNameInfoLabelFont
        self.infoLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.infoLabelColor
        self.inputField.font = ClearentUIBrandConfigurator.shared.fonts.customNameInputLabelFont
    }
    
    @objc final private func textFieldDidChange(textField: UITextField) {
        self.delegate?.didFinishWithResult(name: self.inputField.text)
    }
}
