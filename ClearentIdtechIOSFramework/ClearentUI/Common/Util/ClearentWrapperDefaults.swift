//
//  ClearentWrapperDefaults.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

private struct DefaultKeys {
    static let readerFriendlyNameKey = "xsdk_reader_friendly_name_key"
    static let recentlyPairedReadersKey = "xsdk_recently+paired_readers_key"
}

public class ClearentWrapperDefaults: UserDefaultsPersistence {
        
    private static var defaultReaderInfo: ReaderInfo? {
           
           get {
               if let savedReaderData = retrieveValue(forKey: DefaultKeys.readerFriendlyNameKey) as? Data {
                   let decoder = JSONDecoder()
                   let loadedReaderInfo = try? decoder.decode(ReaderInfo.self, from: savedReaderData)
                   return loadedReaderInfo
               }
               
               return nil
           }
           
           set {
               let encoder = JSONEncoder()
               if let encoded = try? encoder.encode(newValue) {
                   save(encoded, forKey:  DefaultKeys.readerFriendlyNameKey)
               }
           }
       }
    
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
}

extension ClearentWrapperDefaults {
    internal static var pairedReaderInfo: ReaderInfo? {
        get {
            defaultReaderInfo
        }
        set {
            ClearentWrapper.shared.readerInfoReceived?(newValue)
            defaultReaderInfo = newValue
        }
    }
}
