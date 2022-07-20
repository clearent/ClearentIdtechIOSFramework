//
//  ClearentPaymentTwoFieldsCell.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentPaymentTwoFieldsCell: UITableViewCell {
    
    static let nib = "ClearentPaymentTwoFieldsCell"
    static let identifier = "ClearentPaymentTwoFieldsCellIdentifier"
    
    @IBOutlet weak var expirationDateCell: ClearentPaymentFieldCell!
    @IBOutlet weak var securityCodeCell: ClearentPaymentFieldCell!
    
    static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentPaymentTwoFieldsCell.nib, bundle: Bundle(for: ClearentPaymentTwoFieldsCell.self)),
                           forCellReuseIdentifier: ClearentPaymentTwoFieldsCell.identifier)
    }
    
    func setup(with row: ClearentPaymentRow) {
        expirationDateCell.setup(with: row.elements[0])
        securityCodeCell.setup(with: row.elements[1])
    }
}
