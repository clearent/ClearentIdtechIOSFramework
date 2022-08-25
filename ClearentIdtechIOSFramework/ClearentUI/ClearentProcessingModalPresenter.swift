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
    func dismissViewController(result: CompletionResult)
    func positionViewOnTop(flag: Bool)
    func updateUserActionButtonState(enabled: Bool)
}

protocol ProcessingModalProtocol {
    var editableReader: ReaderInfo? { get set }
    var amountWithoutTip: Double? { get set }
    var tip: Double? { get set }
    var sdkFeedbackProvider: FlowDataProvider { get set }
    var selectedReaderFromReadersList: ReaderItem? { get set }
    func handleUserAction(userAction: FlowButtonType)
    func restartProcess(newPair: Bool)
    func startFlow()
    func startPairingFlow()
    func showDetailsScreen(for reader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)
    func connectTo(reader: ReaderInfo)
    func updateTemporaryReaderName(name: String?)
    func enableDoneButtonForInput(enabled: Bool)
    func handleSignature(with image: UIImage)
    func sendManualEntryTransaction(with dataSource: ClearentPaymentDataSource)
}

class ClearentProcessingModalPresenter {
    // MARK: - Properties

    private weak var modalProcessingView: ClearentProcessingModalView?
    private var temporaryReaderName: String?
    private let sdkWrapper = ClearentWrapper.shared
    private var tipsScreenWasNotShown = true
    // defines the process type set when the SDK UI starts
    private var processType: ProcessType
    var amountWithoutTip: Double?
    var tip: Double?
    var selectedReaderFromReadersList: ReaderItem?
    var sdkFeedbackProvider: FlowDataProvider
    var editableReader: ReaderInfo?
    var shouldStartTransactionAfterRenameReader = false

    // MARK: Init

    init(modalProcessingView: ClearentProcessingModalView, amount: Double?, processType: ProcessType) {
        self.modalProcessingView = modalProcessingView
        amountWithoutTip = amount
        self.processType = processType
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
    }

    private func successfulDissmissViewWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            let result = CompletionResult.success(ClearentWrapperDefaults.pairedReaderInfo?.customReaderName)
            self?.modalProcessingView?.dismissViewController(result: result)
        }
    }
}

extension ClearentProcessingModalPresenter: ProcessingModalProtocol {
    func enableDoneButtonForInput(enabled: Bool) {
        modalProcessingView?.updateUserActionButtonState(enabled: enabled)
    }
    
    func restartProcess(newPair: Bool) {
        guard let processType = ClearentWrapper.shared.flowType?.processType, let flowFeedbackType = ClearentWrapper.shared.flowType?.flowFeedbackType else { return }
        sdkFeedbackProvider.delegate = self
        modalProcessingView?.showLoadingView()
        startProcess(isRestart: true, processType: processType, flowFeedbackType: flowFeedbackType, newPair: newPair)
    }
    
    func startFlow() {
        startProcess(isRestart: false, processType: processType)
    }
    
    private func startProcess(isRestart: Bool, processType: ProcessType, flowFeedbackType: FlowFeedbackType? = nil, newPair: Bool = false) {
        ClearentWrapper.shared.flowType = (processType, flowFeedbackType)
        
        switch processType {
        case let .pairing(withReader: readerInfo):
            if isRestart {
                sdkWrapper.startPairing(reconnectIfPossible: !newPair)
            } else if let readerInfo = readerInfo {
                // automatically connect to this reader
                connectTo(reader: readerInfo)
            } else {
                startPairingFlow()
            }
        case .payment:
            switch flowFeedbackType {
            case .signature:
                showSignatureScreen()
            case .signatureError:
                resendSignature()
            default:
                startTransactionFlow()
            }
        case .showReaders:
            if isRestart { break }
            showReadersList()
        case .renameReader:
            showRenameReader()
        }
    }

    func startPairingFlow() {
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.Pairing.readerRange),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .description, object: ClearentConstants.Localized.Pairing.readerButton),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairInFlow)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }

    func showDetailsScreen(for reader: ReaderItem, allReaders _: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController) {
        let vc = ClearentReaderDetailsViewController(nibName: String(describing: ClearentReaderDetailsViewController.self), bundle: ClearentConstants.bundle)
        vc.detailsPresenter = ClearentReaderDetailsPresenter(currentReader: reader, flowDataProvider: flowDataProvider, navigationController: navigationController, delegate: self)
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
        if editableReader == nil { editableReader = ClearentWrapperDefaults.pairedReaderInfo }
        temporaryReaderName = name
    }
    
    func handleUserAction(userAction: FlowButtonType) {
        switch userAction {
        case .done, .renameReaderLater, .skipSignature:
            if ClearentWrapper.shared.flowType?.flowFeedbackType == .pairingDoneInfo {
                showReaderNameOption()
            } else {
                if ClearentWrapper.shared.flowType?.flowFeedbackType == .renameReaderDone {
                    updateReaderName()
                }

                if shouldStartTransactionAfterRenameReader {
                    shouldStartTransactionAfterRenameReader = false
                    startTipFlow()
                    modalProcessingView?.positionViewOnTop(flag: false)
                } else {
                    modalProcessingView?.dismissViewController(result: .success(editableReader?.customReaderName))
                }
            }
        case .cancel:
            modalProcessingView?.dismissViewController(result: .failure(.cancelledByUser))
        case .retry, .pair:
            restartProcess(newPair: false)
        case .pairInFlow:
            restartProcess(newPair: true)
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
            if sdkWrapper.useCardReaderPaymentMethod {
                startCardReaderTransaction()
            } else {
                startManualEntryTransaction()
            }
        case .manuallyEnterCardInfo:
            startManualEntryTransaction()
        }
    }
    
    func handleSignature(with image: UIImage) {
        modalProcessingView?.showLoadingView()
        do {
            try sdkWrapper.sendSignatureWithImage(image: image)
        } catch {
            if let error = error as? ClearentResult {
                modalProcessingView?.dismissViewController(result: .failure(error))
            }
        }
    }

    func sendManualEntryTransaction(with dataSource: ClearentPaymentDataSource) {
        guard let amount = amountWithoutTip?.stringFormattedWithTwoDecimals,
              let cardNo = dataSource.valueForType(.creditCardNo)?.replacingOccurrences(of: ClearentPaymentItemType.creditCardNo.separator, with: ""),
              let date = dataSource.valueForType(.date)?.replacingOccurrences(of: ClearentPaymentItemType.date.separator, with: ""),
              let csc = dataSource.valueForType(.securityCode) else { return }

        let cardInfo = ManualEntryCardInfo(card: cardNo, expirationDateMMYY: date, csc: csc)
        
        let billingZipCode = dataSource.valueForType(.billingZipCode)?.replacingOccurrences(of: ClearentPaymentItemType.billingZipCode.separator, with: "")
        let billingInfo = ClientInformation(firstName: dataSource.valueForType(.cardholderFirstName),
                                            lastName: dataSource.valueForType(.cardholderLastName),
                                            company: dataSource.valueForType(.companyName),
                                            zip: billingZipCode)
        
        let shipToZipCode = dataSource.valueForType(.shippingZipCode)?.replacingOccurrences(of: ClearentPaymentItemType.shippingZipCode.separator, with: "")
        let shippingInfo = ClientInformation(zip: shipToZipCode)
        let saleEntity = SaleEntity(amount: amount,
                                    tipAmount: tip?.stringFormattedWithTwoDecimals,
                                    billing: billingInfo,
                                    shipping: shippingInfo,
                                    customerID: dataSource.valueForType(.customerId),
                                    invoice: dataSource.valueForType(.invoiceNo),
                                    orderID: dataSource.valueForType(.orderNo))

        startTransaction(saleEntity: saleEntity, manualEntryCardInfo: cardInfo)
    }

    func resendSignature() {
        modalProcessingView?.showLoadingView()
        
        ClearentWrapper.shared.resendSignature { [weak self] result in
            guard let strongSelf = self else { return }
            
            if case .failure(_) = result {
                strongSelf.modalProcessingView?.dismissViewController(result: result)
            }
        }
    }

    // MARK: Private
    
    private func startTransactionFlow() {
        sdkFeedbackProvider.delegate = self

        if sdkWrapper.useCardReaderPaymentMethod, !sdkWrapper.isReaderConnected() {
            shouldStartTransactionAfterRenameReader = ClearentWrapperDefaults.pairedReaderInfo == nil
            sdkWrapper.startPairing(reconnectIfPossible: true)
        } else {
            startTipFlow()
        }
    }
    
    private func startTipFlow() {
        sdkWrapper.fetchTipSetting { [weak self] in
            guard let strongSelf = self else { return }            
            let showTipsScreen = ClearentWrapper.shared.tipEnabled && strongSelf.tipsScreenWasNotShown

            if showTipsScreen {
                strongSelf.sdkFeedbackProvider.startTipTransaction(amountWithoutTip: strongSelf.amountWithoutTip ?? 0)
                strongSelf.tipsScreenWasNotShown = false
            } else {
                if strongSelf.sdkWrapper.useCardReaderPaymentMethod {
                    strongSelf.startCardReaderTransaction()
                } else {
                    strongSelf.startManualEntryTransaction()
                }
            }
        }
    }

    private func startCardReaderTransaction() {
        if let amountFormatted = amountWithoutTip?.stringFormattedWithTwoDecimals {
            let saleEntity = SaleEntity(amount: amountFormatted, tipAmount: tip?.stringFormattedWithTwoDecimals)
            startTransaction(saleEntity: saleEntity)
        }
    }
    
    private func startManualEntryTransaction() {
        let items = [FlowDataItem(type: .manualEntry, object: nil)]
        let feedback = FlowFeedback(flow: .payment, type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
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
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.Pairing.addReaderName),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                     FlowDataItem(type: .userAction, object: FlowButtonType.addReaderName),
                     FlowDataItem(type: .userAction, object: FlowButtonType.renameReaderLater)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func showRenameReader() {
        temporaryReaderName = nil
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.Pairing.renameReader),
                     FlowDataItem(type: .input, object: FlowInputType.nameInput),
                     FlowDataItem(type: .userAction, object: FlowButtonType.done)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.renameReaderDone, items: items)
        modalProcessingView?.updateContent(with: feedback)
        modalProcessingView?.updateUserActionButtonState(enabled: editableReader?.customReaderName != nil)
    }
    
    private func showSignatureScreen() {
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.Signature.title),
                     FlowDataItem(type: .signature, object: nil)]
        let feedback = FlowFeedback(flow: .pairing(), type: .signature, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func updateReaderName() {
        if var reader = editableReader {
            if let newName = temporaryReaderName, newName != "" {
                reader.customReaderName = newName
            } else {
                reader.customReaderName = nil
            }
            if ClearentWrapperDefaults.pairedReaderInfo?.readerName == reader.readerName {
                ClearentWrapperDefaults.pairedReaderInfo?.customReaderName = reader.customReaderName
            }
            sdkWrapper.removeReaderFromRecentlyUsed(reader: reader)
            sdkWrapper.addReaderToRecentlyUsed(reader: reader)
            editableReader = reader
        }
    }

    private func startTransaction(saleEntity: SaleEntity, manualEntryCardInfo: ManualEntryCardInfo? = nil) {
        modalProcessingView?.showLoadingView()
        
        do {
            try sdkWrapper.startTransaction(with: saleEntity, manualEntryCardInfo: manualEntryCardInfo)
        } catch {
            if let error = error as? ClearentResult {
                modalProcessingView?.dismissViewController(result: .failure(error))
            }
        }
    }
}

extension ClearentProcessingModalPresenter: FlowDataProtocol {
    func deviceDidDisconnect() {}

    func didFinishedPairing() {
        if [.pairing(), .showReaders].contains(processType) || shouldStartTransactionAfterRenameReader == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                // display successful pairing content
                var items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.pairingSuccessful),
                             FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                             FlowDataItem(type: .description, object: ClearentConstants.Localized.Pairing.readerSuccessfulPaired),
                             FlowDataItem(type: .userAction, object: FlowButtonType.done)]
                if let readerInfo = ClearentWrapperDefaults.pairedReaderInfo {
                    items.insert(FlowDataItem(type: .readerInfo, object: readerInfo), at: 0)
                }
                
                // Only show the transaction flow after pairing if there is a new pair
                if let processType = self?.processType {
                    let feedback = FlowFeedback(flow: processType, type: FlowFeedbackType.pairingDoneInfo, items: items)
                    self?.modalProcessingView?.updateContent(with: feedback)
                }
            }
        } else {
            startTipFlow()
        }
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        ClearentApplicationOrientation.customOrientationMaskClosure?(UIInterfaceOrientationMask.portrait)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        modalProcessingView?.updateContent(with: feedback)
    }

    func didFinishTransaction(error: ResponseError?) {
        if error == nil {
            if ClearentUIManager.shared.signatureEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showSignatureScreen()
                }
            } else {
                successfulDissmissViewWithDelay()
            }
        }
    }
    
    func didFinishSignature() {
        successfulDissmissViewWithDelay()
    }

    func didBeginContinuousSearching() {
        modalProcessingView?.addLoadingViewToCurrentContent()
    }
}

extension ClearentProcessingModalPresenter: ClearentReaderDetailsDismissProtocol {
    func shutDown(userAction: FlowButtonType) {
        handleUserAction(userAction: userAction)
    }
}
