//
//  ClearentStringExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 12.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension String {
    var localized: String {
        return NSLocalizedString(self, bundle: ClearentConstants.bundle, comment: self)
    }
}
