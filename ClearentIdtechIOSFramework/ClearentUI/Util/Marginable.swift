//
//  Marginable.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 06.04.2022.
//

import UIKit

protocol Marginable {
    var viewType: UIView.Type { get }
    var margings: [RelativeMargin] { get }
    func handleBottomMarging(to neighbor: Marginable?)
    func setBottomMargin(margin: RelativeMargin)
}

extension Marginable {
    func handleBottomMarging(to neighbor: Marginable?) {
        guard let neighbor = neighbor,
              let margin =  margings.first(where: { neighbor.viewType == $0.relatedViewType }) else { return }
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
