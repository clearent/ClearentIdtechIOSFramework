//
//  ClearentTextField.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 02.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearenttextFieldProtocol {
    func didFinishWithResult(name: String?)
}

class ClearentTextField: ClearentMarginableView, UITextFieldDelegate {

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    var delegate: ClearenttextFieldProtocol?

    private var readerName: String?
        override public var margins: [BottomMargin] {
        [
            BottomMargin(constant: 80)
        ]
    }
    
    convenience init(currentReaderName: String?, inputName: String, hint: String, delegate: ClearenttextFieldProtocol) {
        self.init()
        self.readerName = currentReaderName
        self.infoLabel.text = inputName
        self.inputField.placeholder = hint
        if let readerName = self.readerName {
            self.inputField.text = readerName
        }
        self.inputField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        self.delegate = delegate
    }

    override func configure() {
        self.infoLabel.font = ClearentConstants.Font.proTextSmall
        self.inputField.font = ClearentConstants.Font.proTextNormal
    }
    
    @objc final private func textFieldDidChange(textField: UITextField) {
        self.delegate?.didFinishWithResult(name: self.inputField.text)
    }
}
