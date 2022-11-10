//
//  FlowDataProvider.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

/*
 This class integrates the wrapper delegate methods and receives all feedback from the SDK.
 It will process and provide the information further to the UI part in way that is easier to create the UI by using its own protocol to communicate with the UI.
  Every time there is a new feedback that needs to be displayed, a FlowFeedback object will be generated and pushed through the delegate method to the UI.
  Flow feedback contains everything that UI needs to display the new information.
 */

import Foundation

public struct FlowDataItem {
  var type: FlowDataKeys
  var object: Any?
}

public class FlowFeedback {
    var flow : ProcessType
    var type : FlowFeedbackType
    var items = [FlowDataItem]()
    
    init(flow: ProcessType, type: FlowFeedbackType, items: [FlowDataItem]) {
        self.flow = flow
        self.type = type
        self.items = items
    }
}

class FlowDataFactory {
    class func component(with flow: ProcessType, type: FlowFeedbackType, readerInfo: ReaderInfo?, payload: [FlowDataItem]) -> FlowFeedback {
        let isNotManualPayment = FlowDataProvider.useCardReaderPaymentMethod || ClearentWrapper.shared.flowType?.processType != .payment
        if (readerInfo != nil || !ClearentWrapper.shared.previouslyPairedReaders.isEmpty) && isNotManualPayment {
            var allItems = [FlowDataItem(type: .readerInfo, object: readerInfo)]
            allItems.append(contentsOf: payload)
            
            return FlowFeedback(flow: flow, type: type, items: allItems)
        }
    
        return FlowFeedback(flow: flow, type: type, items: payload)
    }
}

protocol FlowDataProtocol : AnyObject {
    func didFinishSignature()
    func didFinishTransaction(error: ClearentError?)
    func deviceDidDisconnect()
    func didFinishedPairing()
    func didReceiveFlowFeedback(feedback: FlowFeedback)
    func didBeginContinuousSearching()
}

class FlowDataProvider : NSObject {
    weak var delegate: FlowDataProtocol?
    
    let sdkWrapper = ClearentWrapper.shared
    var connectionErrorDisplayed = false
    
    private var shouldAskForOfflineModePermission: Bool {
        switch ClearentUIManager.configuration.offlineModeState {
        case .on:
            return false
        case .prompted:
            return sdkWrapper.isNewPaymentProcess ? true : false
        }
    }
    
    static var useCardReaderPaymentMethod: Bool {
        ClearentWrapper.shared.cardReaderPaymentIsPreffered && ClearentWrapper.shared.useManualPaymentAsFallback == nil
    }
    
    // MARK: - Init
    
    public override init() {
        super.init()
        sdkWrapper.delegate = self
    }
    
    // MARK: - Internal
    
    func fetchReaderInfo() -> ReaderInfo? {
        ClearentWrapperDefaults.pairedReaderInfo
    }
    
    func startTipTransaction(amountWithoutTip: Double) {
        let amountInfo = AmountInfo(amountWithoutTip: amountWithoutTip, availableTipPercentages: ClearentUIManager.configuration.tipAmounts)
        
        let items = [FlowDataItem(type: .title, object: ClearentConstants.Localized.Tips.transactionTip),
                     FlowDataItem(type: .tips, object: amountInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.transactionWithTip),
                     FlowDataItem(type: .userAction, object: FlowButtonType.transactionWithoutTip)]
        
        let feedback = FlowFeedback(flow: .payment, type: FlowFeedbackType.info, items: items)

        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func displayOfflineModeWarningMessage() {
        let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.OfflineMode.offlineModeWarningMessageTitle),
                     FlowDataItem(type: .description, object: ClearentConstants.Localized.OfflineMode.offlineModeWarningMessageDescription),
                     FlowDataItem(type: .userAction, object: FlowButtonType.confirmOfflineModeWarningMessage)]
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo:fetchReaderInfo(),
                                                 payload: items)
        
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
}

extension FlowDataProvider : ClearentWrapperProtocol {
    
    func didAcceptOfflineSignature(err: TransactionStoreStatus, transactionID: String) {
        // handle offline signature
    }
    
    func didFinishedSignatureUploadWith(response: SignatureResponse?, error: ClearentError?) {
        let feedback: FlowFeedback
        
        if error != nil {
            let errItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.error),
                            FlowDataItem(type: .title, object: ClearentConstants.Localized.Signature.signatureUploadFailure),
                            FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                            FlowDataItem(type: .userAction, object: FlowButtonType.skipSignature)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                 type: .signatureError,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: errItems)
        } else {
            let transactionItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.transaction_completed),
                                    FlowDataItem(type: .title, object: ClearentConstants.Localized.Signature.signatureUploadSuccessful)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: transactionItems)
            delegate?.didFinishSignature()
        }
        
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
 
    // MARK - Transaction related
    
    func didEncounteredGeneralError() {
        let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.error),
                     FlowDataItem(type: .description, object: ClearentConstants.Localized.Error.generalErrorDescription),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .error,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: items)
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didAcceptOfflineTransaction(err: TransactionStoreStatus) {
        // handle offline transaction here
    }
        
    func didFinishTransaction(response: TransactionResponse?, error: ClearentError?) {
        let feedback: FlowFeedback
        
        if let error = error {
            
            var detailedErrorMessage = ""
            if let response = response {
                detailedErrorMessage = createDetailedErrorMessage(with: error.code, message: response.payload.transaction?.message, transactionID: response.links?.first?.id, exchangeID: response.exchange_id)
            } else {
                detailedErrorMessage = createDetailedErrorMessage(with: error.code, message: error.message, transactionID: nil, exchangeID: "-")
            }
            
            let errorItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.error),
                            FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.generalErrorTitle),
                            FlowDataItem(type: .error, object: detailedErrorMessage),
                            FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                            FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                     type: .error,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: errorItems)
        } else {
            let transactionItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.transaction_completed),
                                    FlowDataItem(type: .title, object: ClearentConstants.Localized.FlowDataProvider.transactionCompleted)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: transactionItems)
            
        }
        delegate?.didReceiveFlowFeedback(feedback: feedback)
        delegate?.didFinishTransaction(error: error)
    }
    
    func deviceDidDisconnect() {
        delegate?.deviceDidDisconnect()
    }
    
    func didBeginContinuousSearching() {
        delegate?.didBeginContinuousSearching()
    }
    
    func showEncryptionWarning() {
        let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.OfflineMode.offlineModeEncryptionWarningMessage),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        let flowFeedback = FlowDataFactory.component(with: .payment,
                                                     type: .warning,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: items)
        delegate?.didReceiveFlowFeedback(feedback: flowFeedback)
    }
    
    func userActionNeeded(action: UserAction) {
        var items : [FlowDataItem]? = nil
        var type = FlowFeedbackType.info

        switch action {
        case .pleaseWait:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .description, object: action.description)]
        case .swipeTapOrInsert:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.animatedCardInteraction),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .pressReaderButton, .connectionTimeout:
            items = [FlowDataItem(type: .description, object: ClearentConstants.Localized.Pairing.readerRange),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.press_button),
                     FlowDataItem(type: .description, object: action.description)]
            
            if ClearentWrapper.shared.flowType?.processType == .payment, connectionErrorDisplayed {
                items?.append(FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo))
            }
            items?.append(FlowDataItem(type: .userAction, object: FlowButtonType.cancel))
            connectionErrorDisplayed = true
        case .tryICCAgain, .cardHasChip, .tryMSRAgain, .useMagstripe, .swipeInsert, .tapFailed:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.staticCardInteraction),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .removeCard, .cardSecured, .authorizing:
            print("nothing to do here")
        case .noInternet:
            type = .warning
            
            if !ClearentWrapper.configuration.enableOfflineMode {
                items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                         FlowDataItem(type: .title, object: ClearentConstants.Localized.Internet.error),
                         FlowDataItem(type: .description, object: action.description),
                         FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                         FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
            } else {
                if ClearentUIManager.configuration.offlineModeState == .on {
                    displayOfflineModeWarningMessage()
                    return
                } else if sdkWrapper.isNewPaymentProcess {
                    items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                             FlowDataItem(type: .title, object: ClearentConstants.Localized.OfflineMode.enableOfflineMode),
                             FlowDataItem(type: .description, object: ClearentConstants.Localized.OfflineMode.offlineModeWarningMessageDescription),
                             FlowDataItem(type: .description, object: ClearentConstants.Localized.OfflineMode.offlineModeWarningConfirmationDescription),
                             FlowDataItem(type: .userAction, object: FlowButtonType.confirmOfflineMode),
                             FlowDataItem(type: .userAction, object: FlowButtonType.denyOfflineMode)]
                } else {
                    items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                             FlowDataItem(type: .title, object: ClearentConstants.Localized.Internet.error),
                             FlowDataItem(type: .description, object: action.description),
                             FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                             FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
                }
            }
        case .noBluetooth:
            guard FlowDataProvider.useCardReaderPaymentMethod else { return }
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Bluetooth.error),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .noBluetoothPermission:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Bluetooth.permissionError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.settings),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .failedToStartSwipe:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .cardUnsupported, .cardBlocked, .cardExpired, .badChip:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.error),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .transactionFailed:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.staticCardInteraction),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .processing, .goingOnline, .transactionStarted:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .description, object: action.description)]
        case .amountNotAllowedForTap:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .chipNotRecognized:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        }
        
        if let flowItems = items {
            let feedback = FlowDataFactory.component(with: .payment,
                                                     type: ClearentWrapper.shared.flowType?.flowFeedbackType ?? type,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: flowItems)
            delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    // MARK - Pairing related
    
    func didFinishPairing() {
        if case .showReaders = ClearentWrapper.shared.flowType?.processType {
            createFeedbackForSuccessfulPairing()
        } else {
            let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.pairingSuccessful),
                         FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader)]
            let feedback = FlowDataFactory.component(with: .pairing(),
                                                     type: .searchDevices,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: items)
            delegate?.didReceiveFlowFeedback(feedback: feedback)
            delegate?.didFinishedPairing()
        }
    }

    func didStartPairing() {
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.Pairing.selectReader),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]

        let feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: .info,
                                                 readerInfo: nil,
                                                 payload: items)
        
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFindReaders(readers: [ReaderInfo]) {
        let title = readers.count > 0 ? ClearentConstants.Localized.Pairing.selectReader : ClearentConstants.Localized.Pairing.noReadersFoundTitle
        let flowDataItem = readers.count > 0 ? FlowDataItem(type: .devicesFound, object: readers) : FlowDataItem(type: .description, object: ClearentConstants.Localized.Pairing.noReadersFoundDescription)
        let flowFeedbackType = readers.count > 0 ? FlowFeedbackType.searchDevices : FlowFeedbackType.info
        
        let items = [FlowDataItem(type: .hint, object: title),
                     flowDataItem,
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]

        let feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: flowFeedbackType,
                                                 readerInfo: nil,
                                                 payload: items)
        delegate?.didReceiveFlowFeedback(feedback: feedback)
     }
    
    func startedReaderConnection(with reader: ReaderInfo) {
        let items: [FlowDataItem]
        let feedback: FlowFeedback
        
        if case .showReaders = ClearentWrapper.shared.flowType?.processType {
            guard let recentlyPairedDevices = ClearentWrapperDefaults.recentlyPairedReaders else { return }
            
            items = [FlowDataItem(type: .recentlyPaired, object: recentlyPairedDevices),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
            feedback = FlowDataFactory.component(with: .showReaders,
                                                 type: .showReaders,
                                                 readerInfo: reader,
                                                 payload: items)
        } else {
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader)]
            feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: .searchDevices,
                                                 readerInfo: reader,
                                                 payload: items)
        }
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFindRecentlyUsedReaders(readers: [ReaderInfo]) {
        let flowDataItem = readers.count > 0 ? FlowDataItem(type: .recentlyPaired, object: readers) : FlowDataItem(type: .description, object: ClearentConstants.Localized.Pairing.noReadersFoundDescription)
        let items = [flowDataItem,
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        
        let feedback = FlowDataFactory.component(with: .showReaders,
                                                 type: .showReaders,
                                                 readerInfo: ClearentWrapperDefaults.pairedReaderInfo,
                                                 payload: items)
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }

    func didReceiveSignalStrength() {
        // when signal strength is received, content should be reloaded
        if case .showReaders = ClearentWrapper.shared.flowType?.processType {
            createFeedbackForSuccessfulPairing()
        }
    }
    
    // MARK: - Private
    
    private func createFeedbackForSuccessfulPairing() {
        guard var recentlyPairedReaders = ClearentWrapperDefaults.recentlyPairedReaders,
              let pairedReaderInfo = ClearentWrapperDefaults.pairedReaderInfo,
              let indexOfSelectedReader = recentlyPairedReaders.firstIndex(where: {$0 == pairedReaderInfo}) else { return }
        
        recentlyPairedReaders[indexOfSelectedReader] = pairedReaderInfo
        
        let items = [FlowDataItem(type: .recentlyPaired, object: recentlyPairedReaders),
                 FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        let feedback = FlowDataFactory.component(with: .showReaders,
                                             type: .showReaders,
                                             readerInfo: ClearentWrapperDefaults.pairedReaderInfo,
                                             payload: items)
        delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    private func createDetailedErrorMessage(with errorCode: String?, message: String?, transactionID: String?, exchangeID: String) -> String {
        guard let errorCode = errorCode else { return "" }

        var detailedErrorMessage = String(format: ClearentConstants.Localized.Error.errorCode, errorCode)
        
        if let errorMessage = message {
            detailedErrorMessage = detailedErrorMessage.appending(String(format: ClearentConstants.Localized.Error.errorMessage, errorMessage))
        }
        
        if let transactionID = transactionID {
            detailedErrorMessage = detailedErrorMessage.appending(String(format: ClearentConstants.Localized.Error.transactionID, transactionID))
        }
        detailedErrorMessage = detailedErrorMessage.appending(String(format: ClearentConstants.Localized.Error.exchangeID, exchangeID))
        
        return detailedErrorMessage
    }
}
