//
//  ClearentLoggerExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 20.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import CocoaLumberjack

extension ClearentWrapper {
    
    internal func addReaderToRecentlyUsed(reader:ReaderInfo) {
        guard let existingReaders = ClearentWrapperDefaults.recentlyPairedReaders else {
            ClearentWrapperDefaults.recentlyPairedReaders = [reader]
            return
        }
        
        let readersWithSameName = existingReaders.filter { $0.readerName == reader.readerName }
        if (readersWithSameName.count == 0) {
            var newReaders : [ReaderInfo] = [reader]
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
        guard let recentReaders = ClearentWrapperDefaults.recentlyPairedReaders else {return availableReaders}
       
        let result = availableReaders.filter {currentReader in recentReaders.contains(where: { $0.readerName == currentReader.readerName }) }
        return result
    }
    
    internal func readerInfo(from clearentDevice:ClearentBluetoothDevice) -> ReaderInfo {
        let uuidString: UUID? = UUID(uuidString: clearentDevice.deviceId)
        return ReaderInfo(name: clearentDevice.friendlyName, batterylevel:nil , signalLevel: nil, connected: clearentDevice.connected, uuid: uuidString)
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
