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

protocol ClearentOfflineModeReportViewProtocol {
    func clearAndProceed()
    func saveErrorLog()
    func itemCount() -> Int
    func itemForIndexPath(indexPath: IndexPath) -> ReportItem
}

class ClearentOfflineModeReportPresenter {
    private var dataSource: [ReportItem]
    
    init() {
        dataSource = []
    }
}

extension ClearentOfflineModeReportPresenter : ClearentOfflineModeReportViewProtocol {
    
    func saveErrorLog() {
        
    }
    
    func clearAndProceed() {
        // do something
    }
    
    func itemCount() -> Int {
        return 6 //dataSource.count
    }
    
    func itemForIndexPath(indexPath: IndexPath) -> ReportItem {
        ReportItem(itemName: "Something", itemValue: "40", isAmount: true)
    }
}
