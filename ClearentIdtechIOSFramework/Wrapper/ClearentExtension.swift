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
                currentReader.batterylevel = nil
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
    
    internal func addReaderToRecentlyUsed(reader:ReaderInfo) {
        var newReader = reader
        newReader.isConnected = false
        newReader.batterylevel = nil
        newReader.signalLevel = nil
        guard let existingReaders = ClearentWrapperDefaults.recentlyPairedReaders else {
            ClearentWrapperDefaults.recentlyPairedReaders = [newReader]
            return
        }
        
        let readersWithSameName = existingReaders.filter { $0.readerName == newReader.readerName }
        if (readersWithSameName.count == 0) {
            var newReaders : [ReaderInfo] = [newReader]
            newReaders.append(contentsOf: existingReaders)
            ClearentWrapperDefaults.recentlyPairedReaders = newReaders
        }
    }
    
    internal func removeReaderFromRecentlyUsed(reader: ReaderInfo) {
        guard var existingReaders = ClearentWrapperDefaults.recentlyPairedReaders else { return }
        
        let readersWithSameName = existingReaders.filter { $0.readerName == reader.readerName }
        if (readersWithSameName.count == 1) {
            existingReaders.removeAll { current in
                current.readerName == reader.readerName
            }
        }
        
        ClearentWrapperDefaults.recentlyPairedReaders = existingReaders
    }
    
    internal func fetchRecentlyAndAvailableReaders(devices: [ClearentBluetoothDevice]) -> [ReaderInfo] {
        
        let availableReaders = devices.compactMap { readerInfo(from: $0)}
        if let savedReader = ClearentWrapperDefaults.pairedReaderInfo {
            removeReaderFromRecentlyUsed(reader:savedReader)
            addReaderToRecentlyUsed(reader: savedReader)
        }
        guard let recentReaders = ClearentWrapperDefaults.recentlyPairedReaders else {return []}
       
        let result = availableReaders.filter {currentReader in recentReaders.contains(where: { $0.readerName == currentReader.readerName }) }
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
