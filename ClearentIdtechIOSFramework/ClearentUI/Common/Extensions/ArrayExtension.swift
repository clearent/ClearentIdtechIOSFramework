//
//  ArrayExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 30.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension Array where Element: Equatable {
    /**
     * Used to get the next element in array.
     * @param after,  specifies the element after which next item is taken
     * Returns: next element in array. If the last element is reached, next item returned will be the first in the array
     */
    func nextItem(after: Element) -> Element? {
        if let index = firstIndex(of: after), index + 1 < count {
            return self[index + 1]
        } else {
            return self[safe: 0]
        }
    }
}
