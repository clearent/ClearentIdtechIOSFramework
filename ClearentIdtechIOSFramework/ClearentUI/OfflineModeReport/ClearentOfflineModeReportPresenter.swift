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
    private var dataSource: [ReportItem] = []
    
    init() {
        updateDataSource()
    }
    
    func updateDataSource() {
        let transactions = ClearentWrapper.shared.retriveAllOfflineTransactions()
        
        var approvedCount = 0
        var approvedAmount = 0.0
        var declinedCount = 0
        var declinedAmount = 0.0
        var errorCount = 0
        var errorAmount = 0.0
        
        transactions?.forEach({ transaction in
            if let errorStatus = transaction.errorStatus {
                if errorStatus.error.type == .httpError {
                    declinedCount = declinedCount + 1
                    if let amount = Double(transaction.paymentData.saleEntity.amount) {
                        declinedAmount = declinedAmount + amount
                    }
                } else if errorStatus.error.type == .httpError {
                    errorCount = errorCount + 1
                    if let amount = Double(transaction.paymentData.saleEntity.amount) {
                        errorAmount = errorAmount + amount
                    }
                }
            } else {
                approvedCount = approvedCount + 1
                if let amount = Double(transaction.paymentData.saleEntity.amount) {
                    approvedAmount = approvedAmount + amount
                }
            }
        })
        
        let result = [ReportItem(itemName: ClearentConstants.Localized.OfflineReport.approvedCount, itemValue: String(approvedCount), isAmount: false),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.approvedAmount, itemValue: String(approvedAmount), isAmount: true),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.declinedCount, itemValue: String(declinedCount), isAmount: false),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.declinedAmount, itemValue: String(declinedAmount), isAmount: true),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.errorCount, itemValue: String(errorCount), isAmount: false),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.errorAmount, itemValue: String(errorAmount), isAmount: true),
        ]
        
        dataSource = result
    }
}

extension ClearentOfflineModeReportPresenter : ClearentOfflineModeReportViewProtocol {
    
    func saveErrorLog() {
        
    }
    
    func clearAndProceed() {
        // do something
    }
    
    func itemCount() -> Int {
        return dataSource.count
    }
    
    func itemForIndexPath(indexPath: IndexPath) -> ReportItem {
        return dataSource[indexPath.row]
    }
}
