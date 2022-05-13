//
//  Identifiers.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

enum SignalLevel : Int {
    case good = 0, medium, bad
}

enum FlowDataKeys {
    case readerInfo, graphicType, title, description, userAction, devicesFound, devicesFound2, hint
}

enum FlowFeedbackType {
    case error, info, warning, searchDevices
}

enum FlowGraphicType {
    case insert_card, press_button, transaction_completed, loading, error, warning, readerButton, reader, pairedReader, pairingSuccessful
    
    var iconName: String? {
        switch self {
        case .insert_card:
            return ClearentConstants.IconName.cardInteraction
        case .press_button:
            return ClearentConstants.IconName.pressButtonOnReader
        case .transaction_completed:
            return ClearentConstants.IconName.success
        case .error:
            return ClearentConstants.IconName.error
        case .warning:
            return ClearentConstants.IconName.warning
        case .loading:
            return nil
        case .readerButton:
            // TO DO - add the correct asset
            return nil
        case .reader:
            // TO DO - add the correct asset
            return nil
        case .pairedReader:
            return ClearentConstants.IconName.reader
        case .pairingSuccessful:
            return ClearentConstants.IconName.pairingSuccessful
        }
    }
}

public enum FlowButtonType {
    case cancel, retry, pair, done, pairNewReader
    
    var title: String {
        switch self {
        case .cancel:
            return "xsdk_user_action_cancel".localized
        case .retry:
            return "xsdk_user_action_retry".localized
        case .pair:
            return "xsdk_user_action_pair".localized
        case .done:
            return "xsdk_user_action_done".localized
        case .pairNewReader:
            return "xsdk_pair_new_reader".localized
        }
    }
}

public enum ProcessType {
    case pairing
    case payment
    case showReaders
}

public enum ReaderStatusHeaderViewState {
    case collapsed
    case expanded
}
