//
//  ReaderInfo.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 19.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public struct ReaderItem {
    var readerInfo: ReaderInfo
    var isConnecting: Bool = false
}

public struct ReaderInfo: Codable {
    public var readerName: String
    public var customReaderName: String?
    public var batterylevel: Int?
    public var signalLevel: Int?
    public var isConnected: Bool {
        didSet {
            if isConnected == false {
                signalLevel = nil
                batterylevel = nil
            }
        }
    }
    public var autojoin: Bool
    public var uuid: UUID?
    public var serialNumber: String?
    public var version: String?
}

extension ReaderInfo: Equatable {
    public static func == (lhs: ReaderInfo, rhs: ReaderInfo) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

public extension ReaderInfo {
    func batteryStatus(flowFeedbackType: FlowFeedbackType? = nil) -> (iconName: String, title: String)? {
        // if reader is not connected, battery should not be shown
        guard let batteryLevel = batterylevel, isConnected, flowFeedbackType != .searchDevices else {
            return nil
        }
        var iconName = ClearentConstants.IconName.batteryLow
        if batteryLevel > 95 { iconName = ClearentConstants.IconName.batteryFull }
        else if batteryLevel > 75 { iconName = ClearentConstants.IconName.batteryHigh }
        else if batteryLevel > 50 { iconName = ClearentConstants.IconName.batteryMediumHigh }
        else if batteryLevel > 25 { iconName = ClearentConstants.IconName.batteryMedium }
        else if batteryLevel > 5 { iconName = ClearentConstants.IconName.batteryMediumLow }
        return (iconName, "\(String(batteryLevel))%")
    }

    func signalStatus(flowFeedbackType: FlowFeedbackType? = nil, isConnecting: Bool? = nil) -> (iconName: String?, title: String) {
        var icon: String? = ClearentConstants.IconName.signalIdle
        
        guard isConnected else {
            if flowFeedbackType == .searchDevices {
                return (iconName: nil, title: ClearentConstants.Localized.Pairing.connecting)
            } else if flowFeedbackType == .showReaders, let isConnecting = isConnecting, isConnecting {
                return (iconName: nil, title: ClearentConstants.Localized.Pairing.connecting)
            }
            return (iconName: icon, title: ClearentConstants.Localized.ReaderInfo.idle)
        }
        
        switch signalLevel {
        case 0:
            icon = ClearentConstants.IconName.goodSignal
        case 1:
            icon = ClearentConstants.IconName.mediumSignal
        case 2:
            icon = ClearentConstants.IconName.weakSignal
        default:
            icon = flowFeedbackType == .searchDevices ? nil : ClearentConstants.IconName.signalIdle
        }
        let title = flowFeedbackType == .searchDevices ? ClearentConstants.Localized.Pairing.connectionSuccessful : ClearentConstants.Localized.ReaderInfo.connected
        
        return (iconName: icon, title: title)
    }
}
