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
}

class ClearentWrapperDefaults: UserDefaultsPersistence {
        
    static var pairedReaderFriendlyName: String? {
           
           get {
               guard let persistentValue = retrieveValue(forKey: DefaultKeys.readerFriendlyNameKey) as? String else {
                   return nil
               }
               return persistentValue
           }
           
           set {
               save(newValue as Any, forKey:  DefaultKeys.readerFriendlyNameKey)
           }
       }
}
