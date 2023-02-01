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
    func startPairNewReaderFlow()
}

protocol ProcessingModalProtocol {
    var editableReader: ReaderInfo? { get set }
    var paymentInfo: PaymentInfo? { get set }
    var tip: Double? { get set }
    var amountWithTip: String? { get }
    var amountWithTipAndServiceFee: String? { get }
    var sdkFeedbackProvider: FlowDataProvider { get set }
    var selectedReaderFromReadersList: ReaderItem? { get set }
    var useCardReaderPaymentMethod: Bool { get }
    func handleUserAction(userAction: FlowButtonType)
    func restartProcess(newPair: Bool)
    func startFlow()
    func startPairingFlow()
    func showDetailsScreen(for reader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, on navigationController: UINavigationController)
    func connectTo(reader: ReaderInfo)
    func updateTemporaryReaderName(name: String?)
    func enableDoneButtonForInput(enabled: Bool)
    func handleSignature(with image: UIImage)
    func handleEmailReceipt(with emailAddress: String)
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
    private var serviceFeeScreenWasNotShown = true
    
    // defines the process type set when the SDK UI starts
    private var processType: ProcessType
    
    var useCardReaderPaymentMethod: Bool { ClearentWrapper.shared.useCardReaderPaymentMethod }
    var paymentInfo: PaymentInfo?
    var tip: Double?
    var amountWithTip: String? {
        guard let amountWithoutTip = paymentInfo?.amount else { return nil }
        let amountWithTip = amountWithoutTip + (tip ?? 0)
        return ClearentMoneyFormatter.formattedWithSymbol(from: amountWithTip)
    }
    var amountWithTipAndServiceFee: String? {
        guard let amountWithoutTip = paymentInfo?.amount else { return nil }
        let amountWithTipAndServiceFee = amountWithoutTip + (tip ?? 0) + (serviceFeeAmount ?? 0)
        return ClearentMoneyFormatter.formattedWithSymbol(from: amountWithTipAndServiceFee)
    }
    
    var selectedReaderFromReadersList: ReaderItem?
    var sdkFeedbackProvider: FlowDataProvider
    var editableReader: ReaderInfo?
    var shouldStartTransactionAfterRenameReader = false

    // MARK: Init

    init(modalProcessingView: ClearentProcessingModalView, paymentInfo: PaymentInfo?, processType: ProcessType) {
        self.modalProcessingView = modalProcessingView
        self.paymentInfo = paymentInfo
        self.processType = processType
        sdkFeedbackProvider = FlowDataProvider()
        sdkFeedbackProvider.delegate = self
        
        if let auth = paymentInfo?.webAuth {
            ClearentWrapper.shared.updateWebAuth(with: auth)
        }
    }

    private func dissmissView(with delay: CGFloat = 0, error: ClearentError? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if let error = error {
                self?.modalProcessingView?.dismissViewController(result: .failure(error))
            } else {
                let result = CompletionResult.success(ClearentWrapperDefaults.pairedReaderInfo?.customReaderName)
                self?.modalProcessingView?.dismissViewController(result: result)
            }
        }
        
        // reset status
        sdkWrapper.isNewPaymentProcess = true
        ClearentUIManager.shared.isOfflineModeConfirmed = false
    }
}

extension ClearentProcessingModalPresenter: ProcessingModalProtocol {
    private var serviceFeeAmount: Double? {
        guard let amountWithoutTip = paymentInfo?.amount else { return nil }
        let totalAmountWithoutServiceFee = amountWithoutTip + (tip ?? 0.0)
        return ClearentWrapper.shared.serviceFeeAmount(amount: totalAmountWithoutServiceFee)
    }
    
    func offlineTransactionsWarningText() -> String {
        String(format: ClearentConstants.Localized.OfflineMode.offlineModeEnabled, String(ClearentUIManager.shared.allUnprocessedOfflineTransactionsCount()))
    }
    
    func handleOfflineModeCancelOption() {
        sdkWrapper.isNewPaymentProcess = false
        restartProcess(newPair: false)
    }
    
    func handleOfflineModeConfirmationOption() {
        sdkWrapper.isNewPaymentProcess = false
        sdkFeedbackProvider.displayOfflineModeWarning()
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
                    startTransactionFlow()
                    modalProcessingView?.positionViewOnTop(flag: false)
                } else if sdkWrapper.flowType?.flowFeedbackType == .signatureError {
                    showEmailReceiptOption()
                } else {
                    dissmissView()
                }
            }
            ClearentUIManager.shared.isOfflineModeConfirmed = false
        case .cancel, .emailReceiptOptionNo, .emailFormSkip:
            dissmissView(error: .init(type: .cancelledByUser))
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
            showRenameReader()
        case .transactionWithTip, .transactionWithoutTip, .transactionWithServiceFee:
            handlePaymentWithAdditionalFees()
        case .manuallyEnterCardInfo:
            ClearentWrapper.shared.useManualPaymentAsFallback = true
            handlePaymentWithAdditionalFees()
        case .acceptOfflineMode:
            handleOfflineModeConfirmationOption()
        case .denyOfflineMode:
            handleOfflineModeCancelOption()
        case .confirmOfflineModeWarningMessage:
            ClearentUIManager.shared.isOfflineModeConfirmed = true
            sdkFeedbackProvider.delegate = self
            modalProcessingView?.showLoadingView()
            handleTerminalSettings()
        case .emailReceiptOptionYes:
            showEmailFormScreen()
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
    
    func handleEmailReceipt(with emailAddress: String) {
        modalProcessingView?.showLoadingView()
        
        sdkWrapper.sendReceipt(emailAddress: emailAddress) {  [weak self] (response, error) in
            if let error = error, error.type.isMissingKeyError {
                self?.dissmissView(error: error)
            } else {
                self?.sdkFeedbackProvider.didFinishedSendingReceipt(response: response, error: error)
            }
        }
    }

    func sendManualEntryTransaction(with dataSource: ClearentPaymentDataSource) {
        guard let amount = paymentInfo?.amount.stringFormattedWithTwoDecimals,
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
        
        let saleEntity = SaleEntity(amount: amount,
                                    tipAmount: tip?.stringFormattedWithTwoDecimals,
                                    softwareType: paymentInfo?.softwareType,
                                    billing: billingInfo,
                                    shipping: shippingInfo,
                                    card: cardNo,
                                    csc: csc,
                                    customerID: dataSource.valueForType(.customerId),
                                    invoice: dataSource.valueForType(.invoiceNo),
                                    orderID: dataSource.valueForType(.orderNo),
                                    expirationDateMMYY: date,
                                    serviceFeeAmount: serviceFeeAmount?.stringFormattedWithTwoDecimals)

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
            if shouldDisplayOfflineModeWarning() {
                sdkFeedbackProvider.displayOfflineModeWarning()
            } else if shouldDisplayOfflineModeQuestion() {
                sdkFeedbackProvider.displayOfflineModeQuestion()
            } else {
                handleTerminalSettings()
            }
        }
    }
    
    private func handleTerminalSettings() {
        ClearentWrapper.shared.processTransactionOnline = (ClearentWrapperDefaults.enableOfflineMode && ClearentWrapperDefaults.enableOfflinePromptMode && ClearentWrapper.shared.isInternetOn) ||
                                                    !ClearentWrapperDefaults.enableOfflineMode ||
                                                    !ClearentUIManager.shared.isOfflineModeConfirmed
        sdkWrapper.fetchTerminalSetting { [weak self] error in
            if let error = error, error.type.isMissingKeyError {
                self?.dissmissView(error: error)
            }
            self?.handlePaymentWithAdditionalFees()
        }
    }
    
    private func handlePaymentWithAdditionalFees() {
        let showTipsScreen = sdkWrapper.tipEnabled && tipsScreenWasNotShown
        let showServiceFeeScreen = sdkWrapper.serviceFeeEnabled && serviceFeeScreenWasNotShown

        if showTipsScreen {
            sdkFeedbackProvider.startTipTransaction(amountWithoutTip: paymentInfo?.amount ?? 0)
            tipsScreenWasNotShown = false
        } else if showServiceFeeScreen, let serviceFeeProgram = ClearentWrapperDefaults.terminalSettings?.serviceFeeProgram {
            sdkFeedbackProvider.showServiceFeeScreen(for: serviceFeeProgram)
            serviceFeeScreenWasNotShown = false
        } else {
            useCardReaderPaymentMethod ? startCardReaderTransaction() : startManualEntryTransaction()
        }
    }

    private func startCardReaderTransaction() {
        // Check if the card reader is encrypted and show the proper warning message
        if let isReaderEncrypted = sdkWrapper.isReaderEncrypted(), !isReaderEncrypted, !sdkWrapper.processTransactionOnline {
            sdkWrapper.disableOfflineMode()
            sdkFeedbackProvider.showEncryptionWarning()
            return
        }

        if let amountFormatted = paymentInfo?.amount.stringFormattedWithTwoDecimals {
            let saleEntity = SaleEntity(amount: amountFormatted,
                                        tipAmount: tip?.stringFormattedWithTwoDecimals,
                                        softwareType: paymentInfo?.softwareType,
                                        billing: paymentInfo?.billing,
                                        shipping: paymentInfo?.shipping,
                                        customerID: paymentInfo?.customerID,
                                        invoice: paymentInfo?.invoice,
                                        orderID: paymentInfo?.orderID)
            startTransaction(saleEntity: saleEntity, isManualTransaction: false)
        }
    }
    
    private func startManualEntryTransaction() {
        let items = [FlowDataItem(type: .manualEntry, object: nil)]
        let feedback = FlowFeedback(flow: .payment, type: FlowFeedbackType.info, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func shouldDisplayOfflineModeWarning() -> Bool {
        ClearentWrapperDefaults.enableOfflineMode && !ClearentWrapperDefaults.enableOfflinePromptMode && !ClearentUIManager.shared.isOfflineModeConfirmed
    }
    
    private func shouldDisplayOfflineModeQuestion() -> Bool {
        sdkWrapper.isNewPaymentProcess && ClearentWrapperDefaults.enableOfflineMode &&  ClearentWrapperDefaults.enableOfflinePromptMode && !ClearentUIManager.shared.isOfflineModeConfirmed && !sdkWrapper.isInternetOn
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
        modalProcessingView?.positionViewOnTop(flag: true)
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
    
    private func showEmailReceiptOption() {
        if ClearentWrapperDefaults.enableEmailReceipt {
            let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.EmailReceipt.emailReceiptOptionTitle),
                         FlowDataItem(type: .userAction, object: FlowButtonType.emailReceiptOptionYes),
                         FlowDataItem(type: .userAction, object: FlowButtonType.emailReceiptOptionNo)]
            let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.info, items: items)
            modalProcessingView?.updateContent(with: feedback)
        } else {
           dissmissView(error: nil)
        }
    }
    
    private func showEmailFormScreen() {
        modalProcessingView?.positionViewOnTop(flag: true)
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.EmailReceipt.emailFormTitle),
                     FlowDataItem(type: .receipt, object: nil),
                     FlowDataItem(type: .userAction, object: FlowButtonType.emailFormSkip)]
        let feedback = FlowFeedback(flow: .pairing(), type: FlowFeedbackType.renameReaderDone, items: items)
        modalProcessingView?.updateContent(with: feedback)
    }
    
    private func startTransaction(saleEntity: SaleEntity, isManualTransaction: Bool) {
        modalProcessingView?.showLoadingView()
        sdkWrapper.startTransaction(with: saleEntity, isManualTransaction: isManualTransaction) { [weak self] error in
            if let error = error {
                self?.dissmissView(error: error)
            }
        }
    }
    
    private func displaySurchargeAvoidedIfNeeded(response: Transaction?) {
        guard let surchargeApplied = response?.surchargeApplied, !surchargeApplied, let amountWithTip = amountWithTip, let serviceFeeAmount = serviceFeeAmount else {
            completeTransaction()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            let description = String(format: ClearentConstants.Localized.FlowDataProvider.transactionCompletedSurchargeAvoided,
                                     ClearentMoneyFormatter.formattedWithSymbol(from: serviceFeeAmount),
                                     ClearentMoneyFormatter.formattedWithSymbol(from: amountWithTip))
            let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.transaction_completed),
                         FlowDataItem(type: .title, object: description)]
            
            let feedback = FlowDataFactory.component(with: .payment,
                                                     type: .info,
                                                     readerInfo: ClearentWrapperDefaults.lastPairedReaderInfo,
                                                     payload: items)
            self?.modalProcessingView?.updateContent(with: feedback)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.completeTransaction()
            }
        }
    }

    private func completeTransaction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if ClearentUIManager.configuration.signatureEnabled {
                self?.showSignatureScreen()
            } else {
                self?.showEmailReceiptOption()
            }
        }
    }
}

extension ClearentProcessingModalPresenter: FlowDataProtocol {
    func didFinishSignature() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showEmailReceiptOption()
        }
        sdkWrapper.isNewPaymentProcess = true
        ClearentUIManager.shared.isOfflineModeConfirmed = false
    }
    
    func didFinishHandlingReceipt() {
        dissmissView(with: 2)
    }
    
    func didFinishTransaction(response: Transaction?) {
        displaySurchargeAvoidedIfNeeded(response: response)
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
       // print("🍎 didReceiveFlowFeedback - portrait")
        let orientation: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .landscape
        ClearentApplicationOrientation.customOrientationMaskClosure?(orientation)
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
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
