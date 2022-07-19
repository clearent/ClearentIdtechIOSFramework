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
        return sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        if section.isCollapsable && !section.isCollapsed {
            return 0
        }
        return section.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]
        switch row.type {
            case .singleItem:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "ClearentPaymentTextField", for: indexPath) as? ClearentPaymentTextField {
                    cell.setup(with: row)
                    return cell
                }
                
            case .twoItems:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "ClearentPaymentTwoTextFields", for: indexPath) as? ClearentPaymentTwoTextFields {
                    cell.setup(with: row)
                    return cell
                }
        }
        return UITableViewCell()
    }
}

