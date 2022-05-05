//
//  ClearentPaymentProcessingPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 29.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public protocol ClearentPaymentProcessingView: AnyObject {
    func updateContent(with component: PaymentFeedbackComponentProtocol)
}

public protocol PaymentProcessingProtocol {
    func retryLastTransaction()
    func startBluetoothDevicePairing()
    func pairAgainBluetoothDevice()
    var flowFeedbackReceived: (() -> Void)? { get set }
}

public class ClearentPaymentProcessingPresenter {
    private weak var paymentProcessingView: ClearentPaymentProcessingView?
    private var amount: Double
    private let sdkWrapper: ClearentWrapper
    private var sdkFeedbackProvider: FlowDataProvider
    public var flowFeedbackReceived: (() -> Void)?

    // MARK: Init

    public init(paymentProcessingView: ClearentPaymentProcessingView, amount: Double, baseURL: String, publicKey: String, apiKey: String) {
        self.paymentProcessingView = paymentProcessingView
        self.amount = amount
        sdkWrapper = ClearentWrapper.shared
        sdkFeedbackProvider = FlowDataProvider()
        sdkWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
}

extension ClearentPaymentProcessingPresenter: PaymentProcessingProtocol {
    public func retryLastTransaction() {
        sdkFeedbackProvider.delegate = self
        sdkWrapper.retryLastTransaction()
    }
    
    public func startBluetoothDevicePairing() {
        sdkFeedbackProvider.delegate = self
        if (sdkWrapper.isReaderConnected()) {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        } else {
            sdkWrapper.startPairing()
        }
    }

    public func pairAgainBluetoothDevice() {
        sdkWrapper.startPairing()
    }
}

extension ClearentPaymentProcessingPresenter: FlowDataProtocol {
    public func deviceDidDisconnect() {
        // TODO: implement method
    }

    func didFinishedPairing() {
        sdkWrapper.startTransactionWithAmount(amount: String(amount))
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        let component = PaymentFeedbackComponent(feedbackItems: feedback.items)
        paymentProcessingView?.updateContent(with: component)
        flowFeedbackReceived?()
    }
}
