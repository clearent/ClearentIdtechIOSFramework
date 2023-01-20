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
    @IBOutlet weak var subtitleLabel: ClearentSubtitleLabel!
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
    
    var showSubtitleLabel: Bool = false {
        didSet {
            subtitleLabel.isHidden = !showSubtitleLabel
        }
    }
    
    // MARK: - Methods
    
    convenience init(textFieldTitle: String, textFieldPlaceholder: String, subtitleText: String, buttonTitle: String) {
        self.init()
        self.textField.infoLabelText = textFieldTitle
        self.textField.placeholderText = textFieldPlaceholder
        self.subtitleLabel.title = subtitleText
        self.button.title = buttonTitle
    }
    
    override func configure() {
        button.title = ClearentConstants.Localized.EmailReceipt.emailFormButtonSend
        button.button.isUserInteractionEnabled = false
        subtitleLabel.label.textAlignment = .left
    }
    
    @IBAction func doneButtonWasTapped(_ sender: Any) {
        buttonAction?(textField.inputField.text)
    }
}
