//
//  ClearentReaderDetailsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 17.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public protocol ClearentReaderDetailsProtocol {
    var readerInfo: ReaderInfo { get set }
    var readerSignalStatus: (title: String, iconName: String)? { get }
    var readerBatteryStatus: (title: String, iconName: String)? { get }
    func removeReader()
    func disconnectFromReader()
    func handleAutojoin(markAsAutojoin: Bool)
}

public class ClearentReaderDetailsPresenter: ClearentReaderDetailsProtocol {
    public var readerInfo: ReaderInfo
    
    public var readerSignalStatus: (title: String, iconName: String)? {
        guard let signalLevel = readerInfo.signalLevel,
                let iconName = readerInfo.signalStatus().iconName else { return nil }
        
        var signalStrength = "xsdk_reader_details_signal_weak".localized
        if signalLevel == 0 {
            signalStrength = "xsdk_reader_details_signal_good".localized
        } else if signalLevel == 1 {
            signalStrength = "xsdk_reader_details_signal_medium".localized
        }
    
        let title = String(format: "xsdk_reader_details_signal_status".localized, signalStrength)
        return (title, iconName)
    }
    
    public var readerBatteryStatus: (title: String, iconName: String)? {
        guard let batteryIcon = readerInfo.batteryStatus().iconName,
                let batteryTitle = readerInfo.batteryStatus().title else { return nil }
        let title = String(format: "xsdk_reader_details_battery_status".localized, batteryTitle)
        return (title, batteryIcon)
    }

    public init(readerInfo: ReaderInfo) {
        self.readerInfo = readerInfo
    }

    public func removeReader() {
        // if default reader
        if readerInfo.uuid == ClearentWrapperDefaults.pairedReaderInfo?.uuid {
            if readerInfo.isConnected {
                disconnectFromReader()
            }
            ClearentWrapperDefaults.pairedReaderInfo = nil
            ClearentWrapper.shared.readerInfoReceived?(nil)
        }
        ClearentWrapper.shared.removeReaderFromRecentlyUsed(reader: readerInfo)
    }

    public func disconnectFromReader() {
        ClearentWrapper.shared.disconnectFromReader()
    }

    public func handleAutojoin(markAsAutojoin: Bool) {
        var previousReaderWithAutojoin = ClearentWrapperDefaults.recentlyPairedReaders?.first { $0.autojoin == true }
        previousReaderWithAutojoin?.autojoin = false
        readerInfo.autojoin = markAsAutojoin
    }
}
