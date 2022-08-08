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
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // Register keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset.bottom = keyboardSize.height / 1.3
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        tableView.contentInset.bottom = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableViewHeightLC.constant = tableView.contentSize.height
    }
}

extension ClearentManualEntryFormView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionItem = dataSource?.sections[safe: section], sectionItem.isCollapsable else { return nil }
        
        let sectionHeaderView = ClearentPaymentSectionHeaderView(sectionItem: sectionItem)
        sectionHeaderView.delegate = self
        return sectionHeaderView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return dataSource?.sections[section].isCollapsable == true ? ClearentPaymentFieldCell.Layout.sectionHeaderViewHeight : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ClearentPaymentFieldCell.Layout.cellHeight
    }
}

extension ClearentManualEntryFormView: ClearentPaymentSectionHeaderViewProtocol {
    func didTapOnSectionHeaderView(header: ClearentPaymentSectionHeaderView, sectionIndex: Int) {
        guard let dataSource = dataSource, let section = dataSource.sections[safe: sectionIndex] else { return }

        dataSource.sections[sectionIndex].isCollapsed = !section.isCollapsed
        tableView.reloadData()
        tableViewHeightLC.constant = tableView.contentSize.height
    }
}
