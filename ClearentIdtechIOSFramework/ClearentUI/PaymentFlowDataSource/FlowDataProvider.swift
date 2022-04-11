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
    var type : FeedBackStepType
    var items : [String:String] = [String:String]()
    
    init(flow: ProcessType, type: FeedBackStepType, items: [String:String]) {
        self.flow = flow
        self.type = type
        self.items = items
    }
}

struct ReaderInfo {
    var readerName : String
    let batterylevel : Int?
    let isConnected : Bool
    
    init(name: String?, level: Int, connected: Bool) {
        self.readerName = "Unknown"
        if let readerName = name {
            self.readerName = readerName
        }
        self.batterylevel = level
        self.isConnected = connected
    }
}

class FlowDataFactory {
    
    class func componentWithType(flow: ProcessType, type: FeedBackStepType, readerInfo: ReaderInfo)-> FlowFeedback {
        return FlowFeedback(flow: flow, type: type, items: createDataFor(type: type, readerInfo: readerInfo))
    }
    
    class func createDataFor(type:FeedBackStepType, readerInfo:ReaderInfo) -> [String : String] {
        let readerInfoDict = createDictionaryWithDeviceInfo(readerInfo: readerInfo)
        
        let feedbackDataDict = [FlowDataKeys.icon.rawValue : FlowFeedbackType.info.rawValue,
                        FlowDataKeys.title.rawValue : "Insert Card",
                        FlowDataKeys.description.rawValue : "Hey do something...",
                        FlowDataKeys.userAction.rawValue : "Retry"]
        
        
        let dataDict = feedbackDataDict.merging(readerInfoDict) { (current, _) in current }
        return dataDict
    }
    
    class func createDictionaryWithDeviceInfo(readerInfo:ReaderInfo) -> [String:String] {
        return [FlowDataKeys.readerStatus.rawValue : readerInfo.isConnected ? "Connected" : "Idle",
                FlowDataKeys.readerName.rawValue : readerInfo.readerName]
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
        return ReaderInfo(name: sdkWrapper.friendlyName, level: 100, connected: sdkWrapper.isReaderConnected())
    }
}


extension FlowDataProvider : SDKWrapperProtocol {
    
    func didEncounteredGeneralError() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment,
                                                         type: FeedBackStepType.generalError,
                                                         readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFinishPairing() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFinishTransaction() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didReceiveTransactionError(error: TransactionError) {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func userActionNeeded(action: UserAction) {
        switch action {
            case .pleaseWait:
                let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
                self.delegate?.didReceiveFlowFeedback(feedback: feedback)
            case .swipeInsert:
                let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
                self.delegate?.didReceiveFlowFeedback(feedback: feedback)
            case .pressReaderButton:
                let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
                self.delegate?.didReceiveFlowFeedback(feedback: feedback)
            case .removeCard:
                let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
                self.delegate?.didReceiveFlowFeedback(feedback: feedback)
            }
    }
    
    func didReceiveInfo(info: UserInfo) {
        switch info {
        case .authorizing:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .processing:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func deviceDidDisconnect() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FeedBackStepType.generalError, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didReceiveDeviceFriendlyName(_ name: String?) {
        
    }
}
