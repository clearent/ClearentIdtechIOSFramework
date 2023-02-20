//
//  ClearentWrapperTests.swift
//  ClearentIdtechIOSFramework-Tests
//
//  Created by Carmen Jurcovan on 13.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import XCTest
@testable import ClearentIdtechIOSFramework

final class ClearentWrapperTests: XCTestCase {
    var sut: ClearentWrapper!
    
    override func setUp() {
        super.setUp()

        sut = ClearentWrapper.shared
    }

    override func tearDown() {
        sut = nil

        // Restore the ClearentWrapper instance to default values.
        // Without this, subsequent tests might fail because the tests below change global state.
        ClearentWrapper.shared = ClearentWrapper()
        
        ClearentWrapperDefaults.removeAllValues()
        super.tearDown()
    }
    
    func testSharedWrapper() {
        XCTAssertNotNil(sut, "Wrapper should not be nil")
    }
    
    func testPreviouslyPairedReaders() {
        // Given
        let readerInfo = ReaderInfo(readerName: "Test Reader Name", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: false, uuid: nil, serialNumber: nil, version: nil)
        let readerItem = ReaderItem(readerInfo: readerInfo, isConnecting: false)
        
        // When
        ClearentWrapperDefaults.recentlyPairedReaders = [readerInfo]
        
        // Then
        XCTAssertEqual(sut.previouslyPairedReaders.count, 1)
    }
}
