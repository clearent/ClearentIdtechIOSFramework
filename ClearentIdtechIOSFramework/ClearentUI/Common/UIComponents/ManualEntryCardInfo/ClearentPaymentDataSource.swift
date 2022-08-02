//
//  ClearentManualCardEntryTableView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//



protocol ClearentPaymentDataSourceProtocol: AnyObject {
    func didFinishCompletePaymentField(item: ClearentPaymentItem?, value: String?)
}

class ClearentPaymentDataSource: NSObject {
    var sections: [ClearentPaymentSection]
    weak var delegate: ClearentPaymentDataSourceProtocol?

    init(with sections: [ClearentPaymentSection], delegate: ClearentPaymentDataSourceProtocol) {
        self.sections = sections
        self.delegate = delegate
    }
}

extension ClearentPaymentDataSource: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        
        return (section.isCollapsable && section.isCollapsed) ? 0 : section.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: ClearentPaymentFieldCell.identifier, for: indexPath) as? ClearentPaymentFieldCell {
            cell.setup(with: row)
            
            cell.action = { [weak self] item, cardData in
                guard let strongSelf = self else { return }
                let isCardDataValid = ClearentFieldValidationHelper.validateCardData(cardData, field: item)
                
                if isCardDataValid {
                    strongSelf.delegate?.didFinishCompletePaymentField(item: item, value: cardData)
                    cell.updatePaymentField(containing: item, with: nil)
                } else {
                    cell.updatePaymentField(containing: item, with: item?.errorMessage)
                }
            }
            return cell
        }
        return UITableViewCell()
    }
}
