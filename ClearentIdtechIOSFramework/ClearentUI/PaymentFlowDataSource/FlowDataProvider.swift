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
    
    class func componentWithType(flow: ProcessType, type: FlowFeedbackType, readerInfo: ReaderInfo)-> FlowFeedback {
        return FlowFeedback(flow: flow, type: type, items: createDataFor(type: type, readerInfo: readerInfo))
    }
    
    class func createDataFor(type:FlowFeedbackType, readerInfo:ReaderInfo) -> [FlowDataKeys : Any] {
        let readerInfoDict = createDictionaryWithDeviceInfo(readerInfo: readerInfo)
        
        let feedbackDataDict = [FlowDataKeys.icon : FlowFeedbackType.info,
                        FlowDataKeys.title : "Insert Card",
                        FlowDataKeys.description : "Hey do something...",
                        FlowDataKeys.userAction : "Retry"] as [FlowDataKeys : Any]
        
        let dataDict = feedbackDataDict.merging(readerInfoDict) { (current, _) in current }
        return dataDict
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
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment,
                                                         type: FlowFeedbackType.error,
                                                         readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFinishPairing() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didFinishTransaction() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didReceiveTransactionError(error: TransactionError) {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.error, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func userActionNeeded(action: UserAction) {
        switch action {
        case .pleaseWait:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .swipeInsert:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .pressReaderButton:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .removeCard:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .tryICCAgain:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .goingOnline:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .cardSecured:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .cardHasChip:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .tryMSRAgain:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func datAForuserAction(userAction : UserAction) -> [FlowDataKeys : Any] {
        switch userAction {
        case .pleaseWait:
            <#code#>
        case .swipeInsert:
            <#code#>
        case .pressReaderButton:
            <#code#>
        case .removeCard:
            <#code#>
        case .tryICCAgain:
            <#code#>
        case .goingOnline:
            <#code#>
        case .cardSecured:
            <#code#>
        case .cardHasChip:
            <#code#>
        case .tryMSRAgain:
            <#code#>
        }
    }
    
    func didReceiveInfo(info: UserInfo) {
        switch info {
        case .authorizing:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        case .processing:
            let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
            self.delegate?.didReceiveFlowFeedback(feedback: feedback)
        }
    }
    
    func deviceDidDisconnect() {
        let feedback = FlowDataFactory.componentWithType(flow: ProcessType.payment, type: FlowFeedbackType.info, readerInfo: fetchReaderInfo())
        self.delegate?.didReceiveFlowFeedback(feedback: feedback)
    }
    
    func didReceiveDeviceFriendlyName(_ name: String?) {
        
    }
}
