//
//  UICollection.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 01.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
