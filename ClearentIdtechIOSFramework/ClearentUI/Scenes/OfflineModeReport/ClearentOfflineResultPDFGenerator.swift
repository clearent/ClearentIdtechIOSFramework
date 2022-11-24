//
//  ClearentOfflineResultPDFGenerator.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 24.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation


class ClearentOfflineResultPDFGenerator {
    
    func generateReport(transactions: [OfflineTransaction]) -> URL {
        let width = 1024.0
        let height = 780.0
    
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputFileURL = documentsDirectory.appendingPathComponent("file.pdf")

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: width, height: height))

      

            let pageSize = CGSize(width: 595.2, height: 841.8)
            let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
            let printableRect = CGRect(x: pageMargins.left, y: pageMargins.top, width: pageSize.width - pageMargins.left - pageMargins.right, height: pageSize.height - pageMargins.top - pageMargins.bottom)
            let paperRect = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
            
            let renderer = UIPrintPageRenderer()
            renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
            renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
            
            let allData = NSMutableAttributedString()
            transactions.forEach { tr in
                let str = createTransactionString(for: transactionDictionary(for: tr))
                allData.append(str)
            }
        
            let printFormatter = UISimpleTextPrintFormatter(attributedText: allData)
            renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
            
            let pdfData = NSMutableData()

            UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
            renderer.prepare(forDrawingPages: NSMakeRange(0, renderer.numberOfPages))
            
            let bounds = UIGraphicsGetPDFContextBounds()
            for i in 0  ..< renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: i, in: bounds)
            }

            UIGraphicsEndPDFContext()
            
            do {
                try pdfData.write(to: outputFileURL)
            } catch {
                print(error.localizedDescription)
            }
        
        return outputFileURL
    }
    
    func createTransactionString(for transaction: [String: String]) -> NSMutableAttributedString {
        let transactionString = NSMutableAttributedString()
        
        for element  in transaction {
            let text = NSAttributedString(string: element.key + element.value)
            transactionString.append(text)
            
            let space = NSMutableAttributedString(string: "\n")
            transactionString.append(space)
        }
        
        return transactionString
    }
    
    func transactionDictionary(for transaction: OfflineTransaction) -> [String:String] {
        return [ClearentConstants.Localized.OfflineMode.offlineModeMechantID:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeTerminalID:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportDate:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportTime:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineDate:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineTime:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportTransactionID:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportExternalRefID:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportCardHolderName:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportCardType:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportLastFourDigits:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportExpirationDate:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportAmount:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportTipAmount:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportEmpowerAmount:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportTotalAmount:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportCustomerID:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportOrderID:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportInvoice:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportBillingAddress:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportShippingAddress:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportSoftwareType:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportSoftwareVersion:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportError:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportErrorDate:"1312123131",
                ClearentConstants.Localized.OfflineMode.offlineModeReportErrorTime:"1312123131"]
    }
}
