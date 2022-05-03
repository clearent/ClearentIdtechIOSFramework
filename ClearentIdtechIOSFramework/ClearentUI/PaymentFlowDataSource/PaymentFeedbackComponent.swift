//
//  PaymentFeedbackComponent.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 12.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public protocol PaymentFeedbackComponentProtocol {
    var readerName: String { get }

    var batteryStatus: (iconName: String?, title: String?) { get }

    var signalStatus: (iconName: String, title: String) { get }

    var iconName: String? { get }

    var mainTitle: String? { get }

    var mainDescription: String? { get }

    var userAction: FlowFeedbackButtonType? { get }
}

struct PaymentFeedbackComponent: PaymentFeedbackComponentProtocol {
    var feedbackItems: [FlowDataItem]

    init(feedbackItems: [FlowDataItem]) {
        self.feedbackItems = feedbackItems
    }

    var readerName: String {
        guard let readerInfo = itemForKey(key: .readerInfo) as? ReaderInfo else {
            return "xsdk_unknown_reader_name".localized
        }
        return readerInfo.readerName
    }

    var batteryStatus: (iconName: String?, title: String?) {
        guard let readerInfo = itemForKey(key: .readerInfo) as? ReaderInfo else { return (nil, nil) }
        return readerInfo.batteryStatus
    }

    var signalStatus: (iconName: String, title: String) {
        guard let readerInfo = itemForKey(key: .readerInfo) as? ReaderInfo else { return (iconName: ClearentConstants.IconName.signalIdle, title: "xsdk_reader_signal_idle".localized) }
        return readerInfo.signalStatus
    }

    var iconName: String? {
        guard let graphicType = itemForKey(key: .graphicType) as? FlowGraphicType else { return nil }
        return graphicType.iconName
    }

    var mainDescription: String? {
        itemForKey(key: .description) as? String
    }

    var mainTitle: String? {
        itemForKey(key: .title) as? String
    }

    var userAction: FlowFeedbackButtonType? {
        itemForKey(key: .userAction) as? FlowFeedbackButtonType
    }
    
    func itemForKey(key:FlowDataKeys) -> AnyObject? {
        let item = feedbackItems.first { $0.type == key }
        return item?.object as AnyObject
    }
}
