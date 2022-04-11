//
//  UIStackViewExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 10.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
