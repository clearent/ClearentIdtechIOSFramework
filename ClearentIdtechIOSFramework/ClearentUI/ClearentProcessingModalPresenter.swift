//
//  ClearentProcessingModalPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 29.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearentProcessingModalView: AnyObject {
    func updateContent(with feedback: FlowFeedback)
    func showLoadingView()
    func dismissViewController(isConnected: Bool)
}

protocol ProcessingModalProtocol {
    var sdkFeedbackProvider: FlowDataProvider { get set }
    func restartProcess(processType: ProcessType)
    func startFlow()
    func startPairingFlow()
    func showDetailsScreen(for reader: ReaderInfo, allReaders: [ReaderInfo], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)
    func connectTo(reader: ReaderInfo)
}

public class ClearentProcessingModalPresenter {
    private weak var modalProcessingView: ClearentProcessingModalView?
    private var amount: Double?
    private let sdkWrapper = ClearentWrapper.shared
    private let processType: ProcessType
    var sdkFeedbackProvider: FlowDataProvider

    // MARK: Init

    init(modalProcessingView: ClearentProcessingModalView, amount: Double?, processType: ProcessType) {
        self.modalProcessingView = modalProcessingView
        self.amount = amount
        self.processType = processType
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
    }

    private func dissmissViewWithDelay() {
        let deadlineTime = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.modalProcessingView?.dismissViewController(isConnected: true)
        }
    }
}

extension ClearentProcessingModalPresenter: ProcessingModalProtocol {
    func showDetailsScreen(for reader: ReaderInfo, allReaders: [ReaderInfo], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)  {
        let vc = ClearentReaderDetailsViewController(nibName: String(describing: ClearentReaderDetailsViewController.self), bundle: ClearentConstants.bundle)
        vc.detailsPresenter = ClearentReaderDetailsPresenter(currentReader: reader, allReaders: allReaders, flowDataProvider: flowDataProvider, navigationController: navigationController)
        navigationController.pushViewController(vc, animated: true)
    }

    func restartProcess(processType: ProcessType) {
        sdkFeedbackProvider.delegate = self
        modalProcessingView?.showLoadingView()
        switch processType {
        case .pairing:
            sdkWrapper.startPairing(reconnectIfPossible: true)
        case .payment:
            sdkWrapper.retryLastTransaction()
        case .showReaders:
            break
        }
    }

    func startFlow() {
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
        switch processType {
        case let .pairing(withReader: readerInfo):
            if let readerInfo = readerInfo {
                // automatically connect to this reader
                connectTo(reader: readerInfo)
            } else {
                startPairingFlow()
            }
        case .payment:
            startTransactionFlow()
        case .showReaders:
            showReadersList()
        }
    }
    
    func startPairingFlow() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_prepare_pairing_reader_range".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .description, object: "xsdk_prepare_pairing_reader_button".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pair)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    public func connectTo(reader: ReaderInfo) {
        ClearentWrapper.shared.flowType = processType
        sdkWrapper.connectTo(reader: reader)
    }
    
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

        modalProcessingView?.updateContent(with: feedback)
        sdkWrapper.searchRecentlyUsedReaders()
    }
}

extension ClearentProcessingModalPresenter: FlowDataProtocol {
    
    func deviceDidDisconnect() {}

    func didFinishedPairing() {
        if case .pairing = processType {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // display successful pairing content
                var items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.pairingSuccessful),
                             FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                             FlowDataItem(type: .description, object: "xsdk_paired_successful".localized),
                             FlowDataItem(type: .userAction, object: FlowButtonType.done)]
                if let readerInfo = ClearentWrapperDefaults.pairedReaderInfo {
                    items.insert(FlowDataItem(type: .readerInfo, object: readerInfo), at: 0)
                }
                let feedback = FlowFeedback(flow: self.processType, type: FlowFeedbackType.info, items: items)
                self.modalProcessingView?.updateContent(with: feedback)
                
            }
        } else if let amount = amount {
            sdkWrapper.startTransactionWithAmount(amount: String(amount))
        }
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        modalProcessingView?.updateContent(with: feedback)
    }

    func didFinishTransaction(error: ResponseError?) {
        if error == nil {
            dissmissViewWithDelay()
        }
    }
}
