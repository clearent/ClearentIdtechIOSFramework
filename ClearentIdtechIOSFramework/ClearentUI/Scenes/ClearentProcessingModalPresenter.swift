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
    func displayOfflineModeConfirmationMessage(for flowType: FlowButtonType)
    func startPairNewReaderFlow()
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
    func handleOfflineModeCancelOption()
    func handleOfflineModeConfirmationOption()
    func offlineTransactionsWarningText() -> String
}

class ClearentProcessingModalPresenter {
    
    // MARK: - Properties

    private weak var modalProcessingView: ClearentProcessingModalView?
    private var temporaryReaderName: String?
    private let sdkWrapper = ClearentWrapper.shared
    private var tipsScreenWasNotShown = true
    // defines the process type set when the SDK UI starts
    private var processType: ProcessType
    private var useCardReaderPaymentMethod: Bool {
        sdkWrapper.cardReaderPaymentIsPreffered && sdkWrapper.useManualPaymentAsFallback == nil
    }
    
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
    
    func offlineTransactionsWarningText() -> String {
        return String(format: ClearentConstants.Localized.OfflineMode.offlineModeEnabled, String(ClearentUIManager.shared.allUnprocessedOfflineTransactionsCount()))
    }
    
    func handleOfflineModeCancelOption() {
        sdkWrapper.isNewPaymentProcess = false
        restartProcess(newPair: false)
    }
    
    func handleOfflineModeConfirmationOption() {
        sdkWrapper.isNewPaymentProcess = false
        
        if let isReaderEncrypted = sdkWrapper.isReaderEncrypted(), useCardReaderPaymentMethod {
            if !isReaderEncrypted {
                sdkFeedbackProvider.showEncryptionWarning()
            } else {
                sdkFeedbackProvider.displayOfflineModeWarningMessage()
            }
        } else {
            sdkFeedbackProvider.displayOfflineModeWarningMessage()
        }
    }
    
    func enableDoneButtonForInput(enabled: Bool) {
        modalProcessingView?.updateUserActionButtonState(enabled: enabled)
    }
    
    func restartProcess(newPair: Bool) {
        guard let processType = sdkWrapper.flowType?.processType, let flowFeedbackType = sdkWrapper.flowType?.flowFeedbackType else { return }
        sdkFeedbackProvider.delegate = self
        modalProcessingView?.showLoadingView()
        startProcess(isRestart: true, processType: processType, flowFeedbackType: flowFeedbackType, newPair: newPair)
    }
    
    func startFlow() {
        startProcess(isRestart: false, processType: processType)
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
            if sdkWrapper.flowType?.flowFeedbackType == .pairingDoneInfo {
                showReaderNameOption()
            } else {
                if sdkWrapper.flowType?.flowFeedbackType == .renameReaderDone {
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
            ClearentUIManager.shared.isOfflineModeConfirmed = false
        case .cancel:
            sdkWrapper.isNewPaymentProcess = true
            ClearentUIManager.shared.isOfflineModeConfirmed = false
            modalProcessingView?.dismissViewController(result: .failure(.init(type: .cancelledByUser)))
        case .retry, .pair:
            restartProcess(newPair: false)
        case .pairInFlow:
            restartProcess(newPair: true)
        case .pairNewReader:
            modalProcessingView?.startPairNewReaderFlow()
        case .settings:
            let url = URL(string: UIApplication.openSettingsURLString + Bundle.main.bundleIdentifier!)!
            UIApplication.shared.open(url)
        case .addReaderName:
            modalProcessingView?.positionViewOnTop(flag: true)
            showRenameReader()
        case .transactionWithTip, .transactionWithoutTip:
            useCardReaderPaymentMethod ? startCardReaderTransaction() : startManualEntryTransaction()
        case .manuallyEnterCardInfo:
            startManualEntryTransaction()
        case .acceptOfflineMode:
            modalProcessingView?.displayOfflineModeConfirmationMessage(for: .acceptOfflineMode)
        case .denyOfflineMode:
            modalProcessingView?.displayOfflineModeConfirmationMessage(for: .denyOfflineMode)
        case .confirmOfflineModeWarningMessage:
            ClearentUIManager.shared.isOfflineModeConfirmed = true
            sdkFeedbackProvider.delegate = self
            modalProcessingView?.showLoadingView()
            
            useCardReaderPaymentMethod ? startCardReaderTransaction() : startManualEntryTransaction()
            
        }
    }
    
    func handleSignature(with image: UIImage) {
        modalProcessingView?.showLoadingView()
        
        sdkWrapper.sendSignatureWithImage(image: image) { [weak self] (response, error) in
            if let error = error, error.type.isMissingKeyError {
                self?.modalProcessingView?.dismissViewController(result: .failure(error))
            } else {
                self?.sdkFeedbackProvider.didFinishedSignatureUploadWith(response: response, error: error)
            }
        }
    }

    func sendManualEntryTransaction(with dataSource: ClearentPaymentDataSource) {
        guard let amount = amountWithoutTip?.stringFormattedWithTwoDecimals,
              let cardNo = dataSource.valueForType(.creditCardNo)?.replacingOccurrences(of: ClearentPaymentItemType.creditCardNo.separator, with: ""),
              let date = dataSource.valueForType(.date)?.replacingOccurrences(of: ClearentPaymentItemType.date.separator, with: ""),
              let csc = dataSource.valueForType(.securityCode) else { return }

        let billingZipCode = dataSource.valueForType(.billingZipCode)?.replacingOccurrences(of: ClearentPaymentItemType.billingZipCode.separator, with: "")
        let billingInfo = ClientInformation(firstName: dataSource.valueForType(.cardholderFirstName),
                                            lastName: dataSource.valueForType(.cardholderLastName),
                                            company: dataSource.valueForType(.companyName),
                                            zip: billingZipCode)
        
        let shipToZipCode = dataSource.valueForType(.shippingZipCode)?.replacingOccurrences(of: ClearentPaymentItemType.shippingZipCode.separator, with: "")
        let shippingInfo = ClientInformation(zip: shipToZipCode)
        
        var totalAmountWithoutServiceFee = amountWithoutTip ?? 0.0
        totalAmountWithoutServiceFee += tip ?? 0.0
        let calculatedServiceFee = ClearentWrapper.shared.serviceFeeAmount(amount: totalAmountWithoutServiceFee)
        
        let saleEntity = SaleEntity(amount: amount,
                                    tipAmount: tip?.stringFormattedWithTwoDecimals,
                                    billing: billingInfo,
                                    shipping: shippingInfo,
                                    card: cardNo,
                                    csc: csc,
                                    customerID: dataSource.valueForType(.customerId),
                                    invoice: dataSource.valueForType(.invoiceNo),
                                    orderID: dataSource.valueForType(.orderNo),
                                    expirationDateMMYY: date,
                                    serviceFeeAmount: calculatedServiceFee?.stringFormattedWithTwoDecimals)

        startTransaction(saleEntity: saleEntity, isManualTransaction: true)
    }

    func resendSignature() {
        modalProcessingView?.showLoadingView()
        
        sdkWrapper.resendSignature { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            strongSelf.sdkFeedbackProvider.didFinishedSignatureUploadWith(response: response, error: error)
        }
    }

    // MARK: Private
    
    private func startProcess(isRestart: Bool, processType: ProcessType, flowFeedbackType: FlowFeedbackType? = nil, newPair: Bool = false) {
        sdkWrapper.flowType = (processType, flowFeedbackType)
        
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
        case .showSettings:
            break;
        }
    }
    
    private func startTransactionFlow() {
        sdkFeedbackProvider.delegate = self

        if useCardReaderPaymentMethod, !sdkWrapper.isReaderConnected() {
            shouldStartTransactionAfterRenameReader = ClearentWrapperDefaults.pairedReaderInfo == nil
            sdkWrapper.startPairing(reconnectIfPossible: true)
        } else {
            startTipFlow()
        }
    }
    
    private func startTipFlow() {
        sdkWrapper.fetchTipSetting { [weak self] error in
            if let error = error, error.type.isMissingKeyError {
                self?.modalProcessingView?.dismissViewController(result: .failure(error))
            }
            guard let strongSelf = self else { return }            
            let showTipsScreen = strongSelf.sdkWrapper.tipEnabled && strongSelf.tipsScreenWasNotShown

            if showTipsScreen {
                strongSelf.sdkFeedbackProvider.startTipTransaction(amountWithoutTip: strongSelf.amountWithoutTip ?? 0)
                strongSelf.tipsScreenWasNotShown = false
            }
        }
    }

    private func startCardReaderTransaction() {
        if shouldDisplayOfflineModeWarningMessage() {
            sdkFeedbackProvider.displayOfflineModeWarningMessage()
        } else {
            if let amountFormatted = amountWithoutTip?.stringFormattedWithTwoDecimals {
                let saleEntity: SaleEntity

                var totalAmountWithoutServiceFee = amountWithoutTip ?? 0.0
                totalAmountWithoutServiceFee += tip ?? 0.0
                let calculatedServiceFee = ClearentWrapper.shared.serviceFeeAmount(amount: totalAmountWithoutServiceFee)
                
                saleEntity = SaleEntity(amount: amountFormatted, tipAmount: tip?.stringFormattedWithTwoDecimals, serviceFeeAmount: calculatedServiceFee?.stringFormattedWithTwoDecimals)
                
                startTransaction(saleEntity: saleEntity, isManualTransaction: false)
            }
        }
    }
    
    private func startManualEntryTransaction() {
        if shouldDisplayOfflineModeWarningMessage() {
            sdkFeedbackProvider.displayOfflineModeWarningMessage()
        } else {
            let items = [FlowDataItem(type: .manualEntry, object: nil)]
            let feedback = FlowFeedback(flow: .payment, type: FlowFeedbackType.info, items: items)
            modalProcessingView?.updateContent(with: feedback)
        }
    }
    
    private func shouldDisplayOfflineModeWarningMessage() -> Bool {
        if ClearentWrapperDefaults.enableOfflineMode, !ClearentWrapperDefaults.enableOfflinePromptMode, !ClearentUIManager.shared.isOfflineModeConfirmed {
            return true
        }
        return false
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
        let feedback = FlowFeedback(flow: .payment, type: .signature, items: items)
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

    private func startTransaction(saleEntity: SaleEntity, isManualTransaction: Bool) {
        modalProcessingView?.showLoadingView()
        
        sdkWrapper.processTransactionOnline = (ClearentWrapperDefaults.enableOfflineMode &&  ClearentWrapperDefaults.enableOfflinePromptMode && sdkWrapper.isInternetOn) || (!ClearentWrapperDefaults.enableOfflineMode && sdkWrapper.isInternetOn)
        
        sdkWrapper.startTransaction(with: saleEntity, isManualTransaction: isManualTransaction) { [weak self] error in
            if let error = error {
                self?.modalProcessingView?.dismissViewController(result: .failure(error))
            }
        }
    }
}

extension ClearentProcessingModalPresenter: FlowDataProtocol {
    
    func didFinishSignature() {
        successfulDissmissViewWithDelay()
        sdkWrapper.isNewPaymentProcess = true
        ClearentUIManager.shared.isOfflineModeConfirmed = false
    }
    
    func didFinishTransaction() {
        if ClearentUIManager.configuration.signatureEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showSignatureScreen()
            }
        } else {
            successfulDissmissViewWithDelay()
            sdkWrapper.isNewPaymentProcess = true
            ClearentUIManager.shared.isOfflineModeConfirmed = false
        }
    }
    
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
            startTransactionFlow()
        }
    }

    func didReceiveFlowFeedback(feedback: FlowFeedback) {
        ClearentApplicationOrientation.customOrientationMaskClosure?(UIInterfaceOrientationMask.portrait)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        modalProcessingView?.updateContent(with: feedback)
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
