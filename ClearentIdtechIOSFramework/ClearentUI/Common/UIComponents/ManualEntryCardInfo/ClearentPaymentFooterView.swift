//
//  ClearentPaymentFooterView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 18.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

class ClearentPaymentFooterView: ClearentXibView {
    
    @IBOutlet weak var cancelButton: ClearentPrimaryButton!
    @IBOutlet weak var confirmButton: ClearentPrimaryButton!
    
    var cancelButtonAction: (() -> Void)?
    var confirmButtonAction: (() -> Void)?
    
    override func configure() {
        setupCancelButton()
        setupConfirmButton()
    }
    
    // MARK: - Private
    
    private func setupCancelButton() {
        cancelButton.buttonStyle = .bordered
        cancelButton.button.setTitle("xsdk_payment_manual_entry_user_action_cancel".localized, for: .normal)
        
        cancelButton.action = {
            self.cancelButtonAction?()
        }
    }
    
    private func setupConfirmButton() {
        confirmButton.buttonStyle = .filled
        confirmButton.button.setTitle("xsdk_payment_manual_entry_user_action_confirm".localized, for: .normal)
        
        confirmButton.action = {
            self.confirmButtonAction?()
        }
    }
}
