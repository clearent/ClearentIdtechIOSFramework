//
//  ClearentWrapperConfiguration.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 24.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CryptoKit

@objc public class ClearentWrapperConfiguration: NSObject {
    
    // MARK: - Properties

    var baseURL: String
    var apiKey: String?
    var publicKey: String?
    var enableEnhancedMessaging: Bool
    var offlineModeEncryptionKey: SymmetricKey?
    
    /// Closure called when reader info (signal, battery, reader name, connection status) is received
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    
    /// Closure called when the SDK needs to inform the user about the current merchant & terminal selected. Only used when the webAuth is used instead of API KEY for the API authentication.
    /// Returns a tuple representing the merchant and terminal names also providing the auth for processing offline transactions
    /// Only for integrators that provide the webAuth (merchant id , vt-token) for api auth
    public var provideAuthAndMerchantTerminalDetails: (() -> (String?, String?, ClearentWebAuth?))?
    
    // MARK: - Init
    
    /**
     * @param baseURL, required parameter that needs to point either to prod - gateway.clearent.net or sandbox - gateway-sb.clearent.net.
     * @param apiKey, used for API authentication. This parameter can be nil as long as web authentication is used: ClearenwtWrapper.shared.updateWebAuth(...) 
     * @publicKey, if not passed, publicKey will be fetched from the web everytime a transaction is being made
     * @offlineModeEncryptionKeyData, the key used to encrypt the offline transactions. If not passed, offline mode feature is not available
     * @enableEnhancedMessaging, enables or disables the use of enhanced messages
     */
    public init(baseURL: String, apiKey: String?, publicKey: String?, offlineModeEncryptionKeyData: Data? = nil, enableEnhancedMessaging: Bool = false) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.publicKey = publicKey
        self.enableEnhancedMessaging = enableEnhancedMessaging
        if let key = offlineModeEncryptionKeyData {
            self.offlineModeEncryptionKey = SymmetricKey(data: key)
        }
    }
}
