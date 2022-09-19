//
//  ClearentWrapperEntities.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 12.09.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public enum UserAction: String, CaseIterable {
    case pleaseWait,
         swipeTapOrInsert,
         swipeInsert,
         pressReaderButton,
         removeCard,
         tryICCAgain,
         goingOnline,
         cardSecured,
         cardHasChip,
         tryMSRAgain,
         useMagstripe,
         transactionStarted,
         transactionFailed,
         tapFailed,
         connectionTimeout,
         noInternet,
         noBluetooth,
         noBluetoothPermission,
         failedToStartSwipe,
         badChip,
         cardUnsupported,
         cardBlocked,
         cardExpired,
         authorizing,
         processing,
         amountNotAllowedForTap,
         chipNotRecognized
    

    var message: String {
        switch self {
        case .pleaseWait:
            return CLEARENT_PLEASE_WAIT
        case .swipeTapOrInsert:
            return CLEARENT_USER_ACTION_3_IN_1_MESSAGE
        case .swipeInsert:
            return CLEARENT_USER_ACTION_2_IN_1_MESSAGE
        case .pressReaderButton:
            return CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE
        case .removeCard:
            return CLEARENT_CARD_READ_OK_TO_REMOVE_CARD
        case .tryICCAgain:
            return CLEARENT_TRY_ICC_AGAIN
        case .tryMSRAgain:
            return CLEARENT_TRY_MSR_AGAIN
        case .goingOnline:
            return CLEARENT_TRANSLATING_CARD_TO_TOKEN
        case .cardSecured:
            return CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE
        case .cardHasChip:
            return CLEARENT_CHIP_FOUND_ON_SWIPE
        case .useMagstripe:
            return CLEARENT_USE_MAGSTRIPE
        case .transactionStarted:
            return CLEARENT_RESPONSE_TRANSACTION_STARTED
        case .transactionFailed:
            return CLEARENT_RESPONSE_TRANSACTION_FAILED
        case .tapFailed:
            return CLEARENT_CONTACTLESS_FALLBACK_MESSAGE
        case .failedToStartSwipe:
            return CLEARENT_PULLED_CARD_OUT_EARLY
        case .badChip:
            return CLEARENT_BAD_CHIP
        case .cardUnsupported:
            return CLEARENT_CARD_UNSUPPORTED
        case .cardBlocked:
            return CLEARENT_CARD_BLOCKED
        case .cardExpired:
            return CLEARENT_CARD_EXPIRED
        case .connectionTimeout:
            return CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE
        case .noInternet:
            return ClearentConstants.Localized.Internet.noConnection
        case .noBluetooth:
            return ClearentConstants.Localized.Bluetooth.turnedOff
        case .noBluetoothPermission:
            return ClearentConstants.Localized.Bluetooth.noPermission
        case .authorizing:
            return CLEARENT_TRANSACTION_AUTHORIZING
        case .processing:
            return CLEARENT_TRANSACTION_PROCESSING
        case .amountNotAllowedForTap:
            return CLEARENT_TAP_OVER_MAX_AMOUNT
        case .chipNotRecognized:
            return CLEARENT_CHIP_UNRECOGNIZED
        }
    }
    
    var description: String? {
        if ClearentWrapper.shared.enableEnhancedMessaging, let dict = ClearentWrapper.shared.enhancedMessagesDict, let result = dict[message] {
            return result == ClearentConstants.Messaging.suppress ? nil : result
        }
        return message
    }

    static func action(for text: String) -> UserAction? {
        if let action = UserAction.allCases.first(where: { $0.message == text }) {
            return action
        }
        return (text == ClearentConstants.Messaging.suppress) ? nil :UserAction(rawValue: text)
    }
}
