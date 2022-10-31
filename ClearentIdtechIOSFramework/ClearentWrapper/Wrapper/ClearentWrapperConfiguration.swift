//
//  ClearentWrapperConfiguration.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 24.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

@objc public class ClearentWrapperConfiguration: NSObject {
    public var baseURL: String
    public var apiKey: String
    public var publicKey: String
    /// Enables or disables the use of enhanced messages
    var enableEnhancedMessaging: Bool
    /// Enables or disables the use of the store & forward feature
    var enableOfflineMode: Bool
    /// Closure called when reader info (signal, battery, reader name, connection status) is received
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    
    public init(baseURL: String, apiKey: String, publicKey: String, enableEnhancedMessaging: Bool = false, enableOfflineMode: Bool = false) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
        self.enableEnhancedMessaging = enableEnhancedMessaging
        self.enableOfflineMode = enableOfflineMode
    }
}
