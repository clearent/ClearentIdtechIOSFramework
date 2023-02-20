//
//  ClearentPairingReaderItemTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 08.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ClearentPairingReaderItemTests: XCTestCase {
    var sut: ClearentPairingReaderItem!
    
    override func setUp() {
        super.setUp()
        sut = ClearentPairingReaderItem(frame: .zero)
        sut.awakeFromNib()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testOutlets() {
        XCTAssertNotNil(sut.label)
        XCTAssertNotNil(sut.container)
        XCTAssertNotNil(sut.rightIcon)
    }
    
    func testMargins() {
        XCTAssertEqual(sut.margins.count, 1)
        sut.testBottomMargin(for: ClearentPairingReaderItem.self, margin: 8)
    }
    
    func testConfigure() {
        XCTAssertEqual(sut.container.layer.cornerRadius, sut.container.bounds.height / 4)
        XCTAssertTrue(sut.container.layer.masksToBounds)
        XCTAssertEqual(sut.textColor, ClearentConstants.Color.base01)
        XCTAssertEqual(sut.textFont, ClearentUIBrandConfigurator.shared.fonts.listItemTextFont)
        XCTAssertEqual(sut.containerBackgroundColor, ClearentConstants.Color.backgroundSecondary03)
        XCTAssertEqual(sut.rightIconName, ClearentConstants.IconName.rightArrow)
    }
    
    func testAction() {
        var actionExecuted = false
        sut.action = {
            actionExecuted = true
        }
        sut.viewWasPressed()
        XCTAssertTrue(actionExecuted, "Action should be executed")
    }
}
