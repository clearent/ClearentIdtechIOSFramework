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
    func displayNoInternetAlert()
}

protocol ClearentSettingsPresenterProtocol {
    var offlineStatusDescription: String? { get set }
    var offlineStatusDescriptionColor: UIColor? { get set }
    var offlineStatusButtonTitle: String? { get set }
    var offlineStatusButtonAction: (() -> Void)? { get set }
    func updateOfflineStatus()
}

class ClearentSettingsPresenter: ClearentSettingsPresenterProtocol {
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
        guard let offlineManager = ClearentWrapper.shared.retrieveOfflineManager() else {
            settingsPresenterView?.removeOfflineStatusView()
            return
        }
        
        if offlineManager.containsUploadReport() {
            if offlineManager.uploadReportContainsErrors() {
                setupUploadFail()
            } else {
                setupUploadSuccessfully()
            }
        } else {
            let pendingTransactions = offlineManager.retrieveAll().filter({ $0.errorStatus == nil }).count
            if pendingTransactions > 0 {
                setupPendingTransactions(counter: pendingTransactions)
            } else {
                settingsPresenterView?.removeOfflineStatusView()
            }
        }
        settingsPresenterView?.updateOfflineStatusView(inProgress: false)
    }

    // MARK: - Private
    
    private func setupPendingTransactions(counter: Int) {
        if counter > 1 {
            offlineStatusDescription = String(format: "xsdk_offline_mode_transactions".localized, counter)
        } else {
            offlineStatusDescription = "xsdk_offline_mode_one_transaction".localized
        }
        offlineStatusButtonTitle = "xsdk_offline_mode_btn_process".localized
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingOfflineStatusLabel
        offlineStatusButtonAction = { [weak self] in
            if !ClearentWrapper.shared.isInternetOn {
                self?.settingsPresenterView?.displayNoInternetAlert()
            } else {
                self?.settingsPresenterView?.updateOfflineStatusView(inProgress: true)
                ClearentWrapper.shared.processOfflineTransactions() {
                    self?.updateOfflineStatus()
                }
            }
        }
    }
    
    private func setupUploadSuccessfully() {
        offlineStatusDescription = "xsdk_offline_mode_upload_success".localized
        offlineStatusButtonTitle = "xsdk_offline_mode_btn_report".localized
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsOfflineStatusLabelSuccess
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.presentReportScreen()
        }
    }
    
    private func setupUploadFail() {
        offlineStatusDescription = "xsdk_offline_mode_upload_errors".localized
        offlineStatusButtonTitle = "xsdk_offline_mode_btn_report".localized
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsOfflineStatusLabelFail
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.presentReportScreen()
        }
    }
}
