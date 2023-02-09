//
//  HppSettingsEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 07.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

struct HppSettingsEntity: Codable {
    var payload: HppPayloadSettings
}

struct HppPayloadSettings: Codable {
    var hppSettings: HppSettings
    
    enum CodingKeys: String, CodingKey {
        case hppSettings = "hpp-settings"
    }
}

struct HppSettings: CodableProtocol {
    var hppPublicKey: String

    enum CodingKeys: String, CodingKey {
        case hppPublicKey = "hpp-public-key"
    }
}
