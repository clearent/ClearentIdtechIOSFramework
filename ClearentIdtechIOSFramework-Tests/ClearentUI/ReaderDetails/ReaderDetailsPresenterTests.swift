//
//  ReaderDetailsPresenterTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 12.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ReaderDetailsPresenterTests: XCTestCase {
    var sut: ClearentReaderDetailsPresenter!
    
    override func setUp() {
        super.setUp()
        let readerInfo = ReaderInfo(readerName: "Test reader name", customReaderName: "Custom reader name", batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: false, uuid: nil, serialNumber: nil, version: nil)
        let readerItem = ReaderItem(readerInfo: readerInfo, isConnecting: false)
        ClearentWrapperDefaults.recentlyPairedReaders = [readerInfo]
        sut = ClearentReaderDetailsPresenter(currentReader: readerItem, flowDataProvider: FlowDataProvider(), navigationController: UINavigationController(), delegate: self)
    }
    
    override func tearDown() {
        sut = nil
        ClearentWrapperDefaults.removeAllValues()
        super.tearDown()
    }
    
    func testInit() {
        XCTAssertEqual(sut.currentReader.readerName, "Test reader name")
        XCTAssertEqual(sut.currentReader.customReaderName, "Custom reader name")
        XCTAssertNil(sut.currentReader.batterylevel)
        XCTAssertNil(sut.currentReader.signalLevel)
        XCTAssertFalse(sut.currentReader.isConnected)
        XCTAssertFalse(sut.currentReader.autojoin)
        XCTAssertNil(sut.currentReader.uuid)
        XCTAssertNil(sut.currentReader.serialNumber)
        XCTAssertNil(sut.currentReader.version)
        XCTAssertTrue(ClearentWrapperDefaults.recentlyPairedReaders?.count ?? 0 > 0)
    }
    
    func testReaderSignalStatus() {
        // Given
        let signalLevels = [0, 1, 2, nil]
        let localizedReaderDetails = ClearentConstants.Localized.ReaderDetails.self
        
        signalLevels.forEach {
            // When
            sut.currentReader.signalLevel = $0
            
            // Then
            switch $0 {
            case 0:
                XCTAssertEqual(sut.readerSignalStatus?.title, String(format: localizedReaderDetails.signalStatus, localizedReaderDetails.signalGood))
            case 1:
                XCTAssertEqual(sut.readerSignalStatus?.title, String(format:localizedReaderDetails.signalStatus, localizedReaderDetails.signalMedium))
            case 2:
                XCTAssertEqual(sut.readerSignalStatus?.title, String(format: localizedReaderDetails.signalStatus, localizedReaderDetails.signalWeak))
            default:
                XCTAssertNil(sut.readerSignalStatus)
            }
        }
    }
    
    func testReaderBatteryStatus() {
        // Given
        let batteryLevels = [100, nil]
        sut.currentReader.isConnected = true
        
        batteryLevels.forEach {
            // When
            sut.currentReader.batterylevel = $0
            
            // Then
            switch $0 {
            case 100:
                guard let batteryStatus = sut.currentReader.batteryStatus() else {
                    XCTFail("Battery status should not be nil")
                    return
                }
                XCTAssertEqual(sut.readerBatteryStatus?.title, String(format: ClearentConstants.Localized.ReaderDetails.batteryStatus, batteryStatus.title))
                XCTAssertEqual(sut.readerBatteryStatus?.iconName, batteryStatus.iconName)
            default:
                XCTAssertNil(sut.readerBatteryStatus)
            }
        }
    }

    func testDeleteReaderName() {
        // When
        sut.deleteReaderName()
        
        // Then
        XCTAssertNil(sut.currentReader.customReaderName)
    }
}

extension ReaderDetailsPresenterTests: ClearentReaderDetailsDismissProtocol {
    func shutDown(userAction: FlowButtonType) {}
}
