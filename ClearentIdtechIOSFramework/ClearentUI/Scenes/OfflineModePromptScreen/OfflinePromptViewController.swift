//
//  OfflinePromptViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 07.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import UIKit

class OfflinePromptViewController: ClearentBaseViewController {
    
    
    @IBOutlet weak var stackView: ClearentRoundedCornersStackView!
    @IBOutlet weak var offlineQuestionIcon: ClearentIcon!
    @IBOutlet weak var offlineQuestionTitle: ClearentTitleLabel!
    @IBOutlet weak var offlineQuestionFirstSubtitle: ClearentSubtitleLabel!
    @IBOutlet weak var offlineQuestionSecondSubtitle: ClearentSubtitleLabel!
    @IBOutlet weak var offlineQuestionConfirmBtn: ClearentPrimaryButton!
    @IBOutlet weak var offlineQuestionCancelBtn: ClearentPrimaryButton!
    // MARK: - Init
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: String(describing: OfflinePromptViewController.self), bundle: ClearentConstants.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOfflineModeQuestions()
    }
    
    private func setupOfflineModeQuestions() {
        offlineQuestionIcon.iconName = ClearentConstants.IconName.warning
        offlineQuestionTitle.title = ClearentConstants.Localized.OfflineMode.enableOfflineMode
        offlineQuestionFirstSubtitle.title = ClearentConstants.Localized.OfflineMode.offlineModeWarningMessageDescription
        offlineQuestionSecondSubtitle.title = ClearentConstants.Localized.OfflineMode.offlineModeWarningConfirmationDescription
        offlineQuestionConfirmBtn.title = ClearentConstants.Localized.OfflineMode.offlineModeConfirmOption
        offlineQuestionCancelBtn.title = ClearentConstants.Localized.OfflineMode.offlineModeCancelOption
        
        offlineQuestionConfirmBtn.action = { [weak self] in
//            self?.showOfflineModeQuestionIfNeeded(shouldShow: false)
//            self?.updatePromptModeState(isUserInteractionEnabled: true)
//            self?.presenter?.updateOfflineMode(isEnabled: true)
        }
        offlineQuestionCancelBtn.title = ClearentConstants.Localized.OfflineMode.offlineModeCancelOption
        offlineQuestionCancelBtn.buttonStyle = .bordered
        offlineQuestionCancelBtn.action = { [weak self] in
//            self?.enableOfflineMode.isOn = false
//            self?.showOfflineModeQuestionIfNeeded(shouldShow: false)
        }
    }
}
