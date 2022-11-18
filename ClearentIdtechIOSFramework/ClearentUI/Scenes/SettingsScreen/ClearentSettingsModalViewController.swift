//
//  ClearentSettingsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class ClearentSettingsModalViewController: ClearentBaseViewController {
    
    @IBOutlet var titleLabel: ClearentTitleLabel!
    @IBOutlet var readersListView: ClearentInfoWithIcon!
    @IBOutlet var offlineSectionSubtitle: UILabel!
    @IBOutlet var enableOfflineMode: ClearentLabelSwitch!
    @IBOutlet var enablePromptMode: ClearentLabelSwitch!
    @IBOutlet var offlineStatusView: ClearentLabelWithButton!
    @IBOutlet var doneButton: ClearentPrimaryButton!
    
    var presenter: ClearentSettingsPresenterProtocol?
    var dismissCompletion: ((CompletionResult) -> Void)?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: String(describing: ClearentSettingsModalViewController.self), bundle: ClearentConstants.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        
        // Readers section
        readersListView.iconName = ClearentConstants.IconName.rightArrow
        readersListView.titleText = ""
        
        // Offline section
        setupOfflineSectionSubtitle()
        setupEnableOfflineModeSwitch()
        setupEnablePromptModeSwitch()
        setupDoneButton()
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
    }
    
    private func setupTitle() {
        titleLabel.title = ClearentConstants.Localized.Settings.settingsOfflineModeTitle
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenTitle
    }
    
    private func setupOfflineSectionSubtitle() {
        offlineSectionSubtitle.text = ClearentConstants.Localized.Settings.settingsOfflineModeSubtitle
        offlineSectionSubtitle.font = ClearentUIBrandConfigurator.shared.fonts.settingsOfflineModeSubtitle
        offlineSectionSubtitle.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    private func setupEnableOfflineModeSwitch() {
        enableOfflineMode.titleText = ClearentConstants.Localized.Settings.settingsOfflineSwitchEnabled
        enableOfflineMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enableOfflineMode.descriptionText = nil
        enableOfflineMode.isOn = ClearentWrapperDefaults.enableOfflineMode
        enableOfflineMode.valueChangedAction = { [weak self] isOn in
            self?.updatePromptModeState(isUserInteractionEnabled: isOn)
            self?.presenter?.updateOfflineMode(isEnabled: isOn)
        }
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

    @IBAction func readersSectionWasPressed(_: Any) {
        let viewController = ClearentProcessingModalViewController(showOnTop: true)
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, amount: nil, processType: .showReaders)
        viewController.presenter = presenter
        viewController.removeSemiTransparentBackground()

        navigationController?.pushViewController(viewController, animated: true)
        viewController.addNavigationBarWithBackItem(barTitle: ClearentConstants.Localized.Settings.settingsReadersPlaceholder)
        viewController.navigationItem.title = ClearentConstants.Localized.Settings.settingsReadersPlaceholder
    }
}

extension ClearentSettingsModalViewController: ClearentSettingsPresenterView {
    func removeOfflineStatusView() {
        offlineStatusView.isHidden = true
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
        vc.reportPresenter = ClearentOfflineModeReportPresenter()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func displayNoInternetAlert() {
        let alert = UIAlertController(title: ClearentConstants.Localized.Internet.noConnection, message: ClearentConstants.Localized.Internet.error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ClearentConstants.Localized.Internet.noConnectionDoneButton, style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}
