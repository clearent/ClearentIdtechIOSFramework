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
    case readerBatteryLevel = "xplor__battery_level"
    case readerName = "xplor_reader_name"
    case icon = "xplor_icon_type"
    case title = "xplor_title"
    case description = "xplor_description"
    case userAction = "xplor_user_action_type"
}

enum FlowFeedbackType : String {
    case error = "xplor_error_type", info = "xplor_info_type", warning = "xplor_warning_type"
}

enum ProcessType {
    case pairing
    case payment
}

enum FeedBackStepType {
    case insertCard
    case tryAgain
    case generalError
}
