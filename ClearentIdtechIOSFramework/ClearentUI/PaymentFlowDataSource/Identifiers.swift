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
    case readerInfo, graphicType, title, description, userAction, devicesFound, recentlyPaired, hint, input
}

public enum FlowFeedbackType {
    case error, info, warning, searchDevices, showReaders, pairingDoneInfo, renameReaderDone
}

public enum ProcessType: Equatable {
    case pairing(withReader: ReaderInfo? = nil), payment, showReaders, renameReader
    
    public static func == (lhs: ProcessType, rhs: ProcessType) -> Bool {
        switch (lhs,rhs) {
        case (.pairing, .pairing): return true
        case (.payment, .payment): return true
        case (.showReaders, .showReaders): return true
        case (.renameReader, .renameReader): return true
        default: return false
        }
    }
}

public enum ReaderStatusHeaderViewState {
    case collapsed, expanded
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

    case cancel, retry, pair, done, pairNewReader, settings, pairInFlow, addReaderName, renameReaderLater

    var title: String {
        switch self {
        case .cancel:
            return "xsdk_user_action_cancel".localized
        case .retry:
            return "xsdk_user_action_retry".localized
        case .pair, .pairInFlow:
            return "xsdk_user_action_pair".localized
        case .done:
            return "xsdk_user_action_done".localized
        case .pairNewReader:
            return "xsdk_pair_new_reader".localized
        case .settings:
            return "xsdk_user_action_settings".localized
        case .addReaderName:
            return "xsdk_user_action_addName".localized
        case .renameReaderLater:
            return "xsdk_user_action_later".localized
        }
    }
}

public enum FlowInputType {
    case nameInput
}
