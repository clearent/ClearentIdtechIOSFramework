//
//  UserDefaultsPersistence.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public class UserDefaultsPersistence {
    
    static let userDefaults = UserDefaults(suiteName: "xsdk_user_default_container_key")
    
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
        userDefaults.synchronize()
    }
}
