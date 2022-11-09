//
//  ClearentSettingsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class ClearentSettingsModalViewController: ClearentBaseViewController {
    
    @IBOutlet weak var titleLabel: ClearentTitleLabel!
    @IBOutlet weak var enableOfflineMode: ClearentLabelSwitch!
    @IBOutlet weak var enablePromptMode: ClearentLabelSwitch!
    @IBOutlet weak var progressView: ClearentLabelWithButton!
    @IBOutlet weak var doneButton: ClearentPrimaryButton!
    @IBOutlet weak var offlineModeSubtitle: UILabel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: String(describing: ClearentSettingsModalViewController.self), bundle: ClearentConstants.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupTitle()
        setupSubtitle()
        setupSwitches()
        setupProgressView()
        setupDoneButton()
    }
    
    func setupTitle() {
        titleLabel.title = "xsdk_settings_title".localized
        titleLabel.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenTitle
    }
    
    func setupSubtitle() {
        offlineModeSubtitle.text = "xsdk_offline_mode_subtitle".localized
        offlineModeSubtitle.font = ClearentUIBrandConfigurator.shared.fonts.settingsScreenOfflineModeSubtitle
        offlineModeSubtitle.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    func setupSwitches() {
        enableOfflineMode.titleText = "xsdk_offline_mode_switch_enabled".localized
        enableOfflineMode.titleTextColor = ClearentUIBrandConfigurator.shared.colorPalette.titleLabelColor
        enableOfflineMode.descriptionText = nil
        enableOfflineMode.valueChangedAction = { isOn in
            // TODO
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
    
    func setupProgressView() {
        progressView.activityIndicator.isHidden = true
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
        //dismissCompletion?(result)
    }
}
