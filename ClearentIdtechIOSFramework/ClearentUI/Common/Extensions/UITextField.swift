//
//  UITextField.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 26.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UITextField {
    typealias KeyboardAction = (target: Any, action: Selector, isEnabled: Bool)
    
    // Adds a toolbar with a done button to the UITextField's Keyboard
    func addDoneToKeyboard() {
        let onDone = (target: self, action: #selector(doneButtonTapped), isEnabled: true)
        let doneBtn = UIBarButtonItem(title: "xsdk_keyboard_done".localized, style: .done, target: onDone.target, action: onDone.action)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        createToolbar(with: [flexibleSpace, doneBtn])
    }
    
    // Adds a toolbar with navigation arrows and done button to the UITextField's Keyboard
    func addNavigationAndDoneToKeyboard(previousAction: KeyboardAction, nextAction: KeyboardAction) {
        let onDone = (target: self, action: #selector(doneButtonTapped))
        let doneBtn = UIBarButtonItem(title: "xsdk_keyboard_done".localized, style: .done, target: onDone.target, action: onDone.action)
        
        let previousButton = UIBarButtonItem(image: UIImage(named: ClearentConstants.IconName.collapseMedium, in: ClearentConstants.bundle, with: nil), style: .plain, target: previousAction.target, action: previousAction.action)
        previousButton.isEnabled = previousAction.isEnabled
        
        let nextButton = UIBarButtonItem(image: UIImage(named: ClearentConstants.IconName.expandMedium, in: ClearentConstants.bundle, with: nil), style: .plain, target: nextAction.target, action: nextAction.action)
        nextButton.isEnabled = nextAction.isEnabled
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 10
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        createToolbar(with: [fixedSpace, previousButton, fixedSpace, nextButton, flexibleSpace, doneBtn])
    }
    
    private func createToolbar(with items: [UIBarButtonItem]) {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60))
        toolbar.items = items
        toolbar.sizeToFit()
        inputAccessoryView = toolbar
    }
    
    @objc private func doneButtonTapped() {
        _ = resignFirstResponder()
    }
}
