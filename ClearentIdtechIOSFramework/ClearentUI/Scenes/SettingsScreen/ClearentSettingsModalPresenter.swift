//
//  ClearentSettingsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

protocol ClearentSettingsPresenterView: AnyObject {
    func removeOfflineStatusView()
    func updateOfflineStatusView(inProgress: Bool)
    func presentReportScreen()
}

protocol ClearentSettingsPresenterProtocol {

}

class ClearentSettingsPresenter {
    // MARK: - Properties

    private weak var settingsPresenterView: ClearentSettingsPresenterView?
    
    var offlineStatusDescription: String?
    
    var offlineStatusDescriptionColor: UIColor?

    var offlineStatusButtonTitle: String?
    
    var offlineStatusButtonAction: (() -> Void)?

    // MARK: Init

    init(settingsPresenterView: ClearentSettingsPresenterView) {
        self.settingsPresenterView = settingsPresenterView
    }
    
    func updateOfflineStatus() {
        guard let offlineManager = ClearentWrapper.shared.retriveOfflineManager() else { return }
        
        if offlineManager.containsReport() {
            if offlineManager.reportContainsErrors() {
                setupUploadFail()
            } else {
                setupUploadSuccessfully()
            }
        } else {
            let pendingTransactions = offlineManager.retriveAll().filter({ $0.errorStatus == nil }).count
            if pendingTransactions > 0 {
                setupPendingTransactions(counter: pendingTransactions)
            } else {
                settingsPresenterView?.removeOfflineStatusView()
            }
        }
        settingsPresenterView?.updateOfflineStatusView(inProgress: false)
    }

    func setupPendingTransactions(counter: Int) {
        if counter > 1 {
            offlineStatusDescription = String(format: "xsdk_offline_mode_transactions".localized, counter)
        } else {
            offlineStatusDescription = "xsdk_offline_mode_one_transaction".localized
        }
        offlineStatusButtonTitle = "xsdk_offline_mode_btn_process".localized
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingOfflineStatusLabel
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.updateOfflineStatusView(inProgress: true)
            ClearentWrapper.shared.processOfflineTransactions() {
                self?.updateOfflineStatus()
               
            }
        }
    }
    
    func setupUploadSuccessfully() {
        offlineStatusDescription = "xsdk_offline_mode_upload_success".localized
        offlineStatusButtonTitle = "xsdk_offline_mode_btn_report".localized
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsOfflineStatusLabelSuccess
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.presentReportScreen()
        }
    }
    
    func setupUploadFail() {
        offlineStatusDescription = "xsdk_offline_mode_upload_errors".localized
        offlineStatusButtonTitle = "xsdk_offline_mode_btn_report".localized
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsOfflineStatusLabelFail
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.presentReportScreen()
        }
    }
}
