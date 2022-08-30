//
//  String.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 11.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension String {
    /**
     * Used to access a specific character in a string
     * @param i,  position of the character in the string
     */
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}
