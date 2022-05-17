//
//  ReaderInfo.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 19.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public struct ReaderInfo : Codable {
    public var readerName : String
    var batterylevel: Int?
    var signalLevel: Int?
    var isConnected: Bool
    var autojoin: Bool
    var uuid: UUID?
    var serialNumber: String?
    var version: String?
}

public extension ReaderInfo {
    func batteryStatus(flowFeedbackType: FlowFeedbackType? = nil) -> (iconName: String?, title: String?) {
        // if reader is not connected, battery should not be shown
        guard let batteryLevel = batterylevel, isConnected, flowFeedbackType != .searchDevices else {
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

    func signalStatus(flowFeedbackType: FlowFeedbackType? = nil) -> (iconName: String?, title: String) {
        var icon = ClearentConstants.IconName.signalIdle
        guard let signalLevel = signalLevel, isConnected else {
            if flowFeedbackType == .searchDevices {
                return (iconName: nil, title: "xsdk_connecting_reader".localized)
            }
            return (iconName: icon, title: "xsdk_reader_signal_idle".localized)
        }

        switch signalLevel {
        case 0:
            icon = ClearentConstants.IconName.goodSignal
        case 1:
            icon = ClearentConstants.IconName.mediumSignal
        case 2:
            icon = ClearentConstants.IconName.weakSignal
        default:
            icon = ClearentConstants.IconName.signalIdle
        }
        let title = flowFeedbackType == .searchDevices ? "xsdk_connection_sucesfull".localized : "xsdk_reader_signal_connected".localized
        return (iconName: icon, title: title)
    }
}
