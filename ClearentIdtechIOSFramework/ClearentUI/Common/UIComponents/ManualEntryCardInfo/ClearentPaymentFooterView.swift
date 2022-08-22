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
    
    func enableConfirmButton() {
        confirmButton.setEnabledButton()
        confirmButton.isEnabled = true
    }
    
    func disableConfirmButton() {
        confirmButton.setDisabledButton()
        confirmButton.isEnabled = false
    }
    
    // MARK: - Private
    
    private func setupCancelButton() {
        cancelButton.buttonStyle = .bordered
        cancelButton.button.setTitle(ClearentConstants.Localized.ManualEntry.footerCancel, for: .normal)
        
        cancelButton.action = {
            self.cancelButtonAction?()
        }
    }
    
    private func setupConfirmButton() {
        confirmButton.buttonStyle = .filled
        confirmButton.button.setTitle(ClearentConstants.Localized.ManualEntry.footerConfirm, for: .normal)
        disableConfirmButton()
        
        confirmButton.action = {
            self.confirmButtonAction?()
        }
    }
}
