//
//  ClearentMarginableExtension.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 12.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

extension ClearentMarginable {
    func testBottomMargin<T>(for type: T.Type, margin: CGFloat) {
        // Given
        guard let bottomMargin = self.margins.first(where: { ($0 as? RelativeBottomMargin)?.relatedViewType == type }) else {
            XCTFail("Missing bottom margin to \(type)")
            return
        }
        
        // Then
        XCTAssertEqual(bottomMargin.constant, margin)
    }
}


extension OfflineModeManager {
    func generateOfflineTransactions(count: Int, cardReaderTransactions: Bool) {
        for index in 1...count {
            let amount = "\(index).00"
            
            // manual entry transactions
            var cardSaleEntity = SaleEntity(amount: amount, card: "4111111111111111", csc: "999", expirationDateMMYY: "1132")
            var paymentData = PaymentData(saleEntity: cardSaleEntity)
            
            if cardReaderTransactions {
                // card reader transactions
                cardSaleEntity = SaleEntity(amount: amount)
                paymentData = PaymentData(saleEntity: cardSaleEntity, cardToken: "some_secret_token_here".data(using: .utf8))
            }
            let oftr = OfflineTransaction(paymentData: paymentData)
            _ = saveOfflineTransaction(transaction: oftr)
        }
    }
}
