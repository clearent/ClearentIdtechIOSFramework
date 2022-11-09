//
//  ClearentSettingsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

protocol ClearentSettingsPresenterView: AnyObject {

}

protocol ClearentSettingsPresenterProtocol {

}

class ClearentSettingsPresenter {
    // MARK: - Properties

    private weak var modalProcessingView: ClearentSettingsPresenterView?
    
    var offlineModeProgressDescription: String? {
        // TODO
        let offlineManager = ClearentWrapper.shared.retriveOfflineManager()
        let offlineTransactionsCount = offlineManager?.retriveAll().count ?? 0
        if offlineTransactionsCount > 1 {
            return String(format: "xsdk_offline_mode_transactions".localized, offlineTransactionsCount)
        } else if offlineTransactionsCount > 0 {
            return "xsdk_offline_mode_one_transaction".localized
        }
        return nil
    }
    
    var offlineModeProgressButtonTitle: String? {
        // TODO
        nil
    }

    // MARK: Init

    init(modalProcessingView: ClearentSettingsPresenterView) {
        self.modalProcessingView = modalProcessingView
    }
    
    func handleOfflineModeProgressButtonAction() {
        
    }

}
