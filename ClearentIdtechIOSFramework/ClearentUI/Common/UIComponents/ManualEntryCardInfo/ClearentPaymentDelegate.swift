//
//  ClearentPaymentDelegate.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 20.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

protocol ClearentManualEntryFormDelegate: AnyObject {
    
}

class ClearentPaymentDelegate: NSObject, ClearentManualEntryFormDelegate {
    
    weak var delegate: ClearentManualEntryFormDelegate?
    
    // MARK: - Init
    
    init(with delegate: ClearentManualEntryFormDelegate) {
        self.delegate = delegate
    }
}

extension ClearentPaymentDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
