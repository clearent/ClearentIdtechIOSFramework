//
//  ClearentUIManagerConfiguration.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 24.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CryptoKit

@objc public class ClearentUIManagerConfiguration: ClearentWrapperConfiguration {
    public var tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages
    public var signatureEnabled: Bool = true

    // MARK: - Init
    
    @objc public init(baseURL: String, apiKey: String? = nil, publicKey: String, enableEnhancedMessaging: Bool = false, tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages, signatureEnabled: Bool = true) {
        self.tipAmounts = tipAmounts
        self.signatureEnabled = signatureEnabled
        
        super.init(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, enableEnhancedMessaging: enableEnhancedMessaging)
        
        ClearentWrapper.shared.initialize(with: ClearentWrapperConfiguration(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, enableEnhancedMessaging: enableEnhancedMessaging))
    }
    
    @objc public init(baseURL: String, apiKey: String? = nil, publicKey: String, offlineModeEncryptionKeyData: Data, enableEnhancedMessaging: Bool = false, tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages, signatureEnabled: Bool = true) {
        self.tipAmounts = tipAmounts
        self.signatureEnabled = signatureEnabled
        
        super.init(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, offlineModeEncryptionKeyData: offlineModeEncryptionKeyData, enableEnhancedMessaging: enableEnhancedMessaging)
        
        ClearentWrapper.shared.initialize(with: ClearentWrapperConfiguration(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, offlineModeEncryptionKeyData: offlineModeEncryptionKeyData, enableEnhancedMessaging: enableEnhancedMessaging))
    }
}
