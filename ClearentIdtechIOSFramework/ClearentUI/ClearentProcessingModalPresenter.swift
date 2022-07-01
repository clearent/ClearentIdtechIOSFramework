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
    func addLoadingViewToCurrentContent()
    func showLoadingView()
    func dismissViewController(isConnected: Bool, customName: String?)
    func positionViewOnTop(flag: Bool)
}

protocol ProcessingModalProtocol {
    var editableReader: ReaderInfo? { get set }
    var processType: ProcessType { get set }
    var amountWithoutTip: Double? { get set }
    var tip: Double? { get set }
    var sdkFeedbackProvider: FlowDataProvider { get set }
    var selectedReaderFromReadersList: ReaderItem? { get set }
    func handleUserAction(userAction: FlowButtonType, processType: ProcessType, flowFeedbackType: FlowFeedbackType)
    func restartProcess(processType: ProcessType, newPair: Bool)
    func startFlow()
    func startPairingFlow()
    func showDetailsScreen(for reader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)
    func connectTo(reader: ReaderInfo)
    func updateTemporaryReaderName(name: String?)
    func fetchTipSetting(completion: @escaping () -> Void)
    func handleSignature(with image: UIImage)
}

class ClearentProcessingModalPresenter {
    
    // MARK: - Properties
    
    private weak var modalProcessingView: ClearentProcessingModalView?
    private var temporaryReaderName: String?
    private let sdkWrapper = ClearentWrapper.shared
    private var tipsScreenWasNotShown = true
    var amountWithoutTip: Double?
    var tip: Double?
    var processType: ProcessType
    var selectedReaderFromReadersList: ReaderItem?
    var sdkFeedbackProvider: FlowDataProvider
    var editableReader: ReaderInfo?
    // MARK: Init

    init(modalProcessingView: ClearentProcessingModalView, amount: Double?, processType: ProcessType) {
        self.modalProcessingView = modalProcessingView
        self.amountWithoutTip = amount
        self.processType = processType
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
    }

    private func dissmissViewWithDelay() {
        let deadlineTime = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.modalProcessingView?.dismissViewController(isConnected: true, customName: ClearentWrapperDefaults.pairedReaderInfo?.customReaderName)
        }
    }
}

extension ClearentProcessingModalPresenter: ProcessingModalProtocol {

    func restartProcess(processType: ProcessType, newPair: Bool) {
        ClearentWrapper.shared.flowType = processType
        self.processType = processType
        sdkFeedbackProvider.delegate = self
        modalProcessingView?.showLoadingView()
        
        switch processType {
        case .renameReader:
            showRenameReader()
        case .pairing:
            sdkWrapper.startPairing(reconnectIfPossible: !newPair)
        case .payment:
            startTransactionFlow()
        case .showReaders:
            break
        }
    }
    
    func startFlow() {
        ClearentWrapper.shared.flowType = processType
        
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
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairInFlow)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    func showDetailsScreen(for reader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)  {
        let vc = ClearentReaderDetailsViewController(nibName: String(describing: ClearentReaderDetailsViewController.self), bundle: ClearentConstants.bundle)
        vc.detailsPresenter = ClearentReaderDetailsPresenter(currentReader: reader, flowDataProvider: flowDataProvider, navigationController: navigationController)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func connectTo(reader: ReaderInfo) {
        // reset sdk provider to make sure the sdkWrapper is not nil
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
        selectedReaderFromReadersList = ReaderItem(readerInfo: reader, isConnecting: true)
        sdkWrapper.connectTo(reader: reader)
    }
    
    func updateTemporaryReaderName(name: String?) {
        if (editableReader == nil) { editableReader = ClearentWrapperDefaults.pairedReaderInfo }
        temporaryReaderName = name
    }
    
    func handleUserAction(userAction: FlowButtonType, processType: ProcessType, flowFeedbackType: FlowFeedbackType) {
        switch userAction {
        case .cancel, .done, .renameReaderLater:
            if (flowFeedbackType == .pairingDoneInfo) {
                showReaderNameOption()
            } else {
                if (flowFeedbackType == .renameReaderDone) {
                    updateReaderName()
                }
                modalProcessingView?.dismissViewController(isConnected: userAction != .cancel, customName: editableReader?.customReaderName)
            }
        case .retry, .pair:
            restartProcess(processType: processType, newPair: false)
        case .pairInFlow:
            restartProcess(processType: processType, newPair: true)
        case .pairNewReader:
            modalProcessingView?.positionViewOnTop(flag: false)
            startPairingFlow()
        case .settings:
            let url = URL(string: UIApplication.openSettingsURLString + Bundle.main.bundleIdentifier!)!
            UIApplication.shared.open(url)
        case .addReaderName:
            modalProcessingView?.positionViewOnTop(flag: true)
            showRenameReader()
        case .transactionWithTip, .transactionWithoutTip:
            modalProcessingView?.showLoadingView()
            continueTransaction()
            tipsScreenWasNotShown = false
        }
    }
    
    func fetchTipSetting(completion: @escaping () -> Void) {
        sdkWrapper.fetchTipSetting(completion: completion)
    }
    
    func handleSignature(with image: UIImage) {
        modalProcessingView?.showLoadingView()
        ClearentWrapper.shared.sendSignatureWithImage(image: image)
    }

    // MARK: Private
    
    private func startTransactionFlow() {
        sdkFeedbackProvider.delegate = self
        fetchTipSetting { [weak self] in
            guard let strongSelf = self else { return }
            let showTipsScreen = (ClearentWrapper.shared.tipEnabled ?? false) && strongSelf.tipsScreenWasNotShown
            if showTipsScreen, strongSelf.sdkWrapper.isReaderConnected() {
                strongSelf.sdkFeedbackProvider.startTipTransaction(amountWithoutTip: strongSelf.amountWithoutTip ?? 0)
            } else {
                strongSelf.continueTransaction()
            }
        }
    }
    
    private func showReadersList() {
        // when the search starts the reader will be disconnected so we need to show the proper state
        var reader = ClearentWrapperDefaults.pairedReaderInfo
        reader?.isConnected = false
        let items = [FlowDataItem(type: .readerInfo, object: reader),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading)]
        let feedback = FlowFeedback(flow: .showReaders, type: .showReaders, items: items)

        modalProcessingView?.updateContent(with: feedback)
        sdkWrapper.searchRecentlyUsedReaders()
    }
    
    private func showReaderNameOption() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_add_name_to_reader".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .userAction, object: FlowButtonType.addReaderName),
                     FlowDataItem(type: .userAction, object: FlowButtonType.renameReaderLater)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func showRenameReader() {
        temporaryReaderName = nil
        let items = [FlowDataItem(type: .hint, object: "xsdk_rename_your_reader".localized),
                     FlowDataItem(type: .input, object: FlowInputType.nameInput),
                     FlowDataItem(type: .userAction, object: FlowButtonType.done)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.renameReaderDone, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func showSignatureScreen() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_signature_title".localized),
                     FlowDataItem(type: .signature, object: nil)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func updateReaderName() {
        if var reader = editableReader {
            if let newName = temporaryReaderName, newName != "" {
                reader.customReaderName = newName
            } else {
                reader.customReaderName = nil
            }
            if (ClearentWrapperDefaults.pairedReaderInfo?.readerName == reader.readerName){
                ClearentWrapperDefaults.pairedReaderInfo?.customReaderName = reader.customReaderName
            }
            sdkWrapper.removeReaderFromRecentlyUsed(reader: reader)
            sdkWrapper.addReaderToRecentlyUsed(reader: reader)
            editableReader = reader
        }
    }
    
    private func continueTransaction() {
        if sdkWrapper.isReaderConnected(), let amount = amountWithoutTip {
            let formattedAmount = String(ClearentMoneyFormatter.formattedText(from: amount).double)
            let formattedTip = String(ClearentMoneyFormatter.formattedText(from: tip ?? 0).double)
            sdkWrapper.startTransaction(with: formattedAmount, and: formattedTip)
        } else {
            sdkWrapper.startPairing(reconnectIfPossible: true)
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
        } else {
            if (ClearentWrapper.shared.tipEnabled ?? false), tipsScreenWasNotShown {
                self.sdkFeedbackProvider.startTipTransaction(amountWithoutTip: amountWithoutTip ?? 0)
            } else {
                continueTransaction()
            }
        }
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        modalProcessingView?.updateContent(with: feedback)
    }

    func didFinishTransaction(error: ResponseError?) {
        if error == nil {
            if (ClearentUIManager.shared.signatureEnabled) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showSignatureScreen()
                }
            } else {
                dissmissViewWithDelay()
            }
        }
    }
    
    func didFinishSignature() {
        dissmissViewWithDelay()
    }

    func didBeginContinuousSearching() {
        modalProcessingView?.addLoadingViewToCurrentContent()
    }
}
