//
//  OfflineModeReportPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 01.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

struct ReportItem {
    let itemName: String
    let itemValue :String
    let isAmount: Bool
}

protocol ClearentOfflineModeReportProtocol {
    func clearAndProceed()
    func itemCount() -> Int
}

class ClearentOfflineModeReportPresenter {
    
}
