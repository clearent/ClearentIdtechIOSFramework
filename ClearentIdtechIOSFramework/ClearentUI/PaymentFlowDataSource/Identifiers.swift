//
//  Identifiers.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, bundle: Bundle(for: FlowDataProvider.self), comment: self)
    }
}

enum FlowDataKeys {
    case readerConnected, readerBatteryLevel, readerSignalLevel, readerName, graphicType, title, description, userAction
}

enum FlowFeedbackType {
    case error, info, warning
}

enum FlowGraphicType {
    case insert_card, press_button, transaction_completed, loading, error, warning
}

enum ProcessType {
    case pairing
    case payment
}
