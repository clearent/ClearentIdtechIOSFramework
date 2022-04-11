//
//  AdaptiveStackView.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 07.04.2022.
//

import UIKit

/// A custom UIStackView  that supports subviews with different margins between them.
class AdaptiveStackView: UIStackView {
    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        handleSubviewsMargins()
    }

    // MARK: - Margins

    private func handleSubviewsMargins() {
        for index in 0 ..< arrangedSubviews.count {
            if let subview = arrangedSubviews[index] as? Marginable {
                var neighbor: Marginable?
                var neighborIndex = index

                while neighborIndex < arrangedSubviews.count {
                    neighbor = self.neighbor(from: neighborIndex)

                    if neighbor != nil {
                        break
                    }
                    neighborIndex += 1
                }
                subview.handleBottomMarging(to: neighbor)
            }
        }
    }

    private func neighbor(from index: Int) -> Marginable? {
        let nextIndex = index + 1
        if nextIndex >= arrangedSubviews.count {
            return nil
        }

        if let nextView = arrangedSubviews[nextIndex] as? Marginable {
            return nextView
        }

        return nil
    }
}
