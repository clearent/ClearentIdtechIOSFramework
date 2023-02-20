//
//  StringExtensionSwift.swift
//  ClearentIdtechIOSFramework-Tests
//
//  Created by Carmen Jurcovan on 13.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import XCTest
@testable import ClearentIdtechIOSFramework

final class StringExtensionTests: XCTestCase {
    func testSetTwoDecimals() {
        // Given
        let amountsAndExpectations = ["0.5": "0.50",
                                      "1.0": "1.00",
                                      "1.00": "1.00",
                                      "2.1": "2.10",
                                      "2.01": "2.01",
                                      "2.123": "2.123",
                                      "3": "3"]
        
        // When
        amountsAndExpectations.keys.forEach {
            // Then
            XCTAssertEqual($0.setTwoDecimals(), amountsAndExpectations[$0])
        }
    }
    
    func testToDateUseShortFormat() {
        // Given
        let stringDate = "1980-11-21 10:30"
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        // When
        guard let date = stringDate.toDateUseShortFormat() else {
            XCTFail("String could not be converted to Date type")
            return
        }
        
        // then
        XCTAssertEqual(calendar.component(.year, from: date), 1980)
        XCTAssertEqual(calendar.component(.month, from: date), 11)
        XCTAssertEqual(calendar.component(.day, from: date), 21)
        XCTAssertEqual(calendar.component(.hour, from: date), 10)
        XCTAssertEqual(calendar.component(.minute, from: date), 30)
    }
}
