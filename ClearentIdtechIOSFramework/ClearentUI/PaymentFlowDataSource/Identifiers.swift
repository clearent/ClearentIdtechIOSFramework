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
    case readerInfo, graphicType, title, description, userAction, devicesFound, recentlyPaired, hint, input, tips, serviceFee, signature, manualEntry, error
}

public enum FlowFeedbackType {
    case error, info, warning, searchDevices, showReaders, pairingDoneInfo, renameReaderDone, signature, signatureError
}

public enum ProcessType: Equatable {
    case pairing(withReader: ReaderInfo? = nil), payment, showReaders, renameReader, showSettings
    
    public static func == (lhs: ProcessType, rhs: ProcessType) -> Bool {
        switch (lhs, rhs) {
        case (.pairing, .pairing),
            (.payment, .payment),
            (.showReaders, .showReaders),
            (.renameReader, .renameReader),
            (.showSettings, .showSettings):
            return true
        default: return false
        }
    }
}

enum FlowGraphicType {
    case animatedCardInteraction, staticCardInteraction, press_button, transaction_completed, loading, error, warning, smallWarning, pairedReader, pairingSuccessful
    
    var name: String? {
        switch self {
        case .animatedCardInteraction:
            return ClearentConstants.AnimationName.cardInteraction
        case .staticCardInteraction:
            return ClearentConstants.IconName.staticCardInteraction
        case .press_button:
            return ClearentConstants.IconName.pressButtonOnReader
        case .transaction_completed:
            return ClearentConstants.IconName.success
        case .error:
            return ClearentConstants.IconName.error
        case .warning:
            return ClearentConstants.IconName.warning
        case .smallWarning:
            return ClearentConstants.IconName.smallWarning
        case .loading:
            return nil
        case .pairedReader:
            return ClearentConstants.IconName.reader
        case .pairingSuccessful:
            return ClearentConstants.IconName.pairingSuccessful
        }
    }
}

public enum FlowButtonType {
    case cancel, retry, pair, done, skipSignature, pairNewReader, settings, pairInFlow, addReaderName, renameReaderLater, transactionWithTip, transactionWithoutTip, manuallyEnterCardInfo, acceptOfflineMode, denyOfflineMode, confirmOfflineModeWarningMessage, transactionWithServiceFee

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
        case .transactionWithServiceFee:
            return transactionWithServiceFeeTitle()
        case .manuallyEnterCardInfo:
            return ClearentConstants.Localized.Error.manualEntry
        case .acceptOfflineMode:
            return ClearentConstants.Localized.OfflineMode.offlineModeConfirmOption
        case .denyOfflineMode:
            return ClearentConstants.Localized.OfflineMode.offlineModeCancelOption
        case .confirmOfflineModeWarningMessage:
            return ClearentConstants.Localized.OfflineMode.offlineModeWarningMessageConfirm
        }
    }

    func transactionWithTipTitle(for amount: Double? = nil) -> String {
        guard let amount = amount else { return "" }
        let formattedText = ClearentMoneyFormatter.formattedWithSymbol(from: amount)
        return String(format: ClearentConstants.Localized.Tips.withTip, formattedText)
    }
    
    func transactionWithServiceFeeTitle(for amount: String? = nil) -> String {
        guard let amount = amount else { return "" }
        return String(format: ClearentConstants.Localized.Tips.withTip, amount)
    }
}

public enum FlowInputType {
    case nameInput
}
