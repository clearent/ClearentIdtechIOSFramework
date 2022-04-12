//
//  Identifiers.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public enum FlowDataKeys {
    case readerConnected, readerBatteryLevel, readerSignalLevel, readerName, graphicType, title, description, userAction
}

enum FlowFeedbackType {
    case error, info, warning
}

enum FlowGraphicType {
    case insert_card, press_button, transaction_completed, loading, error, warning
    
    var iconName: String {
        switch self {
        case .insert_card:
            return ClearentConstants.IconName.cardInteraction
        case .press_button:
            return ClearentConstants.IconName.pressButtonOnReader
        case .transaction_completed:
            return ClearentConstants.IconName.success
        case .loading:
            return ClearentConstants.IconName.loading
        case .error:
            return ClearentConstants.IconName.error
        case .warning:
            return ClearentConstants.IconName.warning
        }
    }
}

enum ProcessType {
    case pairing
    case payment
}
