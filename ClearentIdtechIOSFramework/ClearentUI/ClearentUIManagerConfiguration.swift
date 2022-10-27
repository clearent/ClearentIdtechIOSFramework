//
//  ClearentUIManagerConfiguration.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 24.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

@objc public class ClearentUIManagerConfiguration: ClearentWrapperConfiguration {
    public var tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages
    public var signatureEnabled: Bool = true

    public override init(baseURL: String, apiKey: String, publicKey: String, enableEnhancedMessaging: Bool = false, enableOfflineMode: Bool = false, readerInfoReceived: ((ReaderInfo?) -> Void)?) {
        super.init(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, enableEnhancedMessaging: enableEnhancedMessaging, enableOfflineMode: enableOfflineMode, readerInfoReceived: readerInfoReceived)
        setupWrapperConfiguration()
    }
    
    convenience init(baseURL: String, apiKey: String, publicKey: String, enableEnhancedMessaging: Bool = false, enableOfflineMode: Bool = false, readerInfoReceived: ((ReaderInfo?) -> Void)?, tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages, signatureEnabled: Bool = true) {
        self.init(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, enableEnhancedMessaging: enableEnhancedMessaging, enableOfflineMode: enableOfflineMode, readerInfoReceived: readerInfoReceived)
        self.tipAmounts = tipAmounts
        self.signatureEnabled = signatureEnabled
        setupWrapperConfiguration()
    }
    
    private func setupWrapperConfiguration() {
        ClearentWrapper.shared.initialize(with: ClearentWrapperConfiguration(baseURL: baseURL, apiKey: apiKey, publicKey: publicKey, enableEnhancedMessaging: enableEnhancedMessaging, enableOfflineMode: enableOfflineMode, readerInfoReceived: readerInfoReceived))
    }
}
