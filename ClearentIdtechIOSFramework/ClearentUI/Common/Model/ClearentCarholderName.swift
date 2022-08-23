//
//  ClearentCarholderName.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 09.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

struct ClearentCarholderName {
    var first: String?
    var last: String?

    init(fullName: String?) {
        guard var names = fullName?.components(separatedBy: " ") else { return }
        first = names.removeFirst()
        last = names.joined(separator: " ")
    }
}
