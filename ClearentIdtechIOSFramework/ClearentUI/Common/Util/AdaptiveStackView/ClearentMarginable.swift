//
//  ClearentMarginable.swift
//  XplorPayMobile
//
//  Created by Carmen Jurcovan on 06.04.2022.
//

import UIKit

// Helper class used to create space between two views
public protocol ClearentMarginable {
    var viewType: UIView.Type { get }
    var margins: [BottomMargin] { get }
    func handleBottomMargin(to neighbor: ClearentMarginable?)
    func setBottomMargin(margin: BottomMargin)
}

extension ClearentMarginable {
    public func handleBottomMargin(to neighbor: ClearentMarginable?) {
        for margin in margins {
            if let relatedViewMargin = margin as? RelativeBottomMargin {
                if neighbor != nil, neighbor?.viewType == relatedViewMargin.relatedViewType {
                    setBottomMargin(margin: margin)
                }
            } else if neighbor == nil {
                setBottomMargin(margin: margin)
            }
        }
    }
}

public class BottomMargin {
    var constant: CGFloat

    init(constant: CGFloat) {
        self.constant = constant
    }
}

class RelativeBottomMargin: BottomMargin {
    var relatedViewType: UIView.Type
    public init(constant: CGFloat, relatedViewType: UIView.Type) {
        self.relatedViewType = relatedViewType
        super.init(constant: constant)
    }
}
