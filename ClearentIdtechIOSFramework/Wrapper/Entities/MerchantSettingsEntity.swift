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
    let enableTip: Bool

    enum CodingKeys: String, CodingKey {
        case enableTip = "enable-tip"
    }
}
