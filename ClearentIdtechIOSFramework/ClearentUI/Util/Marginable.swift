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
    func createBottomMargings(at index: Int, with neighbor: Marginable?)
    func setBottomMargin(value: RelativeMargin)
}

extension Marginable {
    func createBottomMargings(at index: Int, with neighbor: Marginable?) {
        guard let neighbor = neighbor else { return }
        for margin in margings {
            if neighbor.viewType == margin.relatedViewType {
                setBottomMargin(value: margin)
            }
        }
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

