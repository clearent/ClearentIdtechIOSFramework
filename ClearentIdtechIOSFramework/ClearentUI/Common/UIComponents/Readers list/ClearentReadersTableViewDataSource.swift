//
//  ClearentReadersTableViewDataSource.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 12.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearentReadersTableViewDataSourceProtocol {
    func numberOfElements() -> Int
}

class ClearentReadersTableViewDataSource: NSObject {

    public var dataSource: [ReaderInfo]
    
    // MARK: Init
    
    init(dataSource: [ReaderInfo]) {
        self.dataSource = dataSource
    }
}

extension ClearentReadersTableViewDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClearentReadersTableViewCell.identifier,
                                                       for: indexPath) as? ClearentReadersTableViewCell else { return UITableViewCell() }
        indexPath.row == 0 ? cell.setup(readerName: dataSource[indexPath.row].readerName, isFirstCell: true) : cell.setup(readerName: dataSource[indexPath.row].readerName)
        
        return cell
    }
}

extension ClearentReadersTableViewDataSource: ClearentReadersTableViewDataSourceProtocol {
    func numberOfElements() -> Int {
        dataSource.count
    }
}
