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
         
        let pageSize = CGSize(width: 595.2, height: 841.8)
        let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
        let printableRect = CGRect(x: pageMargins.left, y: pageMargins.top, width: pageSize.width - pageMargins.left - pageMargins.right, height: pageSize.height - pageMargins.top - pageMargins.bottom)
        let paperRect = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
        
        let renderer = UIPrintPageRenderer()
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let printFormatter = UISimpleTextPrintFormatter(attributedText: getContentString(transactions: transactions))
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
    
    // Group the transactions in merchantID/terminalID  key based and print a header for each of sublist
    func getContentString(transactions: [OfflineTransaction]) -> NSMutableAttributedString {
        
        var uniqueMerchantAndTerminals = [String]()
        var noIDTransactions = [OfflineTransaction]()
        
        transactions.forEach { tr in
            if let merchantID = tr.transactionResponse?.payload.transaction?.merchantID, let terminalID = tr.transactionResponse?.payload.transaction?.terminalID {
                if (!uniqueMerchantAndTerminals.contains(merchantID+terminalID)) {
                    uniqueMerchantAndTerminals.append(merchantID+terminalID)
                }
            } else {
                noIDTransactions.append(tr)
            }
        }
        
        let allData = NSMutableAttributedString()
        uniqueMerchantAndTerminals.forEach { id in
            
            let trs = transactions.filter {
                if let merchantID = $0.transactionResponse?.payload.transaction?.merchantID, let terminalID = $0.transactionResponse?.payload.transaction?.terminalID {
                   return  merchantID + terminalID == id
                }
                
                return false
            }
            
            if let header =  getHeaderString(transactions: trs) {
                allData.append(header)
                trs.forEach { tr in
                    let str = createTransactionString(for: transactionDictionary(for: tr))
                    allData.append(str)
                }
            }
        }
        
        noIDTransactions.forEach { tr in
            let str = createTransactionString(for: transactionDictionary(for: tr))
            allData.append(str)
        }
        
        return allData
    }
    
    func getHeaderString(transactions: [OfflineTransaction]) -> NSMutableAttributedString? {
        
        if (!transactions.isEmpty) {
            let tr = transactions.first
            if let merchantID = tr?.transactionResponse?.payload.transaction?.merchantID, let terminalID = tr?.transactionResponse?.payload.transaction?.terminalID {
                return createHeaderString(merchantName: merchantID, terminalID: terminalID)
            }
            
        }
        return nil
    }
    
    private func createSeparatorImage() -> NSMutableAttributedString  {
        let paraStyle = NSMutableParagraphStyle()
        let imageString = NSMutableAttributedString(string: "\n", attributes:  [.paragraphStyle : paraStyle])
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: ClearentConstants.IconName.separatorLine, in: ClearentConstants.bundle, compatibleWith: nil)
        imageString.append(NSAttributedString(attachment: attachment))
        return imageString
    }

    func createHeaderString(merchantName: String, terminalID: String) -> NSMutableAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [
            NSTextTab(textAlignment: .left, location: 0, options: [:]),
            NSTextTab(textAlignment: .right, location: 400, options: [:]),
        ]
        
        let date = Date().dateOnlyToString()
        let time = Date().timeToString()
        
        let line1 = ClearentConstants.Localized.OfflineMode.offlineModeMechantID + merchantName + "\t" + ClearentConstants.Localized.OfflineMode.offlineModeReportDate + date + "UTC" + "\n"
        let line2 = ClearentConstants.Localized.OfflineMode.offlineModeTerminalID + terminalID + "\t" + ClearentConstants.Localized.OfflineMode.offlineModeReportTime + time + "UTC" + "\n\n\n"
        
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
        
        text1.append(createSeparatorImage())
        
        return text1
    }
    
    func createTransactionString(for transactionData: [(String, String)]) -> NSMutableAttributedString {
        let emptyLine = NSMutableAttributedString(string: "\n")
        let transactionString = NSMutableAttributedString()
        
        transactionString.append(createSeparatorImage())
        transactionString.append(emptyLine)
        transactionString.append(emptyLine)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [
            NSTextTab(textAlignment: .left, location: 0, options: [:]),
            NSTextTab(textAlignment: .left, location: 140, options: [:]),
        ]
        
        for element in transactionData {
            let text = element.0 + "\t" + element.1
            let keyText = element.0 + "\t"
            
            let value = NSMutableAttributedString(string: text, attributes: [.paragraphStyle : paragraph])
            value.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogKeyLabelColor, range: NSRange(location: 0, length: element.0.count))
            value.addAttribute(.foregroundColor, value: ClearentUIBrandConfigurator.shared.colorPalette.errorLogValueLabelColor, range: NSRange(location: keyText.count, length: element.1.count))
            value.addAttribute(.font, value: ClearentUIBrandConfigurator.shared.fonts.offlineReportFieldLabel, range: NSRange(location: 0, length: text.count))
            transactionString.append(value)
            transactionString.append(emptyLine)
        }

        return transactionString
    }
    
    func transactionDictionary(for transaction: OfflineTransaction) -> [(String, String)] {
        
        var transactionData: [(String, String)] = []
        
        let transactionResponse = transaction.transactionResponse?.payload.transaction
        
        if let createdDate = transaction.createdDate?.toDateUseShortFormat() {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineDate, createdDate.dateOnlyToString() + "UTC"))
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOfflineTime, createdDate.timeToString() + "UTC"))
        }
        
        if let id = transaction.transactionResponse?.payload.transaction?.id {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportTransactionID,id))
        }
        
        let extID = transaction.paymentData.saleEntity.externelRefID ?? transaction.transactionID
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportExternalRefID, extID))
                
        if let lastFour = transactionResponse?.lastFourDigits {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportLastFourDigits, lastFour))
        }
        
        if let expDate = transactionResponse?.epirationDate {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportExpirationDate, expDate))
        }
        
        var totalAmount = 0.0
        if let amount = transactionResponse?.amount {
            totalAmount = totalAmount + (transactionResponse?.amount?.double ?? 0.0)
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportAmount, "$ " + amount.setTwoDecimals()))
        }
        
        if let tipAmount = transactionResponse?.tipAmount {
            totalAmount = totalAmount + (transactionResponse?.tipAmount?.double ?? 0.0)
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportTipAmount, "$ " + tipAmount.setTwoDecimals()))
        }
        
        if let empowerAmount = transactionResponse?.empowerAmount {
            totalAmount = totalAmount + (transactionResponse?.empowerAmount?.double ?? 0.0)
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportEmpowerAmount, "$ " + empowerAmount.setTwoDecimals()))
        }
        
        if let totalAmount = totalAmount.stringFormattedWithTwoDecimals {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportTotalAmount, "$ " + totalAmount))
        }
        
        if let customerID = transactionResponse?.customerID {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportCustomerID, customerID))
        }
        
        if let orderID = transactionResponse?.orderID {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportOrderID, orderID))
        }
        
        if let invoice = transactionResponse?.invoice {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportInvoice, invoice))
        }
        
        if let billingAddress = transactionResponse?.billing, let street = billingAddress.street {
        transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportBillingAddress, street))
        }
        
        if let shippingAddress = transactionResponse?.shipping, let shippingStreet = shippingAddress.street {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportShippingAddress, shippingStreet))
        }

        if let softwareType = transactionResponse?.softwareType {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportSoftwareType, softwareType))
        }
                
        if let sdkVersion = transaction.sdkVersion {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportSoftwareVersion, sdkVersion))
        }
        
        if let errorMessage = transactionResponse?.message, let code = transaction.transactionResponse?.payload.error?.code {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportError, errorMessage + ", \(code)"))
        }
        
        if let errorDate = transaction.errorStatus?.updatedDate.toDateUseShortFormat() {
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportErrorDate, errorDate.dateOnlyToString() + "UTC"))
            transactionData.append((ClearentConstants.Localized.OfflineMode.offlineModeReportErrorTime, errorDate.timeToString() + "UTC"))
        }
        
        return transactionData
    }
}
