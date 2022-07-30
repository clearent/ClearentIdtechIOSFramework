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
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = ClearentPaymentSectionHeaderView()
        sectionHeaderView.delegate = self
        
        return dataSource?.sections[section].isCollapsable == true ? sectionHeaderView : nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataSource?.sections[section].isCollapsable == true ? ClearentPaymentFieldCell.Layout.sectionHeaderViewHeight : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ClearentPaymentFieldCell.Layout.cellHeight
    }
}

extension ClearentManualEntryFormView: ClearentPaymentSectionHeaderViewProtocol {
    func didTapOnSectionHeaderView(_ sender: ClearentPaymentSectionHeaderView) {
        guard let dataSource = dataSource else { return }
        
        let isSectionCollapsed = dataSource.sections[1].isCollapsed
        dataSource.sections[1].isCollapsed = !isSectionCollapsed
        
//        tableView.reloadData()
        sender.updateDropDownIcon(isSectionCollapsed: dataSource.sections[1].isCollapsed)
    }
}
