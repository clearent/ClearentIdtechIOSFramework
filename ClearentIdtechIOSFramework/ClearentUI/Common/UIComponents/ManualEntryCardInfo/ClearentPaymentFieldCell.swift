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
    
    var action: ((ClearentPaymentItem?, String?) -> Void)?
    
    enum Layout {
        static let cellHeight: CGFloat = 94
        static let sectionHeaderViewHeight: CGFloat = 40
    }

    static let identifier = "ClearentPaymentFieldCell"
    static let nib = String(describing: ClearentPaymentFieldCell.self)
    
    // MARK: - Public
    
    static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentPaymentFieldCell.nib, bundle: Bundle(for: ClearentPaymentFieldCell.self)),
                           forCellReuseIdentifier: ClearentPaymentFieldCell.identifier)
    }
    
    func setup(with row: ClearentPaymentRow, isFirstCell: Bool, isLastCell: Bool) {
        guard let firstItem = row.elements[safe: 0] else { return }
        setup(paymentField: leftPaymentTextField, with: firstItem, isFirstCell: isFirstCell, isLastCell: isLastCell)
        // do not show the second text field if there is only one element in row
        rightPaymentTextField.isHidden = row.elements.count == 1

        if let secondItem = row.elements[safe: 1] {
            rightPaymentTextField.isHidden = false
            setup(paymentField: rightPaymentTextField, with: secondItem, isFirstCell: isFirstCell, isLastCell: isLastCell)
        }
    }
    
    func updatePaymentField(containing item: ClearentPaymentItem?) {
        guard let item = item else { return }

        switch item.type {
        case .securityCode:
            update(paymentField: rightPaymentTextField, with: item.isValid ? nil : item.errorMessage)
        default:
            update(paymentField: leftPaymentTextField, with: item.isValid ? nil : item.errorMessage)
        }
    }
    
    func setupNavigationActions(for tableView: UITableView) {
        leftPaymentTextField.nextButtonWasTapped = { identifier in
            tableView.nextResponder(identifier: identifier)
        }
        
        leftPaymentTextField.previousButtonWasTapped = { identifier in
            tableView.previousResponder(identifier: identifier)
        }
        
        rightPaymentTextField.nextButtonWasTapped = { identifier in
            tableView.nextResponder(identifier: identifier)
        }
        
        rightPaymentTextField.previousButtonWasTapped = { identifier in
            tableView.previousResponder(identifier: identifier)
        }
    }
    
    // MARK: - Private
    
    private func setup(paymentField: ClearentPaymentTextField, with item: ClearentPaymentItem, isFirstCell: Bool, isLastCell: Bool) {
        paymentField.setup(with: item, isFirstCell: isFirstCell, isLastCell: isLastCell)
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

private extension UITableView {
    func nextResponder(identifier: ItemIdentifier) {
        guard let identifier = identifier else { return }
        for i in (identifier.tag + 1) ..< (identifier.tag + 100) {
            if let view = viewWithTag(i), let containerView = view.superview?.superview as? ClearentPaymentTextField {
                handleJumpTo(textField: view, and: containerView, tag: i)
                break
            }
        }
    }

    func previousResponder(identifier: ItemIdentifier) {
        guard let identifier = identifier else { return }
        for i in (0 ..< identifier.tag).reversed() {
            if let view = viewWithTag(i), let containerView = view.superview?.superview as? ClearentPaymentTextField {
                handleJumpTo(textField: view, and: containerView, tag: i)
                break
            }
        }
    }

    private func handleJumpTo(textField: UIView, and textFieldContainer: ClearentPaymentTextField, tag _: Int) {
        textField.becomeFirstResponder()
        if let indexPath = textFieldContainer.item?.identifier?.indexPath {
            scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}
