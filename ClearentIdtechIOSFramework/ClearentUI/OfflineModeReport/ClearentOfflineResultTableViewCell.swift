//
//  OfflineResultTableViewCell.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 03.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentOfflineResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemValueLabel: UILabel!
    
    enum Layout {
           static let cellHeight: CGFloat = 40
       }

    static let identifier = "ClearentOflineResultCellIdentifier"
    static let nib = "ClearentOfflineResultTableViewCell"
    
    // MARK: Lifecycle
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure()
    }
    
    // MARK: Public
        
    public static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentOfflineResultTableViewCell.nib, bundle: Bundle(for: ClearentOfflineResultTableViewCell.self)), forCellReuseIdentifier: ClearentOfflineResultTableViewCell.identifier)
    }
    
    public func setup(item: ReportItem) {
        self.itemNameLabel.text = item.itemName + ":"
        let prefix = (item.isAmount) ? "$" : ""
        self.itemValueLabel.text = prefix + item.itemValue
    }
    
    // MARK: Private
    
    private func configure() {
        itemNameLabel.font = ClearentUIBrandConfigurator.shared.fonts.offlineResultItemLabelFont
        itemNameLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
        
        itemValueLabel.font = ClearentUIBrandConfigurator.shared.fonts.offlineResultItemLabelFont
        itemValueLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.subtitleLabelColor
    }
}
