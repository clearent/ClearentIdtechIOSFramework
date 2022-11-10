//
//  Crypto.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 02.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import CryptoKit

@objc public class Crypto: NSObject {
    @objc public static func SHA256hash(data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
