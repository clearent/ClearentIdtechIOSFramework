//
//  FlowDataProvider.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

struct FlowDataItem {
  var type: FlowDataKeys
  var object: Any
}

class FlowFeedback {
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
    
    class func component(with flow: ProcessType, type: FlowFeedbackType, readerInfo: ReaderInfo?, payload:[FlowDataItem])-> FlowFeedback {
        
        if let readerInfo = readerInfo {
            var allItems = [FlowDataItem(type: .readerInfo, object: readerInfo)]
            allItems.append(contentsOf: payload)
            return FlowFeedback(flow: flow, type: type, items: allItems)
        }
      
        return FlowFeedback(flow: flow, type: type, items: payload)
    }
}

protocol FlowDataProtocol : AnyObject {
    func deviceDidDisconnect()
    func didFinishedPairing()
    func didReceiveFlowFeedback(feedback:FlowFeedback)
}

class FlowDataProvider : NSObject {
    weak var delegate: FlowDataProtocol?
    static let shared = FlowDataProvider()
    
    let sdkWrapper = ClearentWrapper.shared
    
    public override init() {
        super.init()
        sdkWrapper.delegate = self
    }
    
    func fetchReaderInfo() -> ReaderInfo? {
        return sdkWrapper.readerInfo
    }
}

extension FlowDataProvider : ClearentWrapperProtocol {
    
    // MARK - Transaction related
    
    func didEncounteredGeneralError() {
        
        let items = [FlowDataItem(type: .description, object: "xsdk_general_error_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.error)]
        
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .error,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: items)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
        
    func didFinishTransaction(response: TransactionResponse, error: ResponseError?) {
        let feedback: FlowFeedback
        
        if let error = error {
            let errItems = [FlowDataItem(type: .title, object: "xsdk_general_error_title".localized),
                            FlowDataItem(type: .description, object: error.message),
                            FlowDataItem(type: .userAction, object: FlowButtonType.retry),
                            FlowDataItem(type: .graphicType, object: FlowGraphicType.error)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                     type: .error,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: errItems)
        } else {
            let transactionItems = [FlowDataItem(type: .description, object: "xsdk_transaction_completed_description".localized),
                                    FlowDataItem(type: .graphicType, object: FlowGraphicType.transaction_completed)]
            
            feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: transactionItems)
            
        }
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func userActionNeeded(action: UserAction) {
        var items : [FlowDataItem]? = nil
        var type = FlowFeedbackType.info
        
        switch action {
        case .pleaseWait:
            items = [FlowDataItem(type: .description, object: "xsdk_processing_description".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading)]
        case .swipeInsert, .swipeTapOrInsert:
            items = [FlowDataItem(type: .description, object: "xsdk_tap_insert_swipe_description".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel)]
        case .pressReaderButton:
            items = [FlowDataItem(type: .description, object: "xsdk_press_button_description".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.press_button)]
        case .tryICCAgain:
            type = .warning
            items = [FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: "xsdk_read_card_try_icc_again_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card)]
        case .cardHasChip:
            type = .warning
            items = [FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: "xsdk_read_card_has_chip_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card)]
        case .tryMSRAgain:
            type = .warning
            items = [FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: "xsdk_read_try_msr_again_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card)]
        case .useMagstripe:
            type = .warning
            items = [FlowDataItem(type: .title, object: "xsdk_read_error_title".localized),
                     FlowDataItem(type: .description, object: "xsdk_read_try_use_magstripe_description".localized),
                     FlowDataItem(type: .userAction, object: FlowButtonType.cancel),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.insert_card)]
        case .removeCard, .cardSecured:
            print("nothing to do here")
        case .transactionStarted, .goingOnline:
            items = [FlowDataItem(type: .description, object: "xsdk_processing_description".localized),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.loading)]
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
        switch info {
        case .authorizing:
            print("nothing to do here")
        case .processing, .goingOnline:
            let  items = [FlowDataItem(type: .description, object: "xsdk_processing_description".localized),
                          FlowDataItem(type: .graphicType, object: FlowGraphicType.loading)]
            
            let feedback = FlowDataFactory.component(with: .payment,
                                                     type: .info,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: items)
            
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    
    // MARK - Pairing related
    
    func didFinishPairing() {
        let  items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.pairingSuccessful),
                      FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader)]
        
        let feedback = FlowDataFactory.component(with: .pairing,
                                                 type: .searchDevices,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: items)
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        self.delegate?.didFinishedPairing()
    }
    
    func deviceDidDisconnect() {
        self.delegate?.deviceDidDisconnect()
    }
    
    func didStartPairing() {
        let  items = [FlowDataItem(type: .title, object: "xsdk_select_reader".localized),
                      FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader),
                      FlowDataItem(type: .userAction, object: "xsdk_user_action_cancel".localized)]
        
        let feedback = FlowDataFactory.component(with: .pairing,
                                                 type: .info,
                                                 readerInfo: nil,
                                                 payload: items)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFindReaders(readers: [ReaderInfo]) {
        let items = [FlowDataItem(type: .title, object: "xsdk_select_reader".localized),
                    FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                    FlowDataItem(type: .devicesFound, object: readers),
                    FlowDataItem(type: .userAction, object: "xsdk_user_action_cancel".localized)]
        
        let feedback = FlowDataFactory.component(with: .pairing,
                                                 type: .searchDevices,
                                                 readerInfo: nil,
                                                 payload: items)
       self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func startedReaderConnection(with reader: ReaderInfo) {
        let items = [FlowDataItem(type: .graphicType, object: FlowGraphicType.loading),
                     FlowDataItem(type: .graphicType, object: FlowGraphicType.pairedReader)]
    
        let feedback = FlowDataFactory.component(with: .pairing,
                                          type: .searchDevices,
                                    readerInfo: reader,
                                       payload: items)
       self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didNotFindReaders() {
        let items = [FlowDataItem(type: .title, object: "xsdk_no_readers_found_title".localized),
                     FlowDataItem(type: .description, object: "xsdk_no_readers_found_description".localized),
                     FlowDataItem(type: .userAction, object: "xsdk_user_action_retry".localized),
                     FlowDataItem(type: .userAction, object: "xsdk_user_action_cancel".localized)]
        
        let feedback = FlowDataFactory.component(with: .pairing,
                                          type: .info,
                                    readerInfo: nil,
                                       payload: items)
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
}
