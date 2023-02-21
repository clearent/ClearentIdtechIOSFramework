//
//  ClearentUIManagerConfiguration.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 24.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CryptoKit

@objc public class ClearentUIManagerConfiguration: ClearentWrapperConfiguration {
    
    // MARK: - Properties
    
    var tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages
    var signatureEnabled: Bool = true

    // MARK: - Init
    
    /**
     * @param baseURL, required parameter that needs to point either to prod - gateway.clearent.net or sandbox - gateway-sb.clearent.net.
     * @param apiKey, used for API authentication. This parameter can be nil as long as web authentication is used: ClearenwtWrapper.shared.updateWebAuth(...)
     * @publicKey, if not passed, publicKey will be fetched from the web everytime a transaction is being made
     * @offlineModeEncryptionKeyData, the key used to encrypt the offline transactions. If not passed, offline mode feature is not available
     * @enableEnhancedMessaging, enables or disables the use of enhanced messages
     * @tipAmounts, an array of tip percentages the client select from during the payment process
     * @signatureEnabled, if true, a screen will be displayed during the payment process where the client can draw the signature
     */
    @objc public init(baseURL: String, apiKey: String? = nil, publicKey: String? = nil, offlineModeEncryptionKeyData: Data? = nil, enableEnhancedMessaging: Bool = false, tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages, signatureEnabled: Bool = true) {
        self.tipAmounts = tipAmounts
        self.signatureEnabled = signatureEnabled
        
        super.init(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, offlineModeEncryptionKeyData: offlineModeEncryptionKeyData, enableEnhancedMessaging: enableEnhancedMessaging)
        
        ClearentWrapper.shared.initialize(with: ClearentWrapperConfiguration(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, offlineModeEncryptionKeyData: offlineModeEncryptionKeyData, enableEnhancedMessaging: enableEnhancedMessaging))
    }
}
