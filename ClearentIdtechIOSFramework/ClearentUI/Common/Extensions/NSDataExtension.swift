//
//  NSDataExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 14.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

extension NSData {
    var int: Int {
        var out: Int = 0
        getBytes(&out, length: MemoryLayout<Int>.size)
        return out
    }
}
