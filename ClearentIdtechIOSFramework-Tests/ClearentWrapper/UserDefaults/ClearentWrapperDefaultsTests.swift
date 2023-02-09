//
//  ClearentWrapperDefaultsTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 03.10.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ClearentWrapperDefaultsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let readerInfo1 = ReaderInfo(readerName: "Reader name 1", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: false, uuid: UUID(), serialNumber: nil, version: nil)
        let readerInfo2 = ReaderInfo(readerName: "Reader name 2", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: true, uuid: UUID(), serialNumber: nil, version: nil)
        let readerInfo3 = ReaderInfo(readerName: "Reader name 3", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: false, uuid: UUID(), serialNumber: nil, version: nil)
        
        ClearentWrapperDefaults.recentlyPairedReaders = [readerInfo1, readerInfo2, readerInfo3]
        ClearentUIManager.shared.initialize(with: ClearentUIManagerConfiguration(baseURL: "test_url", publicKey: "test_public_key"))
        ClearentUIManager.shared.setupReaderInfo()
    }

    override func tearDown() {
        ClearentWrapperDefaults.removeAllValues()
        super.tearDown()
    }
    
    func testRecentlyPairedReaders() throws {
        let recentlyPairedReaders = try XCTUnwrap(ClearentWrapperDefaults.recentlyPairedReaders)
        XCTAssertEqual(recentlyPairedReaders.count, 3)
    }
    
    func testPairedReaderInfo() {
        XCTAssertEqual(ClearentWrapperDefaults.pairedReaderInfo?.readerName, "Reader name 2")
    }
    
    func testSkipOnboarding_true() {
        // When
        ClearentWrapperDefaults.skipOnboarding = true
        
        // Then
        XCTAssertTrue(ClearentWrapperDefaults.skipOnboarding)
    }
    
    func testSkipOnboarding_false() {
        // When
        ClearentWrapperDefaults.skipOnboarding = false
        
        // Then
        XCTAssertFalse(ClearentWrapperDefaults.skipOnboarding)
    }
}
