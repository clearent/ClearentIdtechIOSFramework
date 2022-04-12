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
    func updatePairingButton(shouldBeHidden: Bool)
    func updateDismissButton(shouldBeHidden: Bool)
    func updateDeviceNameLabel(value: String)
    func updateContent(with component: PaymentFeedbackComponentProtocol)
}

public protocol PaymentProcessingProtocol {
    func startBluetoothDevicePairing()
    func pairAgainBluetoothDevice()
}

public class ClearentPaymentProcessingPresenter {
    private weak var paymentProcessingView: ClearentPaymentProcessingView?
    private var amount: Double
    private let sdkWrapper: SDKWrapper
    private var sdkFeedbackProvider : FlowDataProvider
    
    // MARK: Init
    
    public init(paymentProcessingView: ClearentPaymentProcessingView, amount: Double, baseURL: String, publicKey: String, apiKey: String) {
        self.paymentProcessingView = paymentProcessingView
        self.amount = amount
        self.sdkWrapper = SDKWrapper.shared
        sdkFeedbackProvider = FlowDataProvider()
        self.sdkWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
}

extension ClearentPaymentProcessingPresenter: PaymentProcessingProtocol {
    public func startBluetoothDevicePairing() {
       // sdkWrapper.delegate = self
        sdkFeedbackProvider.delegate = self
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updatePairingButton(shouldBeHidden: true)
        
        if sdkWrapper.isReaderConnected() {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        } else {
            paymentProcessingView.updateInfoLabel(message: "SEARCHING FOR READER...")
            
            sdkWrapper.startPairing()
        }
    }
    
    public func pairAgainBluetoothDevice() {
        sdkWrapper.startPairing()
    }
}

extension ClearentPaymentProcessingPresenter: FlowDataProtocol {
    
    func didFinishedPairing() {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Device Successfully Paired")
        sdkWrapper.startTransactionWithAmount(amount: String(amount))
    }
    
    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        let component = PaymentFeedbackComponent(feedbackItems: feedback.items)
        paymentProcessingView?.updateContent(with: component)
    }
}

extension ClearentPaymentProcessingPresenter: SDKWrapperProtocol {
    public func didEncounteredGeneralError() {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Oops, General Error")
        paymentProcessingView.updatePairingButton(shouldBeHidden: false)
    }
    
    public func didFinishPairing() {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Device Successfully Paired")
        
        sdkWrapper.startTransactionWithAmount(amount: String(amount))
    }
    
    public func didFinishTransaction() {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Transaction Completed")
        paymentProcessingView.updateDismissButton(shouldBeHidden: false)
    }
    
    public func didReceiveTransactionError(error: TransactionError) {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Oops, General Error")
    }
    
    public func userActionNeeded(action: UserAction) {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: action.rawValue)
    }
    
    public func didReceiveInfo(info: UserInfo) {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: info.rawValue)
    }
    
    public func deviceDidDisconnect() {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Oops, Device Disconnected")
        paymentProcessingView.updatePairingButton(shouldBeHidden: false)
    }
    
    public func didReceiveDeviceFriendlyName(_ name: String?) {
        guard let deviceFriendlyName = name else {
            paymentProcessingView?.updateDeviceNameLabel(value: "Unknown")
            return
        }
        paymentProcessingView?.updateDeviceNameLabel(value: deviceFriendlyName)
    }
}
