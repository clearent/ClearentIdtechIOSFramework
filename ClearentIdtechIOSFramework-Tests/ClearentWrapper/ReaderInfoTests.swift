//
//  ReaderInfoTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 03.10.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ReaderInfoTests: XCTestCase {

    var sut: ReaderInfo!
    
    override func setUp() {
        super.setUp()
        sut = ReaderInfo(readerName: "Test reader name", customReaderName: "Custom reader name", batterylevel: 10, signalLevel: 1, isConnected: false, autojoin: false, uuid: nil, serialNumber: nil, version: nil)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInit() {
        XCTAssertFalse(sut.isConnected)
        XCTAssertFalse(sut.autojoin)
        XCTAssertEqual(sut.readerName, "Test reader name")
        XCTAssertEqual(sut.customReaderName, "Custom reader name")
        XCTAssertNil(sut.uuid)
        XCTAssertNil(sut.serialNumber)
        XCTAssertNil(sut.version)
    }

    func testIsConnected_true() {
        // When
        sut.isConnected = true
        
        // Then
        XCTAssertEqual(sut.batterylevel, 10)
        XCTAssertEqual(sut.signalLevel, 1)
    }
    
    func testIsConnected_false() {
        // When
        sut.isConnected = false
        
        // Then
        XCTAssertNil(sut.batterylevel)
        XCTAssertNil(sut.signalLevel)
    }
    
    func testBatteryStatus_available() {
        // Given
        sut.isConnected = true
        let batteryLevels = [0, 6, 26, 51, 76, 96]

        batteryLevels.forEach {
            // When
            sut.batterylevel = $0
            
            // Then
            guard let batteryStatus = sut.batteryStatus() else {
                XCTFail("Battery status should not be nil")
                return
            }

            XCTAssertEqual(batteryStatus.title, "\(String(describing: $0))%")
            
            switch $0 {
            case 0:
                XCTAssertEqual(batteryStatus.iconName, ClearentConstants.IconName.batteryLow)
            case 6:
                XCTAssertEqual(batteryStatus.iconName, ClearentConstants.IconName.batteryMediumLow)
            case 26:
                XCTAssertEqual(batteryStatus.iconName, ClearentConstants.IconName.batteryMedium)
            case 51:
                XCTAssertEqual(batteryStatus.iconName, ClearentConstants.IconName.batteryMediumHigh)
            case 76:
                XCTAssertEqual(batteryStatus.iconName, ClearentConstants.IconName.batteryHigh)
            case 96:
                XCTAssertEqual(batteryStatus.iconName, ClearentConstants.IconName.batteryFull)
            default:
                XCTAssertNil(batteryStatus.iconName)
            }
        }
    }
    
    func testBatteryStatus_unavailable_notConnected() {
        // When
        sut.isConnected = false
        sut.batterylevel = 26
        
        // Then
        XCTAssertNil(sut.batteryStatus())
    }
    
    func testBatteryStatus_unavailable_noBattery() {
        // When
        sut.isConnected = true
        sut.batterylevel = nil
        
        // Then
        XCTAssertNil(sut.batteryStatus())
    }
    
    func testBatteryStatus_unavailable_searchDevicesFlow() {
        // When
        sut.isConnected = true
        sut.batterylevel = 26
        
        // Then
        XCTAssertNil(sut.batteryStatus(flowFeedbackType: .searchDevices))
    }
    
    func testSignalStatus_available() {
        // Given
        sut.isConnected = true
        let signalLevels = [0, 1, 2, 3]
        
        signalLevels.forEach {
            // When
            sut.signalLevel = $0
            let signalStatus = sut.signalStatus()
            
            // Then
            XCTAssertEqual(signalStatus.title, ClearentConstants.Localized.ReaderInfo.connected)
            
            switch $0 {
            case 0:
                XCTAssertEqual(signalStatus.iconName, ClearentConstants.IconName.goodSignal)
            case 1:
                XCTAssertEqual(signalStatus.iconName, ClearentConstants.IconName.mediumSignal)
            case 2:
                XCTAssertEqual(signalStatus.iconName, ClearentConstants.IconName.weakSignal)
            case 3:
                XCTAssertEqual(signalStatus.iconName, ClearentConstants.IconName.signalIdle)
                
                let signalStatusSearchDevices = sut.signalStatus(flowFeedbackType: .searchDevices)
                XCTAssertNil(signalStatusSearchDevices.iconName)
            default:
                XCTAssertNil(signalStatus.iconName)
            }
        }
    }
    
    func testSignalStatus_notConnected_searchDevicesFlow() {
        // Given
        sut.isConnected = false
        
        // When
        let signalStatus = sut.signalStatus(flowFeedbackType: .searchDevices)
        
        // Then
        XCTAssertNil(signalStatus.iconName)
        XCTAssertEqual(signalStatus.title, ClearentConstants.Localized.Pairing.connecting)
    }
    
    func testSignalStatus_notConnected_showReadersFlow() {
        // Given
        sut.isConnected = false

        // Case 1 - connecting
        // When
        let signalStatus = sut.signalStatus(flowFeedbackType: .showReaders, isConnecting: true)
        
        // Then
        XCTAssertNil(signalStatus.iconName)
        XCTAssertEqual(signalStatus.title, ClearentConstants.Localized.Pairing.connecting)
        
        // Case 2 - not connecting
        // When
        let signalStatus2 = sut.signalStatus(flowFeedbackType: .showReaders, isConnecting: false)
        
        // Then
        XCTAssertEqual(signalStatus2.iconName, ClearentConstants.IconName.signalIdle)
        XCTAssertEqual(signalStatus2.title, ClearentConstants.Localized.ReaderInfo.idle)
    }
    
    func testEqualityOperator_equal() {
        // When
        let reader1 = ReaderInfo(readerName: "Test Reader Name", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: true, uuid: UUID(uuidString: "eb3202e8-43dd-11ed-b878-0242ac120002"), serialNumber: nil, version: nil)
        let reader2 = ReaderInfo(readerName: "Test Reader Name", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: true, uuid: UUID(uuidString: "eb3202e8-43dd-11ed-b878-0242ac120002"), serialNumber: nil, version: nil)
        
        // Then
        XCTAssertTrue(reader1 == reader2)
    }
    
    func testEqualityOperator_notEqual() {
        // When
        let reader1 = ReaderInfo(readerName: "Test Reader Name", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: true, uuid: UUID(uuidString: "aa3202e8-43dd-11ed-b878-0242ac121112"), serialNumber: nil, version: nil)
        let reader2 = ReaderInfo(readerName: "Test Reader Name", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: true, uuid: UUID(uuidString: "eb3202e8-43dd-11ed-b878-0242ac120002"), serialNumber: nil, version: nil)
        
        // Then
        XCTAssertFalse(reader1 == reader2)
    }
}
