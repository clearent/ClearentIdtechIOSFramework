//
//  DateExtensionTests.swift
//  ClearentIdtechIOSFramework-Tests
//
//  Created by Carmen Jurcovan on 13.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import XCTest
@testable import ClearentIdtechIOSFramework

final class DateExtensionTests: XCTestCase {
    
    var testDate: Date!
    
    override func setUp() {
        super.setUp()
        
        let dateComponents = DateComponents(timeZone: TimeZone(secondsFromGMT: 0)!, year: 1980, month: 06, day: 03, hour: 10, minute: 15, second: 08)
        guard let dateToTest = Calendar.current.date(from: dateComponents) else {
            XCTFail("Can't create test date")
            return
        }
        self.testDate = dateToTest
    }

    override func tearDown() {
        testDate = nil
        super.tearDown()
    }

    func testDateOnlyToString() {
        XCTAssertEqual(testDate.dateOnlyToString(), "1980-06-03")
    }
    
    func testTimeToString() {
        XCTAssertEqual(testDate.timeToString(), "10:15:08")
    }
    
    func testDateAndTimeToString() {
        XCTAssertEqual(testDate.dateAndTimeToString(), "1980-06-03 10:15")
    }
}
