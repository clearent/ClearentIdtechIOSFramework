//
//  MerchantSettingsEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

struct MerchantSettingsEntity: Codable {
    var payload: PayloadSettings
}

struct PayloadSettings: Codable {
    let terminalSettings: TerminalSettings

    enum CodingKeys: String, CodingKey {
        case terminalSettings = "terminal-settings"
    }
}

struct TerminalSettings: Codable {
    let merchantID, terminalName, terminalID, commerceType: String
    let enableTip: Bool
    let batchTimeUTC: String
    let enableAutoCloseBatch: Bool
    let serviceFeeState, businessPhone: String

    enum CodingKeys: String, CodingKey {
        case merchantID = "merchant-id"
        case terminalName = "terminal-name"
        case terminalID = "terminal-id"
        case commerceType = "commerce-type"
        case enableTip = "enable-tip"
        case batchTimeUTC = "batch-time-utc"
        case enableAutoCloseBatch = "enable-auto-close-batch"
        case serviceFeeState = "service-fee-state"
        case businessPhone = "business-phone"
    }
}
