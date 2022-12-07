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
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputFileURL = documentsDirectory.appendingPathComponent("OfflineErrorsReport.pdf")
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 565, height: 600))
        
        let pageSize = CGSize(width: 595.2, height: 841.8)
        let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
        let printableRect = CGRect(x: pageMargins.left, y: pageMargins.top, width: pageSize.width - pageMargins.left - pageMargins.right, height: pageSize.height - pageMargins.top - pageMargins.bottom)
        let paperRect = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
        
        let renderer = UIPrintPageRenderer()
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let allData = NSMutableAttributedString()
        
        allData.append(createHeaderString(merchantName: "Ovidiu's Beach Bar", terminalID: "12456798", date: "2022-17-11", time: "10:07:20"))
        
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
    
    func createHeaderString(merchantName: String, terminalID: String, date: String, time: String) -> NSMutableAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [
            NSTextTab(textAlignment: .left, location: 0, options: [:]),
            NSTextTab(textAlignment: .right, location: 400, options: [:]),
        ]
        
        let line1 = ClearentConstants.Localized.OfflineMode.offlineModeMechantID + merchantName + "\t" + ClearentConstants.Localized.OfflineMode.offlineModeReportDate + date + "\n"
        let line2 = ClearentConstants.Localized.OfflineMode.offlineModeTerminalID + terminalID + "\t" + ClearentConstants.Localized.OfflineMode.offlineModeReportTime + time + "\n\n\n"
        
        let text1 = NSMutableAttributedString(string: line1, attributes: [.paragraphStyle : paragraph])
        text1.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogKeyLabelColor, range: NSRange(location: 0, length: ClearentConstants.Localized.OfflineMode.offlineModeMechantID.count))
        text1.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogValueLabelColor, range: NSRange(location: ClearentConstants.Localized.OfflineMode.offlineModeMechantID.count, length: merchantName.count))
        
        let leftText = ClearentConstants.Localized.OfflineMode.offlineModeMechantID + merchantName + "\t"
        text1.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogKeyLabelColor, range: NSRange(location: leftText.count, length: ClearentConstants.Localized.OfflineMode.offlineModeReportDate.count))
        
        let lastLocation = leftText.count + ClearentConstants.Localized.OfflineMode.offlineModeReportDate.count
        text1.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogValueLabelColor, range: NSRange(location: lastLocation, length: date.count))
        
        let text2 = NSMutableAttributedString(string: line2, attributes: [.paragraphStyle : paragraph])
        text2.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogKeyLabelColor, range: NSRange(location: 0, length: ClearentConstants.Localized.OfflineMode.offlineModeTerminalID.count))
        text2.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogValueLabelColor, range: NSRange(location: ClearentConstants.Localized.OfflineMode.offlineModeTerminalID.count, length: terminalID.count))
        
        let leftText2 = ClearentConstants.Localized.OfflineMode.offlineModeTerminalID + terminalID + "\t"
        text2.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogKeyLabelColor, range: NSRange(location: leftText2.count, length: ClearentConstants.Localized.OfflineMode.offlineModeReportTime.count))
        
        let lastLocation2 = leftText2.count + ClearentConstants.Localized.OfflineMode.offlineModeReportTime.count
        text2.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogValueLabelColor, range: NSRange(location: lastLocation2, length: time.count))
        
        text1.append(text2)
        
        //        let paraStyle = NSMutableParagraphStyle()
        //        let imageString = NSMutableAttributedString(string: "\n", attributes:  [.paragraphStyle : paraStyle])
        //        let attachment = NSTextAttachment()
        //        attachment.image = UIImage(named: "left-arrow")
        //        imageString.append(NSAttributedString(attachment: attachment))
        //        text1.append(imageString)
        
        return text1
    }
    
    func createTransactionString(for transactionData: [(String, String)]) -> NSMutableAttributedString {
        let transactionString = NSMutableAttributedString()
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [
            NSTextTab(textAlignment: .left, location: 0, options: [:]),
            NSTextTab(textAlignment: .left, location: 140, options: [:]),
        ]
        
        for element  in transactionData {
            let text = element.0 + "\t" + element.1
            let keyText = element.0 + "\t"
            
            let value = NSMutableAttributedString(string: text, attributes: [.paragraphStyle : paragraph])
            value.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogKeyLabelColor, range: NSRange(location: 0, length: element.0.count))
            value.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogValueLabelColor, range: NSRange(location: keyText.count, length: element.1.count))
            value.addAttribute(.font, value: ClearentUIBrandConfigurator.shared.fonts.offlineReportFieldLabel, range: NSRange(location: 0, length: text.count))
            transactionString.append(value)
            
            let space = NSMutableAttributedString(string: "\n")
            transactionString.append(space)
        }
        
        
        transactionString.append(NSMutableAttributedString(string: "\n\n"))
        return transactionString
    }
    
    func transactionDictionary(for transaction: OfflineTransaction) -> [(String, String)] {
        
        var transactionData: [(String, String)] = []
        
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineDate, "20.02.1998"))
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineTime, "22:44"))
        
        if let id = transaction.transactionResponse?.code {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineDate,id))
        }
        
        // External ref ID, if this is not provided will be the offline transaction id
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportExternalRefID, transaction.transactionID))
        
        // we don't have the cardholder name
        if let name = transaction.transactionResponse?.payload.transaction?.customerFirstName, let lastName = transaction.transactionResponse?.payload.transaction?.customerLastName {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportCardHolderName,name + lastName))
        }
        
        if let lastFour = transaction.transactionResponse?.payload.transaction?.lastFourDigits {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportLastFourDigits, lastFour))
        }
        
        if let expDate = transaction.transactionResponse?.payload.transaction?.epirationDate {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportExpirationDate, expDate))
        }
        
        if let amount = transaction.transactionResponse?.payload.transaction?.amount {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportAmount, amount))
        }
        
        if let tipAmount = transaction.transactionResponse?.payload.transaction?.amount {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportAmount, tipAmount))
        }
        
        if let empowerAmount = transaction.transactionResponse?.payload.transaction?.empowerAmount {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportEmpowerAmount, empowerAmount))
        }
        
        if let empowerAmount = transaction.transactionResponse?.payload.transaction?.empowerAmount {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportEmpowerAmount, empowerAmount))
        }
        
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportTotalAmount, "0"))
        
        if let customerID = transaction.transactionResponse?.payload.transaction?.customerID {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportCustomerID, customerID))
        }
        
        if let orderID = transaction.transactionResponse?.payload.transaction?.orderID {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOrderID, orderID))
        }
        
        if let invoice = transaction.transactionResponse?.payload.transaction?.invoice {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportInvoice, invoice))
        }
        
        if let billingAddress = transaction.transactionResponse?.payload.transaction?.billing {
            let address = billingAddress.city + " " + billingAddress.street  + " " + billingAddress.lastName + " " + billingAddress.firstName
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportBillingAddress, address))
        }
        
        if let shippingAddress = transaction.transactionResponse?.payload.transaction?.shipping {
            let address = shippingAddress.city + " " + shippingAddress.street  + " " + shippingAddress.lastName + " " + shippingAddress.firstName
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportShippingAddress, address))
        }
        
        if let shippingAddress = transaction.transactionResponse?.payload.transaction?.shipping {
            let address = shippingAddress.city + " " + shippingAddress.street  + " " + shippingAddress.lastName + " " + shippingAddress.firstName
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportShippingAddress, address))
        }
        
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportSoftwareType, "Xplor SDK"))
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportSoftwareVersion, "1.0"))
        
        
        if let errorMessage = transaction.transactionResponse?.payload.transaction?.message {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportError, errorMessage))
        }
        
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportErrorDate, "20.02.1998"))
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportErrorTime, "22:44"))
        
        return transactionData
    }
}
