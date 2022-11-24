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

        do {
            try pdfRenderer.writePDF(to: outputFileURL) { context in
                context.beginPage()

                let attributes: [NSAttributedString.Key: Any] = [
                    .font : UIFont.systemFont(ofSize: 20, weight: .semibold)
                ]

                let text = "Offline Transactions Error Log"
                let titleSize = (text as NSString).size(withAttributes: attributes)
                
                
                (text as NSString).draw(at: CGPoint(x: (width - titleSize.width)/2, y: 20), withAttributes: attributes)
            }
        } catch {
            print("Could not create PDF file: \(error)")
        }
        
        return outputFileURL
    }
    
    func createdPDF() {
        
    }
}
