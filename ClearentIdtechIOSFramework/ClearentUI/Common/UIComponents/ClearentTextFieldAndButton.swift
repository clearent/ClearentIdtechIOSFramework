//
//  ClearentEmailForm.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.01.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

class ClearentTextFieldAndButton: ClearentMarginableView {
    
    // MARK: - Properties
    
    @IBOutlet weak var textField: ClearentTextField!
    @IBOutlet weak var button: ClearentPrimaryButton!
    
    var buttonAction: ((_ emailAddress: String?) -> Void)?
    
    var textFieldValue: String? {
        didSet {
            textField.inputField.text = textFieldValue
        }
    }
    
    var textFieldError: String? {
        didSet {
            textField.errorLabelText = textFieldError
        }
    }
    
    convenience init(textFieldTitle: String, textFieldPlaceholder: String, buttonTitle: String) {
        self.init()
        self.textField.infoLabelText = textFieldTitle
        self.button.title = buttonTitle
    }
    
    override func configure() {
        button.title = ClearentConstants.Localized.EmailReceipt.emailFormButtonSend
        button.button.isUserInteractionEnabled = false
    }
    
    @IBAction func doneButtonWasTapped(_ sender: Any) {
        buttonAction?(textField.inputField.text)
    }
}
