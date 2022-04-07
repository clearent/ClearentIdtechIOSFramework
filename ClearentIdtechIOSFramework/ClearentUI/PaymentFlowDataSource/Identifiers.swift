//
//  Identifiers.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

enum FlowDataKeys : String {
    case readerStatus = "xplor_reader_status"
    case readerBatteryLevel = "xplor_battery_level"
    case readerName = "xplor_reader_name"
    case icon = "xplor_icon_type"
    case title = "xplor_title"
    case description = "xplor_description"
    case userAction = "xplor_user_action_type"
}

enum FlowFeedbackType {
    case error, info, warning
}

enum FlowiconType {
    case insert_card, press_button, transaction_completed, loading
}

enum ProcessType {
    case pairing
    case payment
}
