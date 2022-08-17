//
//  Identifiers.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

enum SignalLevel: Int {
    case good = 0, medium, bad
}

enum FlowDataKeys {
    case readerInfo, graphicType, title, description, userAction, devicesFound, recentlyPaired, hint, input, tips, signature, manualEntry
}

public enum FlowFeedbackType {
    case error, info, warning, searchDevices, showReaders, pairingDoneInfo, renameReaderDone, signature, signatureError
}

public enum ProcessType: Equatable {
    case pairing(withReader: ReaderInfo? = nil), payment, showReaders, renameReader
    
    public static func == (lhs: ProcessType, rhs: ProcessType) -> Bool {
        switch (lhs, rhs) {
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
    case cancel, retry, pair, done, skipSignature, pairNewReader, settings, pairInFlow, addReaderName, renameReaderLater, transactionWithTip, transactionWithoutTip, manuallyEnterCardInfo

    var title: String {
        switch self {
        case .cancel:
            return ClearentConstants.Localized.Error.cancel
        case .retry:
            return ClearentConstants.Localized.Error.retry
        case .pair, .pairInFlow:
            return ClearentConstants.Localized.Pairing.pair
        case .done:
            return ClearentConstants.Localized.Pairing.done
        case .skipSignature:
            return ClearentConstants.Localized.Signature.skip
        case .pairNewReader:
            return ClearentConstants.Localized.Pairing.pairNewReader
        case .settings:
            return ClearentConstants.Localized.Pairing.settings
        case .addReaderName:
            return ClearentConstants.Localized.Pairing.addName
        case .renameReaderLater:
            return ClearentConstants.Localized.Pairing.later
        case .transactionWithTip:
            return transactionWithTipTitle()
        case .transactionWithoutTip:
            return ClearentConstants.Localized.Tips.withoutTip
        case .manuallyEnterCardInfo:
            return ClearentConstants.Localized.Error.manualEntry
        }
    }

    func transactionWithTipTitle(for amount: Double? = nil) -> String {
        guard let amount = amount else { return "" }
        let formattedText = ClearentMoneyFormatter.formattedWithSymbol(from: amount)
        return String(format: ClearentConstants.Localized.Tips.withTip, formattedText)
    }
}

public enum FlowInputType {
    case nameInput
}
