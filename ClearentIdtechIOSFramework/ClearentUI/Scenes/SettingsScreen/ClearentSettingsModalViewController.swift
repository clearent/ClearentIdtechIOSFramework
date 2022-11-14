//
//  ClearentSettingsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class ClearentSettingsModalViewController: ClearentBaseViewController {
    
    @IBOutlet var titleLabel: ClearentTitleLabel!
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
        setupOfflineSectionSubtitle()
        setupSwitches()
        setupDoneButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.updateOfflineStatus()
    }
    
    func setupTitle() {
        titleLabel.title = ClearentConstants.Localized.Settings.settingsOfflineModeTitle
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenTitle
    }
    
    func setupOfflineSectionSubtitle() {
        offlineSectionSubtitle.text = ClearentConstants.Localized.Settings.settingsOfflineModeSubtitle
        offlineSectionSubtitle.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenOfflineModeSubtitle
        offlineSectionSubtitle.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    func setupSwitches() {
        enableOfflineMode.titleText = ClearentConstants.Localized.Settings.settingsOfflineSwitchEnabled
        enableOfflineMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enableOfflineMode.descriptionText = nil
        enableOfflineMode.isOn = ClearentWrapper.configuration.enableOfflineMode
        enableOfflineMode.valueChangedAction = { isOn in
            self.enablePromptMode.isUserInteractionEnabled = isOn
            self.enablePromptMode.alpha = isOn ? 1.0 : 0.5
            if isOn {
                do {
                    try ClearentWrapper.shared.enableOfflineMode()
                } catch {
                    print("Error: \(error)")
                }
            } else {
                ClearentWrapper.shared.disableOfflineMode()
            }
        }
        
        enablePromptMode.titleText = ClearentConstants.Localized.Settings.settingsOfflineSwitchEnablePrompt
        enablePromptMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enablePromptMode.descriptionText = nil
        enablePromptMode.isOn = ClearentUIManager.configuration.offlineModeState == .prompted
        enablePromptMode.valueChangedAction = { isOn in
            if isOn {
                ClearentUIManager.configuration.offlineModeState = .prompted
            } else {
                ClearentUIManager.configuration.offlineModeState = .on
            }
        }
    }
    
    func setupDoneButton() {
        doneButton.title = ClearentConstants.Localized.Settings.settingsOfflineButtonDone
        doneButton.action = { [weak self] in
            self?.dismiss()
        }
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
        dismissCompletion?(.success(nil))
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
        let alert = UIAlertController(title: ClearentConstants.Localized.Internet.error, message: ClearentConstants.Localized.Internet.noConnection, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ClearentConstants.Localized.Internet.noConnectionDoneButton, style: .cancel))
        present(alert, animated: true, completion: nil)
    }
}
