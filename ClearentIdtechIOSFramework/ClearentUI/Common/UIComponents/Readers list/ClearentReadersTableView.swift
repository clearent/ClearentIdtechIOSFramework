//
//  ClearentReadersTableView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 11.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReadersTableView: ClearentMarginableView {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    private var dataSource: ClearentReadersTableViewDataSource?
    private var delegate: ClearentReadersTableViewDelegate?
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self)
        ]
    }
    
    // MARK: Init
    
    convenience init(dataSource: ClearentReadersTableViewDataSource, delegate: ClearentReadersTableViewDelegate) {
        self.init()
        
        self.dataSource = dataSource
        self.delegate = delegate
        
        setupTableView()
        tableView.reloadData()
    }
    
    // MARK: Private
    
    private func setupTableView() {
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        
        ClearentReadersTableViewCell.register(tableView: tableView)
        
        guard let dataSource = dataSource else { return }
        heightConstraint.constant = CGFloat(dataSource.numberOfElements()) * ClearentReadersTableViewCell.Layout.cellHeight
    }
}
