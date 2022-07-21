//
//  ClearentManualEntryFormView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

protocol ClearentManualEntryFormViewProtocol: AnyObject {
    func didTapOnCancelButton()
    func didTapOnConfirmButton()
}

class ClearentManualEntryFormView: ClearentXibView {
    
    @IBOutlet weak var headerView: ClearentPaymentHeaderView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: ClearentPaymentFooterView!
    
    @IBOutlet var tableViewHeightLC: NSLayoutConstraint!
    private var dataSource: ClearentPaymentDataSource?
    weak var delegate: ClearentManualEntryFormViewProtocol?
    
    override func configure() {}
    
    // MARK: - Init
    
    convenience init(with dataSource: ClearentPaymentDataSource) {
        self.init()
        
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        ClearentPaymentFieldCell.register(tableView: tableView)
        ClearentPaymentTwoFieldsCell.register(tableView: tableView)
        
        footerView.cancelButtonAction = {
            self.delegate?.didTapOnCancelButton()
        }
        
        footerView.confirmButtonAction = {
            self.delegate?.didTapOnConfirmButton()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableViewHeightLC.constant = tableView.contentSize.height
    }
}

extension ClearentManualEntryFormView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return UITableViewHeaderFooterView()
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        92.0
    }
}
