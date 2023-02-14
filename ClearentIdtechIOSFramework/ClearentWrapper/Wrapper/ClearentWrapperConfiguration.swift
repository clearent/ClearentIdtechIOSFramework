//
//  ClearentWrapperConfiguration.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 24.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CryptoKit

@objc public class ClearentWrapperConfiguration: NSObject {
    public var baseURL: String
    public var apiKey: String?
    public var publicKey: String?
    
    /// Enables or disables the use of enhanced messages
    var enableEnhancedMessaging: Bool

    /// The key used to encrypt the offline transactions
    var offlineModeEncryptionKey: SymmetricKey?
    
    /// Closure called when reader info (signal, battery, reader name, connection status) is received
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    
    /// Closure called when the SDK need to inform the user about the current merchant & temrinal selected , only used when the webAuth is used instead of API KEY for the API authentication
    /// Returns a touple represeting the merchant and terninal names also providing the auth for processing offline transactions
    /// Only for integrators that provide the webAuth (merchant id , vt-token) for api auth
    public var provideAuthAndMerchantTerminalDetails: (() -> (String?, String?, ClearentWebAuth?))?
    
    // MARK: - Init
    
    public init(baseURL: String, apiKey: String?, publicKey: String?, enableEnhancedMessaging: Bool = false) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
        self.enableEnhancedMessaging = enableEnhancedMessaging
    }
    
    public init(baseURL: String, apiKey: String?, publicKey: String?, offlineModeEncryptionKeyData: Data, enableEnhancedMessaging: Bool = false) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
        self.offlineModeEncryptionKey = SymmetricKey(data: offlineModeEncryptionKeyData)
        self.enableEnhancedMessaging = enableEnhancedMessaging
    }
}
