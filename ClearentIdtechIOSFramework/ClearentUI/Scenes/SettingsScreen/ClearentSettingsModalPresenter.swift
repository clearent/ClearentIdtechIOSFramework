//
//  ClearentSettingsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

protocol ClearentSettingsPresenterView: AnyObject {
    func updateOfflineStatusViewVisibility(show: Bool)
    func updateOfflineStatusView(inProgress: Bool)
    func presentReportScreen()
    func displayNoInternetAlert()
    func displayErrorAlert()
    func displayMerchantAndTerminalInfo(merchant: String, terminal: String, action: UIAlertAction)
    func displayNoMerchantAndTerminal()
}

protocol ClearentSettingsPresenterProtocol {
    var offlineStatusDescription: String? { get set }
    var offlineStatusDescriptionColor: UIColor? { get set }
    var offlineStatusButtonTitle: String? { get set }
    var offlineStatusButtonAction: (() -> Void)? { get set }
    func updateOfflineStatus()
    func updateOfflineMode(isEnabled: Bool)
    func updatePromptMode(isEnabled: Bool)
    func updateEmailReceiptStatus(isEnabled: Bool)
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
    
    // MARK: - Internal
    
    func updateOfflineStatus() {
        guard let offlineManager = ClearentWrapper.shared.retrieveOfflineManager() else {
            settingsPresenterView?.updateOfflineStatusViewVisibility(show: false)
            return
        }
        
        if offlineManager.containsUploadReport() {
            offlineManager.uploadReportContainsErrors() ? setupUploadFail() : setupUploadSuccessfully()
        } else {
            let pendingTransactions = offlineManager.retrieveAll().filter({ $0.errorStatus == nil }).count
            if pendingTransactions > 0 {
                setupPendingTransactions(counter: pendingTransactions)
            } else {
                settingsPresenterView?.updateOfflineStatusViewVisibility(show: false)
            }
        }
        settingsPresenterView?.updateOfflineStatusView(inProgress: false)
    }
    
    func updateOfflineMode(isEnabled: Bool) {
        if isEnabled {
            do {
                try ClearentWrapper.shared.enableOfflineMode()
            } catch {
                print("Error: \(error)")
            }
        } else {
            ClearentWrapper.shared.disableOfflineMode()
        }
    }
    
    func updatePromptMode(isEnabled: Bool) {
        ClearentWrapperDefaults.enableOfflinePromptMode = isEnabled
    }
    
    func updateEmailReceiptStatus(isEnabled: Bool) {
        ClearentWrapperDefaults.enableEmailReceipt = isEnabled
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
                if ClearentWrapper.shared.hasWebAuth() {
                    self?.processOfflineTransactionsWithWebAuth()
                } else {
                    self?.settingsPresenterView?.updateOfflineStatusView(inProgress: true)
                    ClearentWrapper.shared.processOfflineTransactions() { error in
                        if error == nil {
                            self?.updateOfflineStatus()
                        } else {
                            self?.settingsPresenterView?.displayErrorAlert()
                        }
                    }
                }
            } else {
                self?.settingsPresenterView?.displayNoInternetAlert()
            }
        }
    }
    
    
    private func processOfflineTransactionsWithWebAuth() {
        if let hook = ClearentWrapper.configuration.provideAuthAndMerchantTerminalDetails {
            let result = hook()
            if let merchantName = result.0, let terminalName = result.1 , let webAuth = result.2 {
                ClearentWrapper.shared.updateWebAuth(with: webAuth)
                
                let action = UIAlertAction(title: ClearentConstants.Localized.OfflineMode.offlineProcessInfoConfirmationAlertOK, style: UIAlertAction.Style.default, handler: {_ in
                    self.settingsPresenterView?.updateOfflineStatusView(inProgress: true)
                    ClearentWrapper.shared.processOfflineTransactions() { [weak self] error in
                           if error == nil {
                               self?.updateOfflineStatus()
                           } else {
                               self?.settingsPresenterView?.displayErrorAlert()
                           }
                    }
                })
                
                self.settingsPresenterView?.displayMerchantAndTerminalInfo(merchant: merchantName, terminal: terminalName, action: action)
            } else {
                self.settingsPresenterView?.displayNoMerchantAndTerminal() 
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
