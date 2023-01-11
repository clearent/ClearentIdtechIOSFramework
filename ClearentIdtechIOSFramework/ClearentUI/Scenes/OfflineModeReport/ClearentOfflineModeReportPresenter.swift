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

protocol ClearentOfflineViewProtocol {
    func showShareMenu(with fileURL: URL)
}

protocol ClearentOfflineModeReportViewProtocol {
    func reportHasErrors() -> Bool
    func clearAndProceed()
    func saveErrorLog()
    func itemCount() -> Int
    func itemForIndexPath(indexPath: IndexPath) -> ReportItem
}

class ClearentOfflineModeReportPresenter {
    private var dataSource: [ReportItem] = []
    private var offlineResultView: ClearentOfflineViewProtocol?
    
    init(view: ClearentOfflineViewProtocol) {
        offlineResultView = view
        updateDataSource()
    }
    
    func updateDataSource() {
        let transactions = ClearentWrapper.shared.retrieveAllOfflineTransactions()
        
        var approvedCount = 0
        var approvedAmount = 0.0
        var declinedCount = 0
        var declinedAmount = 0.0
        var errorCount = 0
        var errorAmount = 0.0
        
        transactions?.forEach({ transaction in
            if let errorStatus = transaction.errorStatus,
               let amount = Double(transaction.paymentData.saleEntity.amount) {
                if errorStatus.error.type == .gatewayDeclined {
                    declinedCount += 1
                    declinedAmount += amount
                } else if errorStatus.error.type == .none  {
                    approvedCount += 1
                    approvedAmount += amount
                } else {
                    errorCount += 1
                    errorAmount +=  amount
                }
            }
        })
        
        let result = [ReportItem(itemName: ClearentConstants.Localized.OfflineReport.approvedCount, itemValue: String(approvedCount), isAmount: false),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.approvedAmount, itemValue: approvedAmount.stringFormattedWithTwoDecimals?.setTwoDecimals() ?? "-", isAmount: true),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.declinedCount, itemValue: String(declinedCount), isAmount: false),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.declinedAmount, itemValue: declinedAmount.stringFormattedWithTwoDecimals?.setTwoDecimals() ?? "-", isAmount: true),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.errorCount, itemValue: String(errorCount), isAmount: false),
                      ReportItem(itemName: ClearentConstants.Localized.OfflineReport.errorAmount, itemValue: errorAmount.stringFormattedWithTwoDecimals?.setTwoDecimals() ?? "-", isAmount: true),
        ]
        
        dataSource = result
    }
}

extension ClearentOfflineModeReportPresenter : ClearentOfflineModeReportViewProtocol {
    
    func saveErrorLog() {
        let offlineManager = ClearentWrapper.shared.retrieveOfflineManager()
        let allTransactions = offlineManager?.transactionsWithErrors()
        let generator = ClearentOfflineResultPDFGenerator()
        let urlResult = generator.generateReport(transactions: allTransactions!)
        
        self.offlineResultView?.showShareMenu(with: urlResult)
    }
    
    func clearAndProceed() {
        let offlineManager = ClearentWrapper.shared.retrieveOfflineManager()
        let allTransactions = offlineManager?.retrieveAll()
        allTransactions?.forEach({ tr in
            if tr.errorStatus != nil {
                _ = offlineManager?.storage.deleteTransactionWith(id: tr.transactionID)
            }
        })
        
        updateDataSource()
    }
    
    func itemCount() -> Int {
        return dataSource.count
    }
    
    func itemForIndexPath(indexPath: IndexPath) -> ReportItem {
        return dataSource[indexPath.row]
    }
    
    func reportHasErrors() -> Bool {
        let offlineManager = ClearentWrapper.shared.retrieveOfflineManager()
        let allTransactions = offlineManager?.transactionsWithErrors()
        return !(allTransactions?.isEmpty ?? false)
    }
}
