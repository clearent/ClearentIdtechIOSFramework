//
//  ReaderInfo.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 19.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public struct ReaderInfo {
    public var readerName : String
    var batterylevel : Int?
    var signalLevel : Int?
    var isConnected : Bool
    var udid: UUID?
    
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

extension ReaderInfo {
    public var batteryStatus: (iconName: String?, title: String?) {
        // if reader is not connected, battery should not be shown
        guard let batteryLevel = batterylevel, isConnected else {
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

    public var signalStatus: (iconName: String, title: String) {
        guard let signalLevel = signalLevel, isConnected else {
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
}
