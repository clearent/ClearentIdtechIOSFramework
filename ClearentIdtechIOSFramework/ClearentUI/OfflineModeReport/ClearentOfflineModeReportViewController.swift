//
//  OfflineModeReportViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 01.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentOfflineModeReportViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var clearReportButton: ClearentPrimaryButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupButtons()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    
    // MARK: - Private

    private func setupNavigationBar() {
        let image = UIImage(named: ClearentConstants.IconName.navigationArrow, in: ClearentConstants.bundle, compatibleWith: nil)
        customNavigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didPressBackButton))
        navigationBar.isTranslucent = true
        navigationBar.barTintColor = view.backgroundColor
        navigationBar.shadowImage = UIImage()
        navigationBar.tintColor = ClearentUIBrandConfigurator.shared.colorPalette.navigationBarTintColor
        navigationBar.titleTextAttributes = [.font: ClearentUIBrandConfigurator.shared.fonts.screenTitleFont,
                                             .foregroundColor: ClearentUIBrandConfigurator.shared.colorPalette.screenTitleColor]
        customNavigationItem.title = ClearentConstants.Localized.OfflineReport.navigationItem
    }
    
    private func setupButtons() {
        clearReportButton.title = ClearentConstants.Localized.OfflineReport.clearButtonTitle
        clearReportButton.buttonStyle = .filled
        clearReportButton.action = { [weak self] in
            //self?.showRemoveReaderAlert()
        }
    }
    
    @objc func didPressBackButton() {
        navigationController?.popViewController(animated: true)
    }
}
