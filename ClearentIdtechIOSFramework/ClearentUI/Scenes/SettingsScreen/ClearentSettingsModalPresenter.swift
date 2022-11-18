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
            offlineStatusDescription = String(format: ClearentConstants.Localized.Settings.settingsOfflinePendingTransactions, counter)
        } else {
            offlineStatusDescription = ClearentConstants.Localized.Settings.settingsOfflineOnePendingTransactions
        }
        offlineStatusButtonTitle = ClearentConstants.Localized.Settings.settingsOfflineButtonProcess
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingOfflineStatusLabel
        offlineStatusButtonAction = { [weak self] in
            if ClearentWrapper.shared.isInternetOn {
                self?.settingsPresenterView?.updateOfflineStatusView(inProgress: true)
                ClearentWrapper.shared.processOfflineTransactions() {
                    self?.updateOfflineStatus()
                }
            } else {
                self?.settingsPresenterView?.displayNoInternetAlert()
            }
        }
    }
    
    private func setupUploadSuccessfully() {
        offlineStatusDescription = ClearentConstants.Localized.Settings.settingsOfflineUploadSuccess
        offlineStatusButtonTitle = ClearentConstants.Localized.Settings.settingsOfflineButtonReport
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsOfflineStatusLabelSuccess
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.presentReportScreen()
        }
    }
    
    private func setupUploadFail() {
        offlineStatusDescription = ClearentConstants.Localized.Settings.settingsOfflineUploadErrors
        offlineStatusButtonTitle = ClearentConstants.Localized.Settings.settingsOfflineButtonReport
        offlineStatusDescriptionColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsOfflineStatusLabelFail
        offlineStatusButtonAction = { [weak self] in
            self?.settingsPresenterView?.presentReportScreen()
        }
    }
}
