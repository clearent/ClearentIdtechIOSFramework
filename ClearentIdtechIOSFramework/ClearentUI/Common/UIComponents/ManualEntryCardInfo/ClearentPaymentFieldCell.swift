//
//  ClearentPaymentFieldCell.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentPaymentFieldCell: UITableViewCell {
    
    @IBOutlet weak var leftPaymentTextField: ClearentPaymentTextField!
    @IBOutlet weak var rightPaymentTextField: ClearentPaymentTextField!
    @IBOutlet weak var stackView: UIStackView!
    
    private var type: ClearentPaymentRowType?
    var action: ((ClearentPaymentItemType?, String?) -> Void)?
    
    enum Layout {
        static let cellHeight: CGFloat = 92
        static let sectionHeaderViewHeight: CGFloat = 48 //TO DO: double check if this is the right size
    }

    static let identifier = "ClearentPaymentFieldCellIdentifier"
    static let nib = "ClearentPaymentFieldCell"
    
    // MARK: - Public
    
    static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentPaymentFieldCell.nib, bundle: Bundle(for: ClearentPaymentFieldCell.self)),
                           forCellReuseIdentifier: ClearentPaymentFieldCell.identifier)
    }
    
    func setup(with row: ClearentPaymentRow) {
        type = row.type
        
        if row.type == .singleItem {
            setup(paymentField: leftPaymentTextField, with: row.elements[0])
            stackView.removeAllArrangedSubviews()
            stackView.addArrangedSubview(leftPaymentTextField)
        } else {
            setup(paymentField: leftPaymentTextField, with: row.elements[0])
            setup(paymentField: rightPaymentTextField, with: row.elements[1])
        }
    }
    
    func updatePaymentField(containing item: ClearentPaymentItemType?, with errorMessage: String?) {
        if type == .singleItem || item == .date {
            update(paymentField: leftPaymentTextField, with: errorMessage)
        } else {
            update(paymentField: rightPaymentTextField, with: errorMessage)
        }
    }
    
    // MARK: - Private
    
    private func setup(paymentField: ClearentPaymentTextField, with item: ClearentPaymentItem) {
        paymentField.setup(with: item)
        paymentField.action = { [weak self] fieldType, cardData in
            guard let strongSelf = self else { return }
            strongSelf.action?(fieldType, cardData)
        }
    }
    
    private func update(paymentField: ClearentPaymentTextField, with errorMessage: String?) {
        guard let errorMessage = errorMessage else {
            paymentField.disableErrorState()
            return
        }
        paymentField.enableErrorState(errorMessage: errorMessage)
    }
}
