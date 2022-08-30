//
//  UIVIewExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 25.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

// MARK: - Constrains

extension UIView {
    func pinToEdges(edges: UIRectEdge = .all, of view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if edges.contains(.top) {
            constraints.append(topAnchor.constraint(equalTo: view.topAnchor))
        }
        if edges.contains(.bottom) {
            constraints.append(bottomAnchor.constraint(equalTo: view.bottomAnchor))
        }
        if edges.contains(.left) {
            constraints.append(leftAnchor.constraint(equalTo: view.leftAnchor))
        }
        if edges.contains(.right) {
            constraints.append(rightAnchor.constraint(equalTo: view.rightAnchor))
        }
        constraints.forEach { $0.isActive = true }
    }
}

// MARK: - Animations

extension UIView {
    func fadeIn(completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }

    func fadeOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.4, animations: {
            self.alpha = 0
        }) { _ in
            completion?()
        }
    }
}
