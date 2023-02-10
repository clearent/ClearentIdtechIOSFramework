//
//  ClearentWrapperDefaults.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

private struct DefaultKeys {
    static let terminalSettings = "\(UserDefaultsPersistence.clearentSdkPrefix)_terminal_settings"
    static let recentlyPairedReadersKey = "\(UserDefaultsPersistence.clearentSdkPrefix)_recently+paired_readers_key"
    static let skipOnboarding = "\(UserDefaultsPersistence.clearentSdkPrefix)_skip_onboarding_key"
    static let enableOfflineMode = "\(UserDefaultsPersistence.clearentSdkPrefix)_enable_offline_mode"
    static let enableOfflinePromptMode = "\(UserDefaultsPersistence.clearentSdkPrefix)_enable_offline_prompt_mode"
    static let enableEmailReceipt = "\(UserDefaultsPersistence.clearentSdkPrefix)_enable_email_receipt"
}

public class ClearentWrapperDefaults: UserDefaultsPersistence {
    static var lastPairedReaderInfo: ReaderInfo?
    
    static internal(set) var terminalSettings: TerminalSettings? {
        get {
            if let savedReaderData = retrieveValue(forKey: DefaultKeys.terminalSettings) as? Data {
                let decoder = JSONDecoder()
                let terminalSettings = try? decoder.decode(TerminalSettings.self, from: savedReaderData)
                return terminalSettings
            }
            
            return nil
        }
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                save(encoded, forKey:  DefaultKeys.terminalSettings)
            }
        }
    }
    
    static internal(set) var recentlyPairedReaders: [ReaderInfo]? {
           
           get {
               if let savedReaderData = retrieveValue(forKey: DefaultKeys.recentlyPairedReadersKey) as? Data {
                   let decoder = JSONDecoder()
                   let loadedReaderInfo = try? decoder.decode([ReaderInfo].self, from: savedReaderData)
                   return loadedReaderInfo
               }
               
               return nil
           }
           
           set {
               let encoder = JSONEncoder()
               if let encoded = try? encoder.encode(newValue) {
                   save(encoded, forKey:  DefaultKeys.recentlyPairedReadersKey)
               }
           }
       }
    
    internal static var skipOnboarding: Bool {
        get {
            return UserDefaults.standard.bool(forKey: DefaultKeys.skipOnboarding)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultKeys.skipOnboarding)
        }
    }
    
    static var enableOfflineMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: DefaultKeys.enableOfflineMode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultKeys.enableOfflineMode)
        }
    }
    
    static var enableOfflinePromptMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: DefaultKeys.enableOfflinePromptMode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultKeys.enableOfflinePromptMode)
        }
    }
    
    static var enableEmailReceipt: Bool {
        get {
            return UserDefaults.standard.bool(forKey: DefaultKeys.enableEmailReceipt)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultKeys.enableEmailReceipt)
        }
    }
}

extension ClearentWrapperDefaults {
    static internal(set) var pairedReaderInfo: ReaderInfo? {
        get {
            lastPairedReaderInfo
        }
        set {
            setupPairedReader(with: newValue)
        }
    }
    
    private static func setupPairedReader(with newValue: ReaderInfo?) {
        ClearentWrapper.configuration.readerInfoReceived?(newValue)
        
        if var newPairedReader = newValue {
            // set first pairedReader with autojoin true
            if recentlyPairedReaders?.count ?? 0 == 0 {
                newPairedReader.autojoin = true
            }
            ClearentWrapper.shared.addReaderToRecentlyUsed(reader: newPairedReader)
            lastPairedReaderInfo = newPairedReader
        }
        // if pairedReader is nil, we need to set connected and autojoin to false for the corresponding item from the previously paired readers
        else {
            if var defaultReaderInfo = lastPairedReaderInfo {
                defaultReaderInfo.isConnected = false
                defaultReaderInfo.autojoin = false
                ClearentWrapper.shared.updateReaderInRecentlyUsed(reader: defaultReaderInfo)
            }
            lastPairedReaderInfo = nil
        }
    }
}
