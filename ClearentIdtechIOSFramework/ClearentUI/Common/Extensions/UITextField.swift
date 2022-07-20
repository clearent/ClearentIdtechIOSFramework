//
//  UITextField.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 20.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UITextField {
     // Adds a toolbar with a done button to the UITextField's Keyboard
    func addDoneToKeyboard(barButtonTitle: String, onDone: (target: Any, action: Selector)? = nil) {
         let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))

         let toolbar: UIToolbar = UIToolbar()
         let flexibleSpaceBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
         let doneBtn = UIBarButtonItem(title: barButtonTitle, style: .done, target: onDone.target, action: onDone.action)

         toolbar.items = [flexibleSpaceBtn, doneBtn]
         toolbar.sizeToFit()
         inputAccessoryView = toolbar
     }

     @objc private func doneButtonTapped() {
         _ = resignFirstResponder()
     }
 }
