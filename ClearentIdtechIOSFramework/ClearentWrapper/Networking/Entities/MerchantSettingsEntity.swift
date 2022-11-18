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

internal enum ServiceFeeProgrammType: String {
    case surcharge = "SURCHARGE"
    case non_cash_adjustments = "NON_CASH_ADJUSTMENT"
    case empower_lite = "EMPOWER_LITE"
    case service_fee = "SERVICE_FEE"
    case convinience_fee = "CONVENIENCE_FEE"
}

internal enum ServiceFeeType: String {
    case percentage = "PERCENTAGE"
    case flatfee = "FLATFEE"
}

internal enum ServiceFeeState: String {
    case enabled = "ENABLED"
    case disabled = "DISABLED"
}

struct TerminalSettings: CodableProtocol {
    let tipEnabled: Bool
    let serviceFeeState : String?
    let serviceFee : String?
    let serviceFeeType : String?
    let serviceFeeProgram : String?
    
    enum CodingKeys: String, CodingKey {
        case tipEnabled = "enable-tip"
        case serviceFeeState = "service-fee-state"
        case serviceFee = "service-fee"
        case serviceFeeType = "service-fee-type"
        case serviceFeeProgram = "service-fee-program-type"
    }
}
