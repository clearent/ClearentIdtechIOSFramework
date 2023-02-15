//
//  Receipt.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.01.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

struct ReceiptEntity: CodableProtocol {
    
    // MARK: - Properties
    
    let emailAddress: String
    let id: Int

    enum CodingKeys: String, CodingKey {
        case emailAddress = "email-address", id = "id"
    }
}
