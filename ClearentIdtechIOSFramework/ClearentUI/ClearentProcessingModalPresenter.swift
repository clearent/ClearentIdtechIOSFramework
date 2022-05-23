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
    func dismissViewController()
}

public protocol ProcessingModalProtocol {
    func restartProcess(processType: ProcessType)
    func startFlow()
    func startPairingFlow()
    func connectTo(reader: ReaderInfo)
    func getSelectedReaderFromReadersList() -> ReaderItem?
    func setSelectedReaderFromReadersList(_ readerItem: ReaderItem?)
}

public class ClearentProcessingModalPresenter {
    private weak var paymentProcessingView: ClearentProcessingModalView?
    private var amount: Double?
    private let sdkWrapper = ClearentWrapper.shared
    private var sdkFeedbackProvider: FlowDataProvider
    private let processType: ProcessType
    private var selectedReaderFromReadersList: ReaderItem?

    // MARK: Init

    public init(paymentProcessingView: ClearentProcessingModalView, amount: Double?, processType: ProcessType) {
        self.paymentProcessingView = paymentProcessingView
        self.amount = amount
        self.processType = processType
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
    }

    private func dissmissViewWithDelay() {
        let deadlineTime = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.paymentProcessingView?.dismissViewController()
        }
    }
}

extension ClearentProcessingModalPresenter: ProcessingModalProtocol {
    public func restartProcess(processType: ProcessType) {
        sdkFeedbackProvider.delegate = self
        paymentProcessingView?.showLoadingView()
        switch processType {
        case .pairing:
            sdkWrapper.startPairing(reconnectIfPossible: true)
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
    
    public func startPairingFlow() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_prepare_pairing_reader_range".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .description, object: "xsdk_prepare_pairing_reader_button".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pair)]
        let feedback = FlowFeedback(flow: .pairing, type: FlowFeedbackType.info, items: items)
        paymentProcessingView?.updateContent(with: feedback)
    }
    
    public func connectTo(reader: ReaderInfo) {
        selectedReaderFromReadersList = ReaderItem(readerInfo: reader, isConnecting: true)
        ClearentWrapper.shared.flowType = processType
        sdkWrapper.connectTo(reader: reader)
    }
    
    public func getSelectedReaderFromReadersList() -> ReaderItem? {
        selectedReaderFromReadersList ?? nil
    }
    
    public func setSelectedReaderFromReadersList(_ readerItem: ReaderItem?) {
        selectedReaderFromReadersList = readerItem
    }
    
    // MARK: Private
    
    private func startTransactionFlow() {
        sdkFeedbackProvider.delegate = self
        if sdkWrapper.isReaderConnected(), let amount = amount {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        } else {
            sdkWrapper.startPairing(reconnectIfPossible: true)
        }
    }
    
    private func showReadersList() {
        guard let connectedReader = ClearentWrapperDefaults.pairedReaderInfo else { return }
        
        let items = [FlowDataItem(type: .readerInfo, object: connectedReader),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        let feedback = FlowFeedback(flow: .showReaders, type: .showReaders, items: items)
        
        paymentProcessingView?.updateContent(with: feedback)
        sdkWrapper.searchRecentlyUsedReaders()
    }
}

extension ClearentProcessingModalPresenter: FlowDataProtocol {
    
    public func deviceDidDisconnect() {
        ClearentUIManager.shared.readerInfoReceived?(nil)
    }

    func didFinishedPairing() {
        if processType == .pairing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // display successful pairing content
                var items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.pairingSuccessful),
                             FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                             FlowDataItem(type: .description, object: "xsdk_paired_successful".localized),
                             FlowDataItem(type: .userAction, object: FlowButtonType.done)]
                if let readerInfo = ClearentWrapperDefaults.pairedReaderInfo {
                    items.insert(FlowDataItem(type: .readerInfo, object: readerInfo), at: 0)
                }
                let feedback = FlowFeedback(flow: self.processType,
                                            type: FlowFeedbackType.info,
                                            items: items)
                self.paymentProcessingView?.updateContent(with: feedback)
            }
        } else if let amount = amount {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        }
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        paymentProcessingView?.updateContent(with: feedback)
        ClearentUIManager.shared.readerInfoReceived?(ClearentWrapperDefaults.pairedReaderInfo)
    }

    func didFinishTransaction(error: ResponseError?) {
        if error == nil {
            dissmissViewWithDelay()
        }
    }
}
