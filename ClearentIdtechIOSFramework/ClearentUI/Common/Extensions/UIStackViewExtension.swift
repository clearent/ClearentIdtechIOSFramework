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

    func addRoundedCorners(backgroundColor: UIColor, radius: CGFloat, margin: CGFloat) {
        let subView = UIView(frame: CGRect(x: -margin, y: -margin, width: bounds.width + margin * 2, height: bounds.height + margin))
        subView.backgroundColor = backgroundColor
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
        subView.layer.cornerRadius = radius
        subView.layer.masksToBounds = true
        subView.clipsToBounds = true
    }
}
