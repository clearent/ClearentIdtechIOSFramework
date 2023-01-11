//
//  UserDefaultsPersistence.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public class UserDefaultsPersistence {
    static let clearentSdkPrefix = "xsdk"
    static let userDefaults = UserDefaults(suiteName: "\(clearentSdkPrefix)_user_default_container_key")
    
    static func save(_ value: Any, forKey key: String) {
        guard let userDefaults = userDefaults else { return }
        userDefaults.set(value, forKey: key)
    }
    
    static func retrieveValue(forKey key: String) -> Any? {
        guard let userDefaults = userDefaults else { return nil }
        return userDefaults.value(forKey: key)
    }
    
    static func removeValue(forKey key: String) {
        guard let userDefaults = userDefaults else { return }
        userDefaults.removeObject(forKey: key)
    }
    
    /// Deletes all saved user defaults which contain the clearentSdkPrefix
    static func removeAllValues() {
        guard let userDefaults = userDefaults else { return }
        let allSavedKeys = userDefaults.dictionaryRepresentation().map { $0.key }
        let identifiers = allSavedKeys.filter { $0.contains(clearentSdkPrefix) }
        for key in identifiers {
            removeValue(forKey: key)
        }
    }
}
