//
//  AdaptiveStackView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A custom UIStackView  that supports subviews with different margins between them.
public class ClearentAdaptiveStackView: UIStackView {
    // MARK: - Lifecycle

    public override func layoutSubviews() {
        super.layoutSubviews()
        handleSubviewsMargins()
    }
    
    public func positionView(onTop: Bool, of view: UIView) {
        let margin = ClearentConstants.Size.modalStackViewMargin
        removeFromSuperview()
        view.addSubview(self)
        alpha = 0
        topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin).isActive = onTop
        heightAnchor.constraint(lessThanOrEqualToConstant: view.frame.height / 1.3).isActive = onTop
        
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin).isActive = !onTop
        topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: margin).isActive = !onTop

        leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: margin).isActive = true
        rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -margin).isActive = true
        
        UIView.animate(withDuration: 0.5, delay: 0.1) { [weak self] in
            self?.alpha = 1.0
        }
    }

    // MARK: - Margins

    private func handleSubviewsMargins() {
        for index in 0 ..< arrangedSubviews.count {
            if let subview = arrangedSubviews[index] as? ClearentMarginable {
                var neighbor: ClearentMarginable?
                var neighborIndex = index

                while neighborIndex < arrangedSubviews.count {
                    neighbor = self.neighbor(from: neighborIndex)

                    if neighbor != nil {
                        break
                    }
                    neighborIndex += 1
                }
                subview.handleBottomMargin(to: neighbor)
            }
        }
    }

    private func neighbor(from index: Int) -> ClearentMarginable? {
        let nextIndex = index + 1
        if nextIndex >= arrangedSubviews.count {
            return nil
        }

        if let nextView = arrangedSubviews[nextIndex] as? ClearentMarginable {
            return nextView
        }

        return nil
    }
}
