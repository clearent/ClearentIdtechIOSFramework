//
//  SignatureEntity.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

struct SignatureEntity: CodableProtocol {
    let base64Image, created: String
    let transactionID: Int

    enum CodingKeys: String, CodingKey {
        case base64Image = "base-64-image"
        case created
        case transactionID = "transaction-id"
    }
}
