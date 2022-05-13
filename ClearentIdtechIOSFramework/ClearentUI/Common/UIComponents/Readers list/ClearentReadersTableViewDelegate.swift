//
//  ClearentReadersTableViewDelegate.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 12.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol ClearentReadersTableViewProtocol: AnyObject {
    func didSelectCell(from indexPath: IndexPath)
}

class ClearentReadersTableViewDelegate: NSObject {

    weak var delegate: ClearentReadersTableViewProtocol?
    
    init(with delegate: ClearentReadersTableViewProtocol) {
        self.delegate = delegate
    }
}

extension ClearentReadersTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectCell(from: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ClearentReadersTableViewCell.Layout.cellHeight
    }
}
