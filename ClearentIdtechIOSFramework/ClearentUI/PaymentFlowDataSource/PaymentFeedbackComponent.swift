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

    var mainIconName: String? { get }

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
        guard let readerName = feedbackItems[.readerName] as? String else {
            return "xsdk_unknown_reader_name".localized
        }
        return readerName
    }

    var batteryStatus: (iconName: String?, title: String?) {
        // if reader is not connected, battery should not be shown
        guard let batteryLevel = feedbackItems[.readerBatteryLevel] as? Int,
              let connected = feedbackItems[.readerConnected] as? Bool, connected else {
                  return (nil, nil)
              }
        var iconName = ClearentConstants.IconName.batteryLow
        if batteryLevel > 95 { iconName = ClearentConstants.IconName.batteryFull }
        else if batteryLevel > 75 { iconName = ClearentConstants.IconName.batteryHigh }
        else if batteryLevel > 50 { iconName = ClearentConstants.IconName.batteryMediumHigh }
        else if batteryLevel > 25 { iconName = ClearentConstants.IconName.batteryMedium }
        else if batteryLevel > 5 { iconName = ClearentConstants.IconName.batteryMediumLow }
        return (iconName, "\(String(batteryLevel))%")
    }

    var signalStatus: (iconName: String, title: String) {
        guard let connected = feedbackItems[.readerConnected] as? Bool, connected else {
            return (iconName: ClearentConstants.IconName.signalIdle, title: "xsdk_reader_signal_idle".localized)
        }
       
        guard let signalLevel = feedbackItems[.readerSignalLevel] as? Int else {
            return (iconName: ClearentConstants.IconName.signalIdle, title: "xsdk_reader_signal_idle".localized)
        }
        
        var icon = ClearentConstants.IconName.signalIdle
        switch signalLevel {
        
            case 0 :
                icon =  ClearentConstants.IconName.goodSignal
            case 1 :
                icon =  ClearentConstants.IconName.mediumSignal
            case 2 :
                icon =  ClearentConstants.IconName.weakSignal
            default:
                icon =  ClearentConstants.IconName.signalIdle
        }
        
        return (iconName: icon, title: "xsdk_reader_signal_connected".localized)
    }

    var mainIconName: String? {
        guard let graphicType = feedbackItems[.graphicType] as? FlowGraphicType else { return nil }
        return graphicType.iconName
    }

    var mainDescription: String? {
        guard let description = feedbackItems[.description] as? String else { return nil }
        return description
    }

    var mainTitle: String? {
        guard let title = feedbackItems[.title] as? String else { return nil }
        return title
    }

    var userAction: String? {
        guard let userActionText = feedbackItems[.userAction] as? String else { return nil }
        return userActionText
    }
}
