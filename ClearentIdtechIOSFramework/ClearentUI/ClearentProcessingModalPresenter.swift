//
//  ClearentProcessingModalPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 29.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public protocol ClearentProcessingModalView: AnyObject {
    func updateContent(with feedback: FlowFeedback)
    func showLoadingView()
    func dismissView()
}

public protocol ProcessingModalProtocol {
    func restartProcess(processType: ProcessType)
    func startFlow()
    func startNewPairing()
    var flowFeedbackReceived: (() -> Void)? { get set }
}

public class ClearentProcessingModalPresenter {
    private weak var paymentProcessingView: ClearentProcessingModalView?
    private var amount: Double?
    private let sdkWrapper: ClearentWrapper
    private var sdkFeedbackProvider: FlowDataProvider
    public var flowFeedbackReceived: (() -> Void)?
    private let processType: ProcessType

    // MARK: Init

    public init(paymentProcessingView: ClearentProcessingModalView, amount: Double?, baseURL: String, publicKey: String, apiKey: String, processType: ProcessType) {
        self.paymentProcessingView = paymentProcessingView
        self.amount = amount
        self.processType = processType
        sdkWrapper = ClearentWrapper.shared
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
        sdkWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }

    private func dissmissViewWithDelay() {
        let deadlineTime = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.paymentProcessingView?.dismissView()
        }
    }
}

extension ClearentProcessingModalPresenter: ProcessingModalProtocol {
    public func restartProcess(processType: ProcessType) {
        sdkFeedbackProvider.delegate = self
        paymentProcessingView?.showLoadingView()
        flowFeedbackReceived?()
        switch processType {
        case .pairing:
            sdkWrapper.startPairing()
        case .payment:
            sdkWrapper.retryLastTransaction()
        case .showReaders:
            break
        }
    }

    public func startFlow() {
        switch processType {
        case .pairing:
            startPairingFlow()
        case .payment:
            startTransactionFlow()
        case .showReaders:
            showReadersList()
        }
    }
    
    public func startNewPairing() {
        startPairingFlow()
    }

    private func startTransactionFlow() {
        sdkFeedbackProvider.delegate = self
        if sdkWrapper.isReaderConnected(), let amount = amount {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        } else {
            sdkWrapper.startPairing()
        }
    }

    private func startPairingFlow() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_prepare_pairing_reader_range".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .description, object: "xsdk_prepare_pairing_reader_button".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pair)]
        let feedback = FlowFeedback(flow: .pairing, type: FlowFeedbackType.info, items: items)
        paymentProcessingView?.updateContent(with: feedback)
    }
    
    private func showReadersList() {
        guard let connectedReader = ClearentWrapperDefaults.pairedReaderInfo else { return }
        
        let items = [FlowDataItem(type: .readerInfo, object: connectedReader),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        let feedback = FlowFeedback(flow: .showReaders, type: .searchDevices, items: items)
        paymentProcessingView?.updateContent(with: feedback)
        
        sdkWrapper.searchRecentlyUsedReaders()
    }
}

extension ClearentProcessingModalPresenter: FlowDataProtocol {
    public func deviceDidDisconnect() {
        // TODO: implement method
    }

    func didFinishedPairing() {
        if processType == .pairing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // display successful pairing content
                var items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.pairingSuccessful),
                             FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                             FlowDataItem(type: .description, object: "xsdk_paired_successful".localized),
                             FlowDataItem(type: .userAction, object: FlowButtonType.done)]
                if let readerInfo = ClearentWrapper.shared.readerInfo {
                    items.insert(FlowDataItem(type: .readerInfo, object: readerInfo), at: 0)
                }
                let feedback = FlowFeedback(flow: self.processType, type: FlowFeedbackType.info, items: items)
                self.paymentProcessingView?.updateContent(with: feedback)
            }
        } else if let amount = amount {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        }
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        paymentProcessingView?.updateContent(with: feedback)
        flowFeedbackReceived?()
    }
    
    func didFinishTransaction(error: ResponseError?) {
        if (error == nil) {
            dissmissViewWithDelay()
        }
    }
}
