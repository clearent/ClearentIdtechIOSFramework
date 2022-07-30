//
//  ClearentManualCardEntryTableView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 19.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//



protocol ClearentPaymentDataSourceProtocol: AnyObject {
    func didFinishCompletePaymentField(type: ClearentPaymentItemType?, value: String?)
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
            
            cell.action = { [weak self] fieldType, cardData in
                guard let strongSelf = self else { return }
                let isCardDataValid = ClearentFieldValidationHelper.validateCardData(cardData, field: fieldType)
                
                if isCardDataValid {
                    strongSelf.delegate?.didFinishCompletePaymentField(type: fieldType, value: cardData)
                    cell.updatePaymentField(containing: fieldType, with: nil)
                } else {
                    cell.updatePaymentField(containing: fieldType, with: fieldType?.errorMessage)
                }
            }
            return cell
        }
        return UITableViewCell()
    }
}
