//
//  ClearentManualEntryFormView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

class ClearentManualEntryFormView: ClearentXibView {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    
    private var dataSource: ClearentPaymentDataSource?
//    private weak var delegate: ClearentPaymentDelegate?
    
    override func configure() {}
    
    // MARK: - Init
    
    convenience init(with dataSource: ClearentPaymentDataSource) {
        self.init()
        
        self.dataSource = dataSource
//        self.delegate = delegate
        
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        ClearentPaymentFieldCell.register(tableView: tableView)
        ClearentPaymentTwoFieldsCell.register(tableView: tableView)
    }
}

extension ClearentManualEntryFormView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        88
    }
}
