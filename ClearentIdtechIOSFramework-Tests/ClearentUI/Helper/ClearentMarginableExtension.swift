//
//  ClearentMarginableExtension.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 12.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

extension ClearentMarginable {
    func testBottomMargin<T>(for type: T.Type, margin: CGFloat) {
        // Given
        guard let bottomMargin = self.margins.first(where: { ($0 as? RelativeBottomMargin)?.relatedViewType == type }) else {
            XCTFail("Missing bottom margin to \(type)")
            return
        }
        
        // Then
        XCTAssertEqual(bottomMargin.constant, margin)
    }
}
