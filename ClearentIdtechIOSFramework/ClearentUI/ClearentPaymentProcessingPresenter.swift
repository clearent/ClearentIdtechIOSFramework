//
//  ClearentPaymentProcessingPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 29.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public protocol ClearentPaymentProcessingView: AnyObject {
    func updateInfoLabel(message: String)
}

public protocol PaymentProcessingProtocol {
    func startBluetoothDevicePairing()
}

public class ClearentPaymentProcessingPresenter {
    private weak var paymentProcessingView: ClearentPaymentProcessingView?
    private var amount: Double
    private let sdkWrapper: SDKWrapper
    
    // MARK: Init
    
    public init(paymentProcessingView: ClearentPaymentProcessingView, amount: Double, baseURL: String, publicKey: String, apiKey: String) {
        self.paymentProcessingView = paymentProcessingView
        self.amount = amount
        self.sdkWrapper = SDKWrapper(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
}

extension ClearentPaymentProcessingPresenter: PaymentProcessingProtocol {
    public func startBluetoothDevicePairing() {
        sdkWrapper.delegate = self
        sdkWrapper.startPairing()
        
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: "SEARCHING FOR READER...")
    }
}

extension ClearentPaymentProcessingPresenter: SDKWrapperProtocol {
    public func didEncounteredGeneralError() {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: "Oops, General Error")
        //button for try again
    }
    
    public func didFinishPairing() {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: "Device Successfully Paired")
        
        sdkWrapper.startTransactionWithAmount(amount: String(amount))
    }
    
    public func didFinishTransaction() {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: "Transaction Completed")
    }
    
    public func didReceiveTransactionError(error: TransactionError) {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: "Oops, General Error")
    }
    
    public func userActionNeeded(action: UserAction) {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: action.rawValue)
    }
    
    public func didReceiveInfo(info: UserInfo) {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: info.rawValue)
    }
    
    public func deviceDidDisconnect() {
        guard let paymentProcessingViewController = paymentProcessingView else { return }
        paymentProcessingViewController.updateInfoLabel(message: "Oops, Device Disconnected")
        //button for try again
    }
}
