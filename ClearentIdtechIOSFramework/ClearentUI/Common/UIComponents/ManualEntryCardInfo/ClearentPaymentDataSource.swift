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
        super.init()
        self.setupIdentifiersForElements()
    }
    
    private func setupIdentifiersForElements() {
        var tag = 100
        for i in sections.indices {
            for j in sections[i].rows.indices {
                for k in sections[i].rows[j].elements.indices {
                    self.sections[i].rows[j].elements[k].identifier = (tag: tag, indexPath: IndexPath(row: j, section: i))
                    tag += 1
                }
            }
        }
    }
}

extension ClearentPaymentDataSource: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        return section.isCollapsed ? 0 : section.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let row = section.rows[indexPath.row]

        if let cell = tableView.dequeueReusableCell(withIdentifier: ClearentPaymentFieldCell.identifier, for: indexPath) as? ClearentPaymentFieldCell {
            let isLastCell = isLastCell(indexPath: indexPath)
            let isFirstCell = isFirstCell(indexPath: indexPath)
            cell.setup(with: row, isFirstCell: isFirstCell, isLastCell: isLastCell)
            cell.setupNavigationActions(for: tableView)
            cell.action = { [weak self] item, cardData in
                guard let strongSelf = self else { return }
                strongSelf.handleCellAction(cell: cell, item: item, cardData: cardData)
            }
            return cell
        }
        return UITableViewCell()

    }
    
    private func handleCellAction(cell: ClearentPaymentFieldCell, item: ClearentPaymentItem?, cardData: String?) {
        guard var item = item else { return }
        
        let isCardDataValid = ClearentFieldValidationHelper.validateCardData(cardData, field: item)
        item.isValid = isCardDataValid
        item.enteredValue = cardData ?? ""
        
        if isCardDataValid {
            delegate?.didFinishCompletePaymentField(item: item, value: cardData)
            cell.updatePaymentField(containing: item, with: nil)
        } else {
            cell.updatePaymentField(containing: item, with: item.errorMessage)
        }
    }
    
    private func isFirstCell(indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && indexPath.row == 0
    }
    
    private func isLastCell(indexPath: IndexPath) -> Bool {
        if sections[indexPath.section].rows.count == indexPath.row + 1 {
            if let nextSection = sections[safe: indexPath.section + 1], nextSection.isCollapsed {
                return true
            } else if sections[safe: indexPath.section + 1] == nil {
                return true
            }
        }
        return false
    }
}
