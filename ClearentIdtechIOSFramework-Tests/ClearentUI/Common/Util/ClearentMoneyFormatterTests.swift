//
//  ClearentMoneyFormatterTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 20.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ClearentMoneyFormatterTests: XCTestCase {
    
    func testFormattedWithSymbol_fromDouble() {
        let number = ClearentMoneyFormatter.formattedWithSymbol(from: 12.34)
        XCTAssertEqual(number, "$12.34")
    }
    
    func testFormattedWithSymbol_fromString() {
        let number = ClearentMoneyFormatter.formattedWithSymbol(from: "12.34")
        XCTAssertEqual(number, "$12.34")
    }
    
    func testFormattedWithoutSymbol() {
        let number = ClearentMoneyFormatter.formattedWithoutSymbol(from: 12.34)
        XCTAssertEqual(number, "12.34")
    }
}
