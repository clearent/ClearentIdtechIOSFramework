//
//  ClearentSettingsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentSettingsModalViewController: ClearentBaseViewController {

    @IBOutlet var titleLabel: ClearentTitleLabel!
    @IBOutlet var settingsStackView: UIStackView!
    @IBOutlet var readersListView: ClearentInfoWithIcon!
    @IBOutlet var offlineSectionSubtitle: UILabel!
    @IBOutlet var enableOfflineMode: ClearentLabelSwitch!
    @IBOutlet var enablePromptMode: ClearentLabelSwitch!
    @IBOutlet var offlineStatusViewTopSpace: ClearentEmptySpace!
    @IBOutlet var offlineStatusView: ClearentLabelWithButton!
    @IBOutlet var emailSectionSubtitle: UILabel!
    @IBOutlet var enableEmailReceipt: ClearentLabelSwitch!
    @IBOutlet var doneButton: ClearentPrimaryButton!
    
    // Offline mode question prompt
    @IBOutlet var offlineQuestionStackView: UIStackView!
    @IBOutlet var offlineQuestionIcon: ClearentIcon!
    @IBOutlet var offlineQuestionTitle: ClearentTitleLabel!
    @IBOutlet var offlineQuestionFirstSubtitle: ClearentSubtitleLabel!
    @IBOutlet var offlineQuestionSecondSubtitle: ClearentSubtitleLabel!
    @IBOutlet var offlineQuestionConfirmBtn: ClearentPrimaryButton!
    @IBOutlet var offlineQuestionCancelBtn: ClearentPrimaryButton!
    
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
        readersListView.iconName = ClearentConstants.IconName.rightArrow
        readersListView.titleText = ""
        readersListView.containerWasPressed = { [weak self] in
            self?.displayReadersList()
        }
        
        // Offline section
        setupSectionSubtitle(for: offlineSectionSubtitle, with: ClearentConstants.Localized.Settings.settingsOfflineModeSubtitle)
        setupEnableOfflineModeSwitch()
        setupEnablePromptModeSwitch()
        setupDoneButton()
        setupOfflineModeQuestion()
        offlineQuestionStackView.isHidden = true
        
        // Email section
        setupSectionSubtitle(for: emailSectionSubtitle, with: ClearentConstants.Localized.Settings.settingsEmailReceiptSubtitle)
        setupEmailReceiptSwitch()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.updateOfflineStatus()
        setupReaderListSelection()
    }
    
    // MARK: - Private
    
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
    
    private func setupTitle() {
        titleLabel.title = ClearentConstants.Localized.Settings.settingsOfflineModeTitle
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenTitle
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
                self?.showOfflineModeQuestionIfNeeded(shouldShow: true)
            } else {
                self?.enablePromptMode.isOn = false
                self?.updatePromptModeState(isUserInteractionEnabled: false)
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
    
    private func setupOfflineModeQuestion() {
        offlineQuestionIcon.iconName = ClearentConstants.IconName.warning
        offlineQuestionTitle.title = ClearentConstants.Localized.OfflineMode.enableOfflineMode
        offlineQuestionFirstSubtitle.title = ClearentConstants.Localized.OfflineMode.offlineModeWarningMessageDescription
        offlineQuestionSecondSubtitle.title = ClearentConstants.Localized.OfflineMode.offlineModeWarningConfirmationDescription
        offlineQuestionConfirmBtn.title = ClearentConstants.Localized.OfflineMode.offlineModeConfirmOption
        
        offlineQuestionConfirmBtn.action = { [weak self] in
            self?.showOfflineModeQuestionIfNeeded(shouldShow: false)
            self?.updatePromptModeState(isUserInteractionEnabled: true)
            self?.presenter?.updateOfflineMode(isEnabled: true)
        }
        offlineQuestionCancelBtn.title = ClearentConstants.Localized.OfflineMode.offlineModeCancelOption
        offlineQuestionCancelBtn.buttonStyle = .bordered
        offlineQuestionCancelBtn.action = { [weak self] in
            self?.enableOfflineMode.isOn = false
            self?.showOfflineModeQuestionIfNeeded(shouldShow: false)
        }
    }
    
    private func showOfflineModeQuestionIfNeeded(shouldShow: Bool) {
        offlineQuestionStackView.isHidden = !shouldShow
        settingsStackView.isHidden = shouldShow
    }
    
    private func settingsViewController(dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UIViewController {
        let viewController = ClearentSettingsModalViewController()
        let presenter = ClearentSettingsPresenter(settingsPresenterView: viewController)
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion
        return viewController
    }
    
    private func updatePromptModeState(isUserInteractionEnabled: Bool) {
        enablePromptMode.isUserInteractionEnabled = isUserInteractionEnabled
        enablePromptMode.alpha = isUserInteractionEnabled ? 1.0 : 0.5
    }
    
    private func setupEnablePromptModeSwitch() {
        enablePromptMode.titleText = ClearentConstants.Localized.Settings.settingsOfflineSwitchEnablePrompt
        enablePromptMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enablePromptMode.descriptionText = nil
        enablePromptMode.isOn = ClearentWrapperDefaults.enableOfflinePromptMode
        updatePromptModeState(isUserInteractionEnabled: enableOfflineMode.isOn)
        
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
}
