//
//  FlowDataProvider.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

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
        if readerInfo != nil || !ClearentWrapper.shared.previouslyPairedReaders.isEmpty {
            var allItems = [FlowDataItem(type: .readerInfo, object: readerInfo)]
            allItems.append(contentsOf: payload)
            
            return FlowFeedback(flow: flow, type: type, items: allItems)
        }
    
        return FlowFeedback(flow: flow, type: type, items: payload)
    }
}

protocol FlowDataProtocol : AnyObject {
    func didFinishSignature()
    func didFinishTransaction(error: ResponseError?)
    func deviceDidDisconnect()
    func didFinishedPairing()
    func didReceiveFlowFeedback(feedback: FlowFeedback)
    func didBeginContinuousSearching()
}

class FlowDataProvider : NSObject {
    weak var delegate: FlowDataProtocol?
    
    let sdkWrapper = ClearentWrapper.shared
    var connectionErrorDisplayed = false
    
    public override init() {
        super.init()
        sdkWrapper.delegate = self
    }
    
    func fetchReaderInfo() -> ReaderInfo? {
        return ClearentWrapperDefaults.pairedReaderInfo
    }
    
    public func startTipTransaction(amountWithoutTip: Double) {
        let amountInfo = AmountInfo(amountWithoutTip: amountWithoutTip, availableTipPercentages: ClearentUIManager.shared.tipAmounts)
        
        let items = [FlowDataItem(type: .title, object: ClearentConstants.Localized.Tips.transactionTip),
                     FlowDataItem(type: .tips, object: amountInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.transactionWithTip),
                     FlowDataItem(type: .userAction, object: FlowButtonType.transactionWithoutTip)]
        
        let feedback = FlowFeedback(flow: .payment, type: FlowFeedbackType.info, items: items)

        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
}

extension FlowDataProvider : ClearentWrapperProtocol {
    
    func didFinishedSignatureUploadWith(response: SignatureResponse, error: ResponseError?) {
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
            self.delegate?.didFinishSignature()
        }
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
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
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
        
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?) {
        let feedback: FlowFeedback
        
        if let error = error {
            let errItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.error),
                            FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.generalErrorTitle),
                            FlowDataItem(type: .description, object: error.message),
                            FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                            FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                     type: .error,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: errItems)
        } else {
            let transactionItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.transaction_completed),
                                    FlowDataItem(type: .title, object: ClearentConstants.Localized.FlowDataProvider.transactionCompleted)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: transactionItems)
            
        }
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        self.delegate?.didFinishTransaction(error: error)
    }
    
    func userActionNeeded(action: UserAction) {
        var items : [FlowDataItem]? = nil
        var type = FlowFeedbackType.info

        switch action {
        case .pleaseWait:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .description, object: action.description)]
        case .swipeInsert, .swipeTapOrInsert:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .description, object: action.description),
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
        case .tryICCAgain, .cardHasChip, .tryMSRAgain, .useMagstripe, .tapFailed:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .removeCard, .cardSecured:
            print("nothing to do here")
        case .transactionStarted, .goingOnline:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .description, object: action.description)]
        case .noInternet:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Internet.error),
                     FlowDataItem(type: .description, object: action.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .noBluetooth:
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
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
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
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func didReceiveInfo(info: UserInfo) {
        var items: [FlowDataItem]?
        
        switch info {
        case .authorizing:
            print("nothing to do here")
        case .processing, .goingOnline:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .description, object: info.description)]
        case .amountNotAllowedForTap:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: info.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .chipNotRecognized:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: ClearentConstants.Localized.Error.readerError),
                     FlowDataItem(type: .description, object: info.description),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.manuallyEnterCardInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        }
        
        if let flowItems = items {
            let feedback = FlowDataFactory.component(with: .payment,
                                                     type: .info,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: flowItems)
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
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

    func deviceDidDisconnect() {
        delegate?.deviceDidDisconnect()
    }

    func didStartPairing() {
        let items = [FlowDataItem(type: .hint, object: ClearentConstants.Localized.Pairing.selectReader),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]

        let feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: .info,
                                                 readerInfo: nil,
                                                 payload: items)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
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
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
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
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFindRecentlyUsedReaders(readers: [ReaderInfo]) {
        let flowDataItem = readers.count > 0 ? FlowDataItem(type: .recentlyPaired, object: readers) : FlowDataItem(type: .description, object: ClearentConstants.Localized.Pairing.noReadersFoundDescription)
        let items = [flowDataItem,
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        
        let feedback = FlowDataFactory.component(with: .showReaders,
                                                 type: .showReaders,
                                                 readerInfo: ClearentWrapperDefaults.pairedReaderInfo,
                                                 payload: items)
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didBeginContinuousSearching() {
        self.delegate?.didBeginContinuousSearching()
    }

    func didReceiveSignalStrength() {
        // when signal strength is received, content should be reloaded
        if case .showReaders = ClearentWrapper.shared.flowType?.processType {
            createFeedbackForSuccessfulPairing()
        }
    }
    
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
}
