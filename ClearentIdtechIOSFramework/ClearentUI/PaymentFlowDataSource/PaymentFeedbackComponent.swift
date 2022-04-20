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

    var userAction: String? { get }
}

struct PaymentFeedbackComponent: PaymentFeedbackComponentProtocol {
    var feedbackItems: [FlowDataKeys: Any]

    init(feedbackItems: [FlowDataKeys: Any]) {
        self.feedbackItems = feedbackItems
    }

    var readerName: String {
        guard let readerInfo = feedbackItems[.readerInfo] as? ReaderInfo else {
            return "xsdk_unknown_reader_name".localized
        }
        return readerInfo.readerName
    }

    var batteryStatus: (iconName: String?, title: String?) {
        guard let readerInfo = feedbackItems[.readerInfo] as? ReaderInfo else { return (nil, nil) }
        return readerInfo.batteryStatus
    }

    var signalStatus: (iconName: String, title: String) {
        guard let readerInfo = feedbackItems[.readerInfo] as? ReaderInfo else { return  (iconName: ClearentConstants.IconName.signalIdle, title: "xsdk_reader_signal_idle".localized) }
        return readerInfo.signalStatus
    }

    var iconName: String? {
        guard let graphicType = feedbackItems[.graphicType] as? FlowGraphicType else { return nil }
        return graphicType.iconName
    }

    var mainDescription: String? {
        feedbackItems[.description] as? String
    }

    var mainTitle: String? {
        feedbackItems[.title] as? String
    }

    var userAction: String? {
        feedbackItems[.userAction] as? String
    }
}
