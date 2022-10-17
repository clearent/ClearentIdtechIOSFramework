//
//  StringExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 11.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension String {
    func setTwoDecimals() -> String {
        let valueArray = self.split(separator: ".")
        if (valueArray.last?.count == 1) {
            return self + "0"
        }
        return self
    }
}
