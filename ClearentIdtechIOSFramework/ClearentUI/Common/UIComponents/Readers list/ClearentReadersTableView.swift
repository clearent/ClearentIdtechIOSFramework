//
//  ClearentReadersTableView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 11.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import CoreMedia
import UIKit

protocol ClearentReadersTableViewDelegate: AnyObject {
    func didSelectReader(_ reader: ReaderInfo)
    func didSelectReaderDetails(reader: ReaderInfo)
}

class ClearentReadersTableView: ClearentMarginableView {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    private var dataSource: [ReaderInfo]?
    private weak var delegate: ClearentReadersTableViewDelegate?
    
    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentPrimaryButton.self)
        ]
    }
    
    // MARK: Init
    
    convenience init(dataSource: [ReaderInfo], delegate: ClearentReadersTableViewDelegate) {
        self.init()
        
        self.dataSource = dataSource
        self.delegate = delegate
        
        setupTableView()
        tableView.reloadData()
    }
    
    // MARK: Private
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        ClearentReadersTableViewCell.register(tableView: tableView)
        
        guard let dataSource = dataSource else { return }
        heightConstraint.constant = CGFloat(dataSource.count) * ClearentReadersTableViewCell.Layout.cellHeight
    }
}

extension ClearentReadersTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClearentReadersTableViewCell.identifier,
                                                       for: indexPath) as? ClearentReadersTableViewCell,
              let dataSource = dataSource else { return UITableViewCell() }
        indexPath.row == 0 ? cell.setup(readerName: dataSource[indexPath.row].readerName, isConnected: dataSource[indexPath.row].isConnected, isFirstCell: true) : cell.setup(readerName: dataSource[indexPath.row].readerName)
        cell.detailsAction = { [weak self] in
            guard let delegate = self?.delegate else { return }
            delegate.didSelectReaderDetails(reader: dataSource[indexPath.row])
        }

        return cell
    }
}

extension ClearentReadersTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataSource = dataSource else { return }
        
        delegate?.didSelectReader(dataSource[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ClearentReadersTableViewCell.Layout.cellHeight
    }
}
