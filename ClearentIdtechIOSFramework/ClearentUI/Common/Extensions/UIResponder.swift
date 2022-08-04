//
//  UIResponder.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 04.08.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension UIResponder {

    private struct Static {
        static weak var responder: UIResponder?
    }

    /// Finds the current first responder
    /// - Returns: the current UIResponder if it exists
    static func currentFirst() -> UIResponder? {
        Static.responder = nil
        UIApplication.shared.sendAction(#selector(UIResponder._trap), to: nil, from: nil, for: nil)
        return Static.responder
    }

    @objc private func _trap() {
        Static.responder = self
    }
}
