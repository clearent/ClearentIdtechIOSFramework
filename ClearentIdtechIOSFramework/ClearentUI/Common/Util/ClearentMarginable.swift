//
//  ClearentMarginable.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 06.04.2022.
//

import UIKit

// Helper class used to create space between two views
protocol ClearentMarginable {
    var viewType: UIView.Type { get }
    var margins: [RelativeMargin] { get }
    func handleBottomMarging(to neighbor: ClearentMarginable?)
    func setBottomMargin(margin: RelativeMargin)
}

extension ClearentMarginable {
    func handleBottomMarging(to neighbor: ClearentMarginable?) {
        guard let neighbor = neighbor,
              let margin = margins.first(where: { neighbor.viewType == $0.relatedViewType }) else { return }
        setBottomMargin(margin: margin)
    }
}

class RelativeMargin {
    var constant: CGFloat
    var relatedViewType: UIView.Type
    public init(constant: CGFloat, relatedViewType: UIView.Type) {
        self.constant = constant
        self.relatedViewType = relatedViewType
    }
}
