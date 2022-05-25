//
//  ClearentReaderDetailsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 17.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

protocol ClearentReaderDetailsProtocol {
    var currentReader: ReaderInfo { get set }
    var readerSignalStatus: (title: String, iconName: String)? { get }
    var readerBatteryStatus: (title: String, iconName: String)? { get }
    func removeReader()
    func disconnectFromReader()
    func handleAutojoin(markAsAutojoin: Bool)
    func handleBackAction()
}

class ClearentReaderDetailsPresenter: ClearentReaderDetailsProtocol {
    public var currentReader: ReaderInfo
    private var allReaders: [ReaderItem]
    private var flowDataProvider: FlowDataProvider
    private var navigationController: UINavigationController?

    var readerSignalStatus: (title: String, iconName: String)? {
        guard let signalLevel = currentReader.signalLevel,
              let iconName = currentReader.signalStatus().iconName else { return nil }

        var signalStrength = "xsdk_reader_details_signal_weak".localized
        if signalLevel == 0 {
            signalStrength = "xsdk_reader_details_signal_good".localized
        } else if signalLevel == 1 {
            signalStrength = "xsdk_reader_details_signal_medium".localized
        }

        let title = String(format: "xsdk_reader_details_signal_status".localized, signalStrength)
        return (title, iconName)
    }

    var readerBatteryStatus: (title: String, iconName: String)? {
        guard let batteryIcon = currentReader.batteryStatus().iconName,
              let batteryTitle = currentReader.batteryStatus().title else { return nil }
        let title = String(format: "xsdk_reader_details_battery_status".localized, batteryTitle)
        return (title, batteryIcon)
    }

    init(currentReader: ReaderItem, allReaders: [ReaderItem], flowDataProvider: FlowDataProvider, navigationController: UINavigationController) {
        self.currentReader = currentReader.readerInfo
        self.allReaders = allReaders
        self.flowDataProvider = flowDataProvider
        self.navigationController = navigationController
    }

    func removeReader() {
        // if default reader
        if currentReader.uuid == ClearentWrapperDefaults.pairedReaderInfo?.uuid {
            ClearentWrapperDefaults.pairedReaderInfo = nil
            if currentReader.isConnected {
                disconnectFromReader()
            }
        }
        ClearentWrapper.shared.removeReaderFromRecentlyUsed(reader: currentReader)
        if let recentlyPairedReaders = ClearentWrapperDefaults.recentlyPairedReaders, !recentlyPairedReaders.isEmpty {
            handleBackAction()
        } else {
            navigationController?.dismiss(animated: true)
        }
    }

    func disconnectFromReader() {
        ClearentWrapper.shared.disconnectFromReader()
    }

    public func handleAutojoin(markAsAutojoin: Bool) {
        currentReader.autojoin = markAsAutojoin
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders else { return }
    
        if let oldAutojoinIndex = existingReaders.firstIndex(where: {$0.autojoin == true}) {
            existingReaders[oldAutojoinIndex].autojoin = false
        }
        if let currentIndex = existingReaders.firstIndex(where: {$0.uuid == currentReader.uuid}) {
            existingReaders[currentIndex].autojoin = markAsAutojoin
        }
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
        if currentReader.uuid == ClearentWrapperDefaults.pairedReaderInfo?.uuid {
            ClearentWrapperDefaults.pairedReaderInfo?.autojoin = markAsAutojoin
        }
    }

    func handleBackAction() {
        if let recentReaders = ClearentWrapperDefaults.recentlyPairedReaders, let defaultReader = ClearentWrapperDefaults.pairedReaderInfo {
            // create list of available and recently used readers, including default reader
            var result: [ReaderInfo] = recentReaders.filter { _ in
                allReaders.map { $0.readerInfo }.contains(where: { readerInfo in
                    readerInfo.uuid == currentReader.uuid && readerInfo.uuid != ClearentWrapperDefaults.pairedReaderInfo?.uuid
                })
            }
            result.insert(defaultReader, at: 0)
            flowDataProvider.didFindRecentlyUsedReaders(readers: result)
            navigationController?.popViewController(animated: true)
        } else {
            navigationController?.dismiss(animated: true)
        }
    }
}
