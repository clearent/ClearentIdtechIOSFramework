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
    private var sdkFeedbackProvider: FlowDataProvider

    // MARK: Init

    public init(paymentProcessingView: ClearentPaymentProcessingView, amount: Double, baseURL: String, publicKey: String, apiKey: String) {
        self.paymentProcessingView = paymentProcessingView
        self.amount = amount
        sdkWrapper = SDKWrapper.shared
        sdkFeedbackProvider = FlowDataProvider()
        sdkWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
}

extension ClearentPaymentProcessingPresenter: PaymentProcessingProtocol {
    public func startBluetoothDevicePairing() {
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
    public func deviceDidDisconnect() {
        guard let paymentProcessingView = paymentProcessingView else { return }
        paymentProcessingView.updateInfoLabel(message: "Oops, Device Disconnected")
        paymentProcessingView.updatePairingButton(shouldBeHidden: false)
    }
    
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
