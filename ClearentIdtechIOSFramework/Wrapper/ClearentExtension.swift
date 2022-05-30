//
//  ClearentLoggerExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 20.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import CocoaLumberjack

extension ClearentWrapper: BluetoothScannerProtocol {
    
    func didUpdateBluetoothState(isOn: Bool) {
        isBluetoothOn = isOn
        if (!isBluetoothOn) {
            if var currentReader = ClearentWrapperDefaults.pairedReaderInfo {
                currentReader.isConnected = false
                ClearentWrapperDefaults.pairedReaderInfo = currentReader
            }
        }
    }
    
    internal func didReceivedSignalStrength(level: SignalLevel) {
        if var currentReader = ClearentWrapperDefaults.pairedReaderInfo {
            currentReader.signalLevel = level.rawValue
            ClearentWrapperDefaults.pairedReaderInfo = currentReader
        }
    }
    
    internal func didFinishWithError() {
        self.delegate?.didFinishPairing()
    }
}

extension ClearentWrapper {
    
    internal func addReaderToRecentlyUsed(reader: ReaderInfo) {
        var reader = reader
        reader.isConnected = false
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders, !existingReaders.isEmpty else {
            reader.autojoin = true
            ClearentWrapperDefaults.pairedReaderInfo?.autojoin = true
            ClearentWrapperDefaults.recentlyPairedReaders = [reader]
            return
        }
        if let defaultReaderIndex = existingReaders.firstIndex(where: {$0 == reader }) {
            existingReaders[defaultReaderIndex] = reader
        } else {
            existingReaders.insert(reader, at: 0)
        }
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
    }
    
    internal func removeReaderFromRecentlyUsed(reader: ReaderInfo) {
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders else { return }
        existingReaders.removeAll(where: { $0 == reader })
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
    }
    
    internal func fetchRecentlyAndAvailableReaders(devices: [ClearentBluetoothDevice]) -> [ReaderInfo] {
        let availableReaders = devices.compactMap { readerInfo(from: $0)}
        return fetchRecentlyAndAvailableReaders(availableReaders: availableReaders)
    }
    
    internal func fetchRecentlyAndAvailableReaders(availableReaders: [ReaderInfo]) -> [ReaderInfo] {
        guard let recentReaders = ClearentWrapperDefaults.recentlyPairedReaders else { return [] }
        var result = recentReaders.filter { recentReader in availableReaders.contains(where: {
            $0 == recentReader && $0 != ClearentWrapperDefaults.pairedReaderInfo
        })}
        // always include default reader
        if let defaultReader = ClearentWrapperDefaults.pairedReaderInfo {
            result.insert(defaultReader, at: 0)
        }
        return result
    }
    
    internal func readerInfo(from clearentDevice:ClearentBluetoothDevice) -> ReaderInfo {
        let uuidString: UUID? = UUID(uuidString: clearentDevice.deviceId)
        return ReaderInfo(readerName: clearentDevice.friendlyName, batterylevel: nil, signalLevel: nil, isConnected: clearentDevice.connected, autojoin: false, uuid: uuidString, serialNumber: nil, version: nil)
    }
    
    // MARK - Public Logger related
    
    public func retriveLoggFileContents() -> String {
        var logs = ""
        let fileInfo = fetchLoggerFileInfo()
        if let newFileInfo = fileInfo {
            if let newLogs = readContentsOfFile(from: newFileInfo.filePath) {
                logs = newLogs
            }
        }
        return logs
    }
    
    public func fetchLogFileURL() -> URL? {
        if let fileInfo = fetchLoggerFileInfo() {
            let urlPath = URL(fileURLWithPath: fileInfo.filePath)
            return urlPath
        }
        return nil
    }
    
    public func clearLogFile() {
        DDLog.allLoggers.forEach { logger in
            if (logger.isKind(of: DDFileLogger.self)) {
                let fileLogger : DDFileLogger = logger as! DDFileLogger
                fileLogger.rollLogFile(withCompletion: nil)
            }
        }
    }
    
    
    // MARK - Private Logger related
    
    internal func createLogFile() {
        DDLog.allLoggers.forEach { logger in
            if (logger.isKind(of: DDFileLogger.self)) {
                let fl : DDFileLogger = logger as! DDFileLogger
                do {
                    if fl.currentLogFileInfo == nil {
                        try fl.logFileManager.createNewLogFile()
                    }
                } catch {
                    print("error logger")
                }
            }
        }
    }
    
    private func fetchLoggerFileInfo() -> DDLogFileInfo? {
        var resultFileInfo : DDLogFileInfo? = nil
        DDLog.allLoggers.forEach { logger in
            if (logger.isKind(of: DDFileLogger.self)) {
                let fileLogger : DDFileLogger = logger as! DDFileLogger
                let fileInfos = fileLogger.logFileManager.sortedLogFileInfos
                resultFileInfo =  (fileInfos.count > 0) ? fileInfos[0] : nil
            }
        }
        
        return resultFileInfo
    }
    
    private func readContentsOfFile(from path: String) -> String? {
        var string: String? = nil
        let urlPath = URL(fileURLWithPath: path)
        do {
            string = try String(contentsOf:urlPath, encoding: .utf8)
        } catch {
            print("Could not read log file.")
        }
        return string
    }
}
