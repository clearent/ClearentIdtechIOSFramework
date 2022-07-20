//
//  ClearentManualCardEntryTableView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


class ClearentPaymentDataSource: NSObject {
    var sections: [ClearentPaymentSection]

    init(with sections: [ClearentPaymentSection]) {
        self.sections = sections
    }
}

extension ClearentPaymentDataSource: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        
        return (section.isCollapsable && !section.isCollapsed) ? 0 : section.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]
        
        switch row.type {
            case .singleItem:
            if let cell = tableView.dequeueReusableCell(withIdentifier: ClearentPaymentFieldCell.identifier, for: indexPath) as? ClearentPaymentFieldCell {
                    cell.setup(with: row.elements[0])
                    
                    return cell
                }
            case .twoItems:
            if let cell = tableView.dequeueReusableCell(withIdentifier: ClearentPaymentTwoFieldsCell.identifier, for: indexPath) as? ClearentPaymentTwoFieldsCell {
                    cell.setup(with: row)
                    
                    return cell
                }
        }
        return UITableViewCell()
    }
}
