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
    func didFinishTransaction(error: ResponseError?)
    func deviceDidDisconnect()
    func didFinishedPairing()
    func didReceiveFlowFeedback(feedback: FlowFeedback)
    func didBeginContinuousSearching()
}

class FlowDataProvider : NSObject {
    weak var delegate: FlowDataProtocol?
    
    let sdkWrapper = ClearentWrapper.shared
    
    public override init() {
        super.init()
        sdkWrapper.delegate = self
    }
    
    func fetchReaderInfo() -> ReaderInfo? {
        return ClearentWrapperDefaults.pairedReaderInfo
    }
    
    public func startTipTransaction(amountWithoutTip: Double) {
        let amountInfo = AmountInfo(amountWithoutTip: amountWithoutTip, availableTipPercentages: ClearentUIManager.shared.tipAmounts)
        
        let items = [FlowDataItem(type: .title, object: "xsdk_user_transaction_tip_title".localized),
                     FlowDataItem(type: .tips, object: amountInfo),
                     FlowDataItem(type: .userAction, object: FlowButtonType.transactionWithTip),
                     FlowDataItem(type: .userAction, object: FlowButtonType.transactionWithoutTip)]
        
        let feedback = FlowFeedback(flow: .payment, type: FlowFeedbackType.info, items: items)

        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
}

extension FlowDataProvider : ClearentWrapperProtocol {
    // MARK - Transaction related
    
    func didEncounteredGeneralError() {
        let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.error),
                     FlowDataItem(type: .description, object: "xsdk_general_error_description".localized),
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
                            FlowDataItem(type: .title, object: "xsdk_general_error_title".localized),
                            FlowDataItem(type: .description, object: error.message),
                            FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                            FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                     type: .error,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: errItems)
        } else {
            let transactionItems = [FlowDataItem(type: .graphicType, object: FlowGraphicType.transaction_completed),
                                    FlowDataItem(type: .title, object: "xsdk_transaction_completed_description".localized)]
            
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
                     FlowDataItem(type: .description, object: description.localized)]
        case .swipeInsert, .swipeTapOrInsert:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .pressReaderButton, .connectionTimeout:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.press_button),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .tryICCAgain:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .cardHasChip:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .tryMSRAgain:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .useMagstripe:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .tapFailed:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .removeCard, .cardSecured:
            print("nothing to do here")
        case .transactionStarted, .goingOnline:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .description, object: description.localized)]
        case .noInternet:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: "xsdk_internet_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .noBluetooth:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: "xsdk_bluetooth_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .noBluetoothPermission:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.warning),
                     FlowDataItem(type: .title, object: "xsdk_bluetooth_permission_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.settings),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .failedToStartSwipe:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .cardUnsupported:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .cardBlocked:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .cardExpired:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .badChip:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .transactionFailed:
            type = .warning
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        }
        
        if let flowItems = items {
            let feedback = FlowDataFactory.component(with: .payment,
                                                type: type,
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
                         FlowDataItem(type: .description, object: description.localized)]
        case .amountNotAllowedForTap:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .chipNotRecognized:
            items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: description.localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
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
        if case .showReaders = ClearentWrapper.shared.flowType {
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
        let items = [FlowDataItem(type: .hint, object: "xsdk_select_reader".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]

        let feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: .info,
                                                 readerInfo: nil,
                                                 payload: items)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFindReaders(readers: [ReaderInfo]) {
        let items = [FlowDataItem(type: .hint, object: "xsdk_select_reader".localized),
                     FlowDataItem(type: .devicesFound, object: readers),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]

        let feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: .searchDevices,
                                                 readerInfo: nil,
                                                 payload: items)
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
     }
    
    func startedReaderConnection(with reader: ReaderInfo) {
        let items: [FlowDataItem]
        let feedback: FlowFeedback
        
        if case .showReaders = ClearentWrapper.shared.flowType {
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
    
    func didNotFindReaders() {
        let items = [FlowDataItem(type: .hint, object: "xsdk_no_readers_found_title".localized),
                     FlowDataItem(type: .description, object: "xsdk_no_readers_found_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]

        let feedback = FlowDataFactory.component(with: .pairing(),
                                                 type: .info,
                                                 readerInfo: nil,
                                                 payload: items)
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didNotFindRecentlyUsedReaders() {
        let items = [FlowDataItem(type: .description, object: "xsdk_no_readers_found_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.pairNewReader)]
        let feedback = FlowDataFactory.component(with: .showReaders,
                                                 type: .showReaders,
                                                 readerInfo: ClearentWrapperDefaults.pairedReaderInfo,
                                                 payload: items)
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFindRecentlyUsedReaders(readers: [ReaderInfo]) {
        let items = [FlowDataItem(type: .recentlyPaired, object: readers),
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
        if case .showReaders = ClearentWrapper.shared.flowType {
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
