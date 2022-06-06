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
    var selectedReaderFromReadersList: ReaderItem? { get set }
    func restartProcess(processType: ProcessType)
    func startFlow()
    func startPairingFlow()
    func showReaderNameOption()
    func showRenameReader()
    func showDetailsScreen(for reader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)
    func connectTo(reader: ReaderInfo)
    func updateTemporaryReaderName(name: String?)
    func updateReaderName()
}

class ClearentProcessingModalPresenter {
    private weak var modalProcessingView: ClearentProcessingModalView?
    private var amount: Double?
    private var temporaryReaderName: String?
    private let sdkWrapper = ClearentWrapper.shared
    private let processType: ProcessType
    var selectedReaderFromReadersList: ReaderItem?
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
    func showDetailsScreen(for reader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)  {
        let vc = ClearentReaderDetailsViewController(nibName: String(describing: ClearentReaderDetailsViewController.self), bundle: ClearentConstants.bundle)
        vc.detailsPresenter = ClearentReaderDetailsPresenter(currentReader: reader, allReaders: allReaders, flowDataProvider: flowDataProvider, navigationController: navigationController)
        navigationController.pushViewController(vc, animated: true)
    }

    func restartProcess(processType: ProcessType) {
        sdkFeedbackProvider.delegate = self
        modalProcessingView?.showLoadingView()
        switch processType {
        case .renameReader:
            showRenameReader()
        case .pairing:
            sdkWrapper.startPairing(reconnectIfPossible: true)
        case .payment:
            sdkWrapper.retryLastTransaction()
        case .showReaders:
            break
        }
    }

    func startFlow() {
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
        case .renameReader:
            showRenameReader()
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
    
    func connectTo(reader: ReaderInfo) {
        // reset sdk provider to make sure the sdkWrapper is not nil
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
        selectedReaderFromReadersList = ReaderItem(readerInfo: reader, isConnecting: true)
        ClearentWrapper.shared.flowType = processType
        sdkWrapper.connectTo(reader: reader)
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
        let items = [FlowDataItem(type: .readerInfo, object: ClearentWrapperDefaults.pairedReaderInfo),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        let feedback = FlowFeedback(flow: .showReaders, type: .showReaders, items: items)

        modalProcessingView?.updateContent(with: feedback)
        sdkWrapper.searchRecentlyUsedReaders()
    }
    
    func showReaderNameOption() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_add_name_to_reader".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .userAction, object: FlowButtonType.addReaderName),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    func showRenameReader() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_rename_your_reader".localized),
                     FlowDataItem(type: .input, object: FlowInputType.nameInput),
                     FlowDataItem(type: .userAction, object: FlowButtonType.done)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.renameReaderDone, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    func updateTemporaryReaderName(name: String?) {
        temporaryReaderName = name
    }
    
    func updateReaderName() {
        if var reader = ClearentWrapperDefaults.pairedReaderInfo {
            if let newName = temporaryReaderName, newName != "" {
                reader.customReaderName = newName
            } else {
                reader.customReaderName = temporaryReaderName
            }
            ClearentWrapperDefaults.pairedReaderInfo = reader
            sdkWrapper.addReaderToRecentlyUsed(reader: reader)
        }
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
                let feedback = FlowFeedback(flow: self.processType, type: FlowFeedbackType.pairingDoneInfo, items: items)
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
