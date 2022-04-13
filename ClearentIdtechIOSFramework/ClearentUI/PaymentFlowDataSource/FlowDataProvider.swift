//
//  FlowDataProvider.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

class FlowFeedback {
    var flow : ProcessType
    var type : FlowFeedbackType
    var items = [FlowDataKeys: Any]()
    
    init(flow: ProcessType, type: FlowFeedbackType, items: [FlowDataKeys:Any]) {
        self.flow = flow
        self.type = type
        self.items = items
    }
}

struct ReaderInfo {
    var readerName : String
    let batterylevel : Int?
    let signalLevel : Int?
    let isConnected : Bool
    
    init(name: String?, batterylevel: Int, signalLevel:Int, connected: Bool) {
        self.readerName = "xsdk_unknown_reader_name".localized
        if let readerName = name {
            self.readerName = readerName
        }
        self.batterylevel = batterylevel
        self.signalLevel = signalLevel
        self.isConnected = connected
    }
}

class FlowDataFactory {
    
    class func component(with flow: ProcessType, type: FlowFeedbackType, readerInfo: ReaderInfo?, payload:[FlowDataKeys:Any])-> FlowFeedback {
        
        if let readerInfo = readerInfo {
            let readerInfoDict = createDictionaryWithDeviceInfo(readerInfo: readerInfo)
            let dataDict = payload.merging(readerInfoDict) { (current, _) in current }
            return FlowFeedback(flow: flow, type: type, items: dataDict)
        }
      
        return FlowFeedback(flow: flow, type: type, items: payload)
    }
        
    class func createDictionaryWithDeviceInfo(readerInfo:ReaderInfo) -> [FlowDataKeys:Any] {
        return [.readerConnected : readerInfo.isConnected,
                .readerName : readerInfo.readerName,
                .readerBatteryLevel : readerInfo.batterylevel ?? 0,
                .readerSignalLevel:readerInfo.signalLevel ?? 0]
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
    
    let sdkWrapper = SDKWrapper.shared
    
    public override init() {
        super.init()
        sdkWrapper.delegate = self
    }
    
    func fetchReaderInfo() -> ReaderInfo {
        return ReaderInfo(name: sdkWrapper.friendlyName, batterylevel: 100, signalLevel: 1, connected: sdkWrapper.isReaderConnected())
    }
}


extension FlowDataProvider : SDKWrapperProtocol {
    
    func didStartPairing() {
        let pairingDict = [.title:"xsdk_searching_for_reader".localized,
                           .description:"xsdk_searching_for_reader".localized,
                           .userAction:"xsdk_user_action_cancel".localized,
                           .graphicType:FlowGraphicType.loading] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo: nil,
                                                 payload: pairingDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didEncounteredGeneralError() {
        let errorDict = [.description:"xsdk_general_error_description".localized,
                         .userAction:"xsdk_user_action_ok".localized,
                         .graphicType:FlowGraphicType.error] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .error,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: errorDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
        
    func didFinishTransaction() {
        let transactionDict = [.description:"xsdk_transaction_completed_description".localized,
                               .graphicType:FlowGraphicType.transaction_completed] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .info,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: transactionDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didReceiveTransactionError(error: TransactionError) {
        let errorDict = [.title:"xsdk_general_error_title".localized,
                         .description:"xsdk_general_error_description".localized,
                         .userAction:"xsdk_user_action_ok".localized,
                         .graphicType:FlowGraphicType.error] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: .payment,
                                                 type: .error,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: errorDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func userActionNeeded(action: UserAction) {
        var infoDict : [FlowDataKeys:Any]? = nil
        var type = FlowFeedbackType.info
        
        switch action {
        case .pleaseWait:
            infoDict = [.description:"xsdk_processing_description".localized,
                        .graphicType:FlowGraphicType.loading] as [FlowDataKeys : Any]
        case .swipeInsert, .swipeTapOrInsert:
            infoDict = [.description:"xsdk_tap_insert_swipe_description".localized,
                        .userAction:"xsdk_user_action_cancel".localized,
                        .graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .pressReaderButton:
            infoDict = [.description:"xsdk_press_button_description".localized,
                        .userAction:"xsdk_user_action_cancel".localized,
                        .graphicType:FlowGraphicType.press_button] as [FlowDataKeys : Any]
        case .tryICCAgain:
            type = .warning
            infoDict = [.title:"xsdk_read_error_title".localized,
                        .description:"xsdk_read_card_try_icc_again_description".localized,
                        .userAction:"xsdk_user_action_cancel".localized,
                        .graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .cardHasChip:
            type = .warning
            infoDict = [.title:"xsdk_read_error_title".localized,
                        .description:"xsdk_read_card_has_chip_description".localized,
                        .userAction:"xsdk_user_action_cancel".localized,
                        .graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .tryMSRAgain:
            type = .warning
            infoDict = [.title:"xsdk_read_error_title".localized,
                        .description:"xsdk_read_try_msr_again_description".localized,
                        .userAction:"xsdk_user_action_cancel".localized,
                        .graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .removeCard, .cardSecured:
            print("nothing to do here")
        case .transactionStarted, .goingOnline:
            let infoDict = [FlowDataKeys.description:"xsdk_processing_description".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.loading] as [FlowDataKeys : Any]
            
            let feedback = FlowDataFactory.component(with: .payment,
                                                     type: .info,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: infoDict)
            
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
        
        if let dict = infoDict {
            let feedback = FlowDataFactory.component(with: .payment,
                                                type: type,
                                                readerInfo: fetchReaderInfo(),
                                                payload: dict)
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func didReceiveInfo(info: UserInfo) {
        switch info {
        case .authorizing:
            print("nothing to do here")
        case .processing:
            let infoDict = [FlowDataKeys.description:"xsdk_processing_description".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.loading] as [FlowDataKeys : Any]
            
            let feedback = FlowDataFactory.component(with: .payment,
                                                     type: .info,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: infoDict)
            
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func didFinishPairing() {
        self.delegate?.didFinishedPairing()
    }
    
    func deviceDidDisconnect() {
        self.delegate?.deviceDidDisconnect()
    }
}
