//
//  ClearentWrapperDefaults.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import AVFAudio

private struct DefaultKeys {
    static let recentlyPairedReadersKey = "xsdk_recently+paired_readers_key"
    static let skipOnboarding = "xsdk_skip_onboarding_key"
}

public class ClearentWrapperDefaults: UserDefaultsPersistence {
    static var lastPairedReaderInfo: ReaderInfo?
    
    internal static var recentlyPairedReaders: [ReaderInfo]? {
           
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
}

extension ClearentWrapperDefaults {
    internal static var pairedReaderInfo: ReaderInfo? {
        get {
            lastPairedReaderInfo
        }
        set {
            setupPairedReader(with: newValue)
        }
    }
    
    private static func setupPairedReader(with newValue: ReaderInfo?) {
        ClearentWrapper.shared.readerInfoReceived?(newValue)
        
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
