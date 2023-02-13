//
//  ClearentOfflineManagerExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 09.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

@testable import ClearentIdtechIOSFramework

extension OfflineModeManager {
    func generateOfflineTransactions(count: Int, cardReaderTransactions: Bool) {
        for index in 1...count {
            let amount = "\(index).00"
            
            // manual entry transactions
            var cardSaleEntity = SaleEntity(amount: amount, card: "4111111111111111", csc: "999", expirationDateMMYY: "1145")
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
