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
    var margins: [Margin] { get }
    func handleBottomMargin(at row: Int, to neighbor: ClearentMarginable?)
    func setBottomMargin(margin: Margin)
}

extension ClearentMarginable {
    func handleBottomMargin(at row: Int, to neighbor: ClearentMarginable?) {
        var currentRow = row

        if neighbor == nil {
            // current element has no neighbor => last element
            currentRow = -1
        }

        for margin in margins {
            if let relatedViewMargin = margin as? RelativeMargin {
                if neighbor != nil, neighbor?.viewType == relatedViewMargin.relatedViewType {
                    setBottomMargin(margin: margin)
                }
            }

            if let absoluteMargin = margin as? AbsoluteMargin, absoluteMargin.row == currentRow || absoluteMargin.row == row {
                setBottomMargin(margin: margin)
            }
        }
    }
}

class Margin {
    var constant: CGFloat
    
    init(contant: CGFloat) {
        self.constant = contant
    }
}
class RelativeMargin: Margin {
    var relatedViewType: UIView.Type
    public init(constant: CGFloat, relatedViewType: UIView.Type) {
        self.relatedViewType = relatedViewType
        super.init(contant: constant)
    }
}
class AbsoluteMargin: Margin {
    var row: Int
    init(constant: CGFloat, row: Int) {
        self.row = row
        super.init(contant: constant)
    }
}
