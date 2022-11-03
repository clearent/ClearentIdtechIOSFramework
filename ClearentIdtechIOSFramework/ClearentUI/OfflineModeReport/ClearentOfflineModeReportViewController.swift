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
    @IBOutlet weak var saveErrorLogButton: ClearentPrimaryButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var defaultCellIdentifier = "kOfflineResultCell"
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupInfoLabel()
        setupButtons()
        tableView.dataSource = self
        ClearentOfflineResultTableViewCell.register(tableView: tableView)
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
    
    private func setupInfoLabel() {
        self.infoLabel.text = ClearentConstants.Localized.OfflineReport.infoLabeltext
        self.infoLabel.font = ClearentUIBrandConfigurator.shared.fonts.sectionTitleLabelFont
        self.infoLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    private func setupButtons() {
        saveErrorLogButton.title = ClearentConstants.Localized.OfflineReport.saveLogButtonTitle
        saveErrorLogButton.buttonStyle = .link
        saveErrorLogButton.action = { [weak self] in
            //self?.showRemoveReaderAlert()
        }
        
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

extension ClearentOfflineModeReportViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       // guard let dataSource = dataSource else { return 0 }
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClearentOfflineResultTableViewCell.identifier,
                                                              for: indexPath) as? ClearentOfflineResultTableViewCell else { return UITableViewCell() }
        
        

        cell.itemNameLabel.text = "Declined Amount"
        cell.itemValueLabel.text = "$20"
               
        return cell
    }
}
