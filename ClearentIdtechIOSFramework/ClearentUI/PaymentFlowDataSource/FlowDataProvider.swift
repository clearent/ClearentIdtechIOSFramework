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
    var items : [FlowDataKeys:Any] = [FlowDataKeys:Any]()
    
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
        self.readerName = "Unknown"
        if let readerName = name {
            self.readerName = readerName
        }
        self.batterylevel = batterylevel
        self.signalLevel = signalLevel
        self.isConnected = connected
    }
}

class FlowDataFactory {
    
    class func component(with flow: ProcessType, type: FlowFeedbackType, readerInfo: ReaderInfo, payload:[FlowDataKeys:Any])-> FlowFeedback {
        let readerInfoDict = createDictionaryWithDeviceInfo(readerInfo: readerInfo)
        let dataDict = payload.merging(readerInfoDict) { (current, _) in current }
        return FlowFeedback(flow: flow, type: type, items: dataDict)
    }
        
    class func createDictionaryWithDeviceInfo(readerInfo:ReaderInfo) -> [FlowDataKeys:Any] {
        return [FlowDataKeys.readerStatus : readerInfo.isConnected,
                FlowDataKeys.readerName : readerInfo.readerName]
    }
}

protocol FlowDataProtocol : AnyObject {
    func didReceiveFlowFeedback(feedback:FlowFeedback)
}

class FlowDataProvider : NSObject {
    weak var delegate: FlowDataProtocol?
    static let shared = FlowDataProvider()
    
    let sdkWrapper = SDKWrapper()
    
    public override init() {
        super.init()
    }
    
    func fetchReaderInfo() -> ReaderInfo {
        return ReaderInfo(name: sdkWrapper.friendlyName, batterylevel: 100, signalLevel: 1, connected: sdkWrapper.isReaderConnected())
    }
}


extension FlowDataProvider : SDKWrapperProtocol {
    
    func didEncounteredGeneralError() {
        let errorDict = [FlowDataKeys.title:"xsdk_general_error_title".localized,
                         FlowDataKeys.description:"xsdk_general_error_description".localized,
                         FlowDataKeys.userAction:"xsdk_user_action_ok".localized,
                         FlowDataKeys.graphicType:FlowGraphicType.error] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: ProcessType.payment,
                                                 type: FlowFeedbackType.error,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: errorDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFinishPairing() {
        print("do soemthing")
    }
    
    func didFinishTransaction() {
        let transactionDict = [FlowDataKeys.title:"xsdk_transcation_completed_title".localized,
                               FlowDataKeys.graphicType:FlowGraphicType.transaction_completed] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: ProcessType.payment,
                                                 type: FlowFeedbackType.info,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: transactionDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didReceiveTransactionError(error: TransactionError) {
        let errorDict = [FlowDataKeys.title:"xsdk_general_error_title".localized,
                         FlowDataKeys.description:"xsdk_general_error_description".localized,
                         FlowDataKeys.userAction:"xsdk_user_action_ok".localized,
                         FlowDataKeys.graphicType:FlowGraphicType.error] as [FlowDataKeys : Any]
        
        let feedback = FlowDataFactory.component(with: ProcessType.payment,
                                                 type: FlowFeedbackType.error,
                                                 readerInfo: fetchReaderInfo(),
                                                 payload: errorDict)
        
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func userActionNeeded(action: UserAction) {
        var infoDict : [FlowDataKeys:Any]? = nil
        var type = FlowFeedbackType.info
        
        switch action {
        case .pleaseWait:
            infoDict = [FlowDataKeys.description:"xsdk_processing_description".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.loading] as [FlowDataKeys : Any]
        case .swipeInsert:
            infoDict = [FlowDataKeys.description:"xsdk_transcation_completed_description".localized,
                        FlowDataKeys.userAction:"xsdk_user_action_cancel".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .pressReaderButton:
            infoDict = [FlowDataKeys.description:"xsdk_press_button_description".localized,
                        FlowDataKeys.userAction:"xsdk_user_action_cancel".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.press_button] as [FlowDataKeys : Any]
        case .removeCard:
            print("remove card")
        case .tryICCAgain:
            type = FlowFeedbackType.warning
            infoDict = [FlowDataKeys.description:"xsdk_read_card_try_icc_again_title".localized,
                        FlowDataKeys.description:"xsdk_read_card_try_icc_again_description".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .goingOnline:
            print("going online")
        case .cardSecured:
            print("card secured")
        case .cardHasChip:
            type = FlowFeedbackType.warning
            infoDict = [FlowDataKeys.description:"xsdk_read_card_has_chip_title".localized,
                        FlowDataKeys.userAction:"xsdk_read_card_has_chip_description".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.insert_card] as [FlowDataKeys : Any]
        case .tryMSRAgain:
            type = FlowFeedbackType.warning
            infoDict = [FlowDataKeys.description:"xsdk_press_button_description".localized,
                        FlowDataKeys.userAction:"xsdk_user_action_cancel".localized,
                        FlowDataKeys.graphicType:FlowGraphicType.press_button] as [FlowDataKeys : Any]
        }
        
        if let dict = infoDict {
            let feedback = FlowDataFactory.component(with: ProcessType.payment,
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
            
            let feedback = FlowDataFactory.component(with: ProcessType.payment,
                                                     type: FlowFeedbackType.info,
                                                     readerInfo: fetchReaderInfo(),
                                                     payload: infoDict)
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func deviceDidDisconnect() {
        print("do something")
    }
    
    func didReceiveDeviceFriendlyName(_ name: String?) {
        print("friendly name available")
    }
}
