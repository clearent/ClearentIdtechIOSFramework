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
    @IBOutlet var rightPaymentTextField: ClearentPaymentTextField!
    @IBOutlet weak var stackView: UIStackView!
    
    var action: ((ClearentPaymentItem?, String?) -> Void)?
    
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
        guard let firstElement = row.elements[safe: 0] else { return }
        setup(paymentField: leftPaymentTextField, with: firstElement)

        rightPaymentTextField.isHidden = row.elements.count == 1
       
        if let secondElement = row.elements[safe: 1] {
            rightPaymentTextField.isHidden = false
            setup(paymentField: rightPaymentTextField, with: secondElement)
        }
    }
    
    func updatePaymentField(containing item: ClearentPaymentItem?, with errorMessage: String?) {
        switch item?.type {
        case .securityCode:
            update(paymentField: rightPaymentTextField, with: errorMessage)
        default:
            update(paymentField: leftPaymentTextField, with: errorMessage)
        }
    }
    
    // MARK: - Private
    
    private func setup(paymentField: ClearentPaymentTextField, with item: ClearentPaymentItem) {
        paymentField.setup(with: item)
        paymentField.action = { [weak self] item, cardData in
            guard let strongSelf = self else { return }
            strongSelf.action?(item, cardData)
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
