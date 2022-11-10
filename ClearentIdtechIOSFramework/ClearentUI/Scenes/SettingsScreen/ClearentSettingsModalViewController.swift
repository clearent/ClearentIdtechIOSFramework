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
    
    var presenter: ClearentSettingsPresenter?
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
        titleLabel.title = "xsdk_settings_title".localized
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenTitle
    }
    
    func setupOfflineSectionSubtitle() {
        offlineSectionSubtitle.text = "xsdk_offline_mode_subtitle".localized
        offlineSectionSubtitle.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenOfflineModeSubtitle
        offlineSectionSubtitle.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    func setupSwitches() {
        enableOfflineMode.titleText = "xsdk_offline_mode_switch_enabled".localized
        enableOfflineMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enableOfflineMode.descriptionText = nil
        enableOfflineMode.valueChangedAction = { isOn in
            
        }
        
        enablePromptMode.titleText = "xsdk_offline_mode_switch_enable_prompt".localized
        enablePromptMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enablePromptMode.descriptionText = nil
        enablePromptMode.valueChangedAction = { isOn in
            // TODO
        }
    }
    
    func setupDoneButton() {
        doneButton.title = "xsdk_offline_mode_btn_done".localized
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
}
