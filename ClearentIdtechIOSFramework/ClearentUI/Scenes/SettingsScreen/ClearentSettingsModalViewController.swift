//
//  ClearentSettingsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentSettingsModalViewController: ClearentBaseViewController {
    
    // MARK: - IBOutlets

    @IBOutlet public var titleLabel: ClearentTitleLabel!
    @IBOutlet public var settingsStackView: ClearentRoundedCornersStackView!
    @IBOutlet public var doneButton: ClearentPrimaryButton!
    @IBOutlet var readersListView: ClearentInfoWithIcon!
    @IBOutlet var offlineModeSectionTopEmptySpace: ClearentEmptySpace!
    @IBOutlet var offlineSectionSubtitle: UILabel!
    @IBOutlet var enableOfflineMode: ClearentLabelSwitch!
    @IBOutlet var enablePromptMode: ClearentLabelSwitch!
    @IBOutlet var offlineStatusViewTopSpace: ClearentEmptySpace!
    @IBOutlet var offlineStatusView: ClearentLabelWithButton!
    @IBOutlet var emailSectionSubtitle: UILabel!
    @IBOutlet var enableEmailReceipt: ClearentLabelSwitch!
    
    // MARK: - Properties
    
    var presenter: ClearentSettingsPresenterProtocol?
    var dismissCompletion: ((CompletionResult) -> Void)?
    
    // MARK: - Init
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: String(describing: ClearentSettingsModalViewController.self), bundle: ClearentConstants.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        
        // Readers section
        readersListView.iconName = ClearentConstants.IconName.rightArrowLarge
        readersListView.titleText = ""
        readersListView.containerWasPressed = { [weak self] in
            self?.displayReadersList()
        }
        
        // Offline section
        configureOfflineModeSections()
        
        // Email section
        setupSectionSubtitle(for: emailSectionSubtitle, with: ClearentConstants.Localized.Settings.settingsEmailReceiptSubtitle)
        setupEmailReceiptSwitch()
        
        setupDoneButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.updateOfflineStatus()
        setupReaderListSelection()
    }
    
    // MARK: - Private
    
    private func setupTitle() {
        titleLabel.title = ClearentConstants.Localized.Settings.settingsOfflineModeTitle
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenTitle
    }
    
    private func setupReaderListSelection() {
        if let readerName = ClearentWrapperDefaults.lastPairedReaderInfo?.customReaderName ?? ClearentWrapperDefaults.lastPairedReaderInfo?.readerName {
            readersListView.descriptionText = readerName
            readersListView.descriptionFont = ClearentUIBrandConfigurator.shared.fonts.settingsReadersDescriptionLabel
            readersListView.descriptionTextColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsReadersDescriptionColor
        } else {
            readersListView.descriptionText = ClearentConstants.Localized.Settings.settingsReadersPlaceholder
            readersListView.descriptionFont = ClearentUIBrandConfigurator.shared.fonts.settingsReadersPlaceholderLabel
            readersListView.descriptionTextColor = ClearentUIBrandConfigurator.shared.colorPalette.settingsReadersPlaceholderColor
        }
        readersListView.button.isUserInteractionEnabled = false
    }
    
    private func configureOfflineModeSections() {
        let isOfflineModeAvailable = ClearentUIManager.configuration.offlineModeEncryptionKey != nil
        
        [offlineSectionSubtitle, enableOfflineMode, enablePromptMode, offlineModeSectionTopEmptySpace].forEach {
            $0?.isHidden = !isOfflineModeAvailable
        }
        
        if isOfflineModeAvailable {
            setupSectionSubtitle(for: offlineSectionSubtitle, with: ClearentConstants.Localized.Settings.settingsOfflineModeSubtitle)
            setupEnableOfflineModeSwitch()
            setupEnablePromptModeSwitch()
        }
    }
    
    private func setupSectionSubtitle(for label: UILabel, with title: String) {
        label.text = title
        label.font = ClearentUIBrandConfigurator.shared.fonts.settingsOfflineModeSubtitle
        label.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    private func setupEnableOfflineModeSwitch() {
        enableOfflineMode.titleText = ClearentConstants.Localized.Settings.settingsOfflineSwitchEnabled
        enableOfflineMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enableOfflineMode.descriptionText = nil
        enableOfflineMode.isOn = ClearentWrapperDefaults.enableOfflineMode
        
        enableOfflineMode.valueChangedAction = { [weak self] isOn in
            if isOn {
                self?.displayOfflineModeQuestion()
            } else {
                self?.updatePromptModeState(isUserInteractionEnabled: false, enabled: false)
                self?.presenter?.updatePromptMode(isEnabled: false)
                self?.presenter?.updateOfflineMode(isEnabled: false)
            }
        }
    }
    
    private func setupEmailReceiptSwitch() {
        enableEmailReceipt.titleText = ClearentConstants.Localized.Settings.settingsEmailReceiptEnabled
        enableEmailReceipt.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enableEmailReceipt.descriptionText = nil
        enableEmailReceipt.isOn = ClearentWrapperDefaults.enableEmailReceipt
        
        enableEmailReceipt.valueChangedAction = { [weak self] isOn in
            self?.presenter?.updateEmailReceiptStatus(isEnabled: isOn)
        }
    }
    
    private func settingsViewController(dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UIViewController {
        let viewController = ClearentSettingsModalViewController()
        let presenter = ClearentSettingsPresenter(settingsPresenterView: viewController)
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion
        return viewController
    }
    
    private func updatePromptModeState(isUserInteractionEnabled: Bool, enabled: Bool) {
        enablePromptMode.isOn = enabled
        enablePromptMode.isUserInteractionEnabled = isUserInteractionEnabled
        enablePromptMode.alpha = isUserInteractionEnabled ? 1.0 : 0.5
    }
    
    private func setupEnablePromptModeSwitch() {
        enablePromptMode.titleText = ClearentConstants.Localized.Settings.settingsOfflineSwitchEnablePrompt
        enablePromptMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enablePromptMode.descriptionText = nil
        updatePromptModeState(isUserInteractionEnabled: ClearentWrapperDefaults.enableOfflineMode, enabled: ClearentWrapperDefaults.enableOfflinePromptMode)
        
        enablePromptMode.valueChangedAction = { [weak self] isOn in
            self?.presenter?.updatePromptMode(isEnabled: isOn)
        }
    }
    
    private func setupDoneButton() {
        doneButton.title = ClearentConstants.Localized.Settings.settingsOfflineButtonDone
        doneButton.action = { [weak self] in
            self?.dismiss()
        }
    }

    private func dismiss() {
        dismiss(animated: true, completion: nil)
        dismissCompletion?(.success(nil))
    }

    private func displayReadersList() {
        let viewController = ClearentProcessingModalViewController(showOnTop: true)
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, paymentInfo: nil, processType: .showReaders)
        viewController.presenter = presenter
        viewController.removeSemiTransparentBackground()

        navigationController?.pushViewController(viewController, animated: true)
        viewController.addNavigationBarWithBackItem(barTitle: ClearentConstants.Localized.Settings.settingsReadersPlaceholder)
        viewController.navigationItem.title = ClearentConstants.Localized.Settings.settingsReadersPlaceholder
    }
    
    private func displayOfflineModeQuestion() {
        // if the current view controller is Settings modal, it should be hidden to avoid overlapping modals
        let settingsModal = navigationController?.topViewController as? ClearentSettingsModalViewController
        let questionVC = ClearentUIManager.shared.offlineModeQuestionViewController() { [weak self] error in
            let enabled = error == nil
            self?.enableOfflineMode.isOn = enabled
            self?.updatePromptModeState(isUserInteractionEnabled: enabled, enabled: enabled)
            self?.presenter?.updatePromptMode(isEnabled: enabled)
            settingsModal?.view.fadeIn(duration: 0)
        }
        navigationController?.present(questionVC, animated: true)
        settingsModal?.view.fadeOut()
    }
}

extension ClearentSettingsModalViewController: ClearentSettingsPresenterView {
    
    func updateOfflineStatusViewVisibility(show: Bool) {
        offlineStatusView.isHidden = !show
        offlineStatusViewTopSpace.isHidden = !show
    }
    
    func updateOfflineStatusView(inProgress: Bool) {
        offlineStatusView.activityIndicator.isHidden = !inProgress
        offlineStatusView.button.isHidden = inProgress
        
        if inProgress {
            offlineStatusView.activityIndicator.startAnimating()
        }
        offlineStatusView.descriptionText = presenter?.offlineStatusDescription
        offlineStatusView.descriptionColor = presenter?.offlineStatusDescriptionColor
        
        offlineStatusView.buttonTitle = presenter?.offlineStatusButtonTitle
        offlineStatusView.buttonAction = presenter?.offlineStatusButtonAction
    }
    
    func presentReportScreen() {
        let vc = ClearentOfflineModeReportViewController(nibName: String(describing: ClearentOfflineModeReportViewController.self), bundle: ClearentConstants.bundle)
        vc.reportPresenter = ClearentOfflineModeReportPresenter(view: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func displayNoInternetAlert() {
        showCancelAlert(title: ClearentConstants.Localized.Internet.error, message: ClearentConstants.Localized.Settings.settingsOfflineButtonProcessNoInternet, cancelTitle: ClearentConstants.Localized.Internet.noConnectionDoneButton)
    }
    
    func displayErrorAlert() {
        showCancelAlert(title: ClearentConstants.Localized.Error.generalErrorTitle, message: ClearentConstants.Localized.Error.generalErrorDescription, cancelTitle: ClearentConstants.Localized.Error.cancel)
    }
    
    func displayMerchantAndTerminalInfo(merchant: String, terminal: String, action: UIAlertAction) {
        let message = String(format: ClearentConstants.Localized.OfflineMode.offlineProcessInfoConfirmationAlert, merchant, terminal)
        showOfflineProcessConfirmation(title: ClearentConstants.Localized.OfflineMode.offlineProcessInfoConfirmationAlertTitle, message: message, cancelTitle: "Cancel", action: action)
    }
    
    func displayNoMerchantAndTerminal() {
        showCancelAlert(title: ClearentConstants.Localized.OfflineMode.offlineProcessingError, message: ClearentConstants.Localized.OfflineMode.offlineProcessingErrorDetails, cancelTitle: ClearentConstants.Localized.Internet.noConnectionDoneButton)
    }
}
