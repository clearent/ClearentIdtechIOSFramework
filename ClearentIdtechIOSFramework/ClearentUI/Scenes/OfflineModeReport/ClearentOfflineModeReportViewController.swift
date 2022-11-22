//
//  OfflineModeReportViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 01.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentOfflineModeReportViewController: UIViewController {
    
    @IBOutlet weak var clearReportButton: ClearentPrimaryButton!
    @IBOutlet weak var saveErrorLogButton: ClearentPrimaryButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var defaultCellIdentifier = "kOfflineResultCell"
    var reportPresenter: ClearentOfflineModeReportViewProtocol!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        addNavigationBarWithBackItem(barTitle: ClearentConstants.Localized.OfflineReport.navigationItem)
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
    
    private func setupInfoLabel() {
        self.infoLabel.text = ClearentConstants.Localized.OfflineReport.infoLabeltext
        self.infoLabel.font = ClearentUIBrandConfigurator.shared.fonts.sectionTitleLabelFont
        self.infoLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
    
    private func setupButtons() {
        saveErrorLogButton.title = ClearentConstants.Localized.OfflineReport.saveLogButtonTitle
        saveErrorLogButton.buttonStyle = .link
        saveErrorLogButton.action = { [weak self] in
            self?.reportPresenter.saveErrorLog()
        }
        
        clearReportButton.title = ClearentConstants.Localized.OfflineReport.clearButtonTitle
        clearReportButton.buttonStyle = .filled
        clearReportButton.action = { [weak self] in
            self?.reportPresenter.clearAndProceed()
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

extension ClearentOfflineModeReportViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reportPresenter.itemCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClearentOfflineResultTableViewCell.identifier,
                                                              for: indexPath) as? ClearentOfflineResultTableViewCell else { return UITableViewCell() }
        let item = reportPresenter.itemForIndexPath(indexPath: indexPath)
        cell.setup(item:item)
               
        return cell
    }
}
