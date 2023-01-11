//
//  MerchantSettingsEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

struct TerminalSettingsEntity: Codable {
    var payload: PayloadSettings
}

struct PayloadSettings: Codable {
    let terminalSettings: TerminalSettings

    enum CodingKeys: String, CodingKey {
        case terminalSettings = "terminal-settings"
    }
}

internal enum ServiceFeeProgramType: String, Codable {
    case SURCHARGE, NON_CASH_ADJUSTMENT, EMPOWER_LITE, SERVICE_FEE, CONVENIENCE_FEE
}

internal enum ServiceFeeType: String, Codable {
    case PERCENTAGE, FLATFEE
}

internal enum ServiceFeeState: String, Codable {
    case ENABLED, DISABLED
}

struct TerminalSettings: CodableProtocol {
    let tipEnabled: Bool
    let serviceFeeState : ServiceFeeState?
    let serviceFee : String?
    let serviceFeeType : ServiceFeeType?
    let serviceFeeProgram : ServiceFeeProgramType?
    
    enum CodingKeys: String, CodingKey {
        case tipEnabled = "enable-tip"
        case serviceFeeState = "service-fee-state"
        case serviceFee = "service-fee"
        case serviceFeeType = "service-fee-type"
        case serviceFeeProgram = "service-fee-program-type"
    }
}
