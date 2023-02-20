//
//  ReaderDetailsViewControllerTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 09.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ClearentReaderDetailsViewControllerTests: XCTestCase {
    var sut: ClearentReaderDetailsViewController!
    var presenter: ClearentReaderDetailsPresenter!
    
    override func setUp() {
        super.setUp()
        let readerInfo = ReaderInfo(readerName: "Test Reader Name", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: false, uuid: nil, serialNumber: nil, version: nil)
        let readerItem = ReaderItem(readerInfo: readerInfo, isConnecting: false)
        ClearentWrapperDefaults.recentlyPairedReaders = [readerInfo]
        sut = ClearentReaderDetailsViewController(nibName: String(describing: ClearentReaderDetailsViewController.self), bundle: ClearentConstants.bundle)
        sut.detailsPresenter = ClearentReaderDetailsPresenter(currentReader: readerItem, flowDataProvider: FlowDataProvider(), navigationController: UINavigationController(), delegate: self)
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        presenter = nil
        sut = nil
        ClearentWrapperDefaults.removeAllValues()
        super.tearDown()
    }

    func testOutlets() {
        [sut.stackView,
         sut.stackView,
         sut.connectedView,
         sut.signalStatusView,
         sut.batteryStatusView,
         sut.autojoinView,
         sut.readerName,
         sut.customReaderName,
         sut.serialNumberView,
         sut.versionNumberView,
         sut.removeReaderButton].forEach {
            XCTAssertNotNil($0)
        }
    }
    
    func testSwitches() {
        // connected switch
        XCTAssertEqual(sut.connectedView.titleText, ClearentConstants.Localized.ReaderDetails.connected)
        XCTAssertEqual(sut.connectedView.descriptionText, "")
        XCTAssertEqual(sut.connectedView.isOn, sut.detailsPresenter.currentReader.isConnected)
        XCTAssertNotNil(sut.connectedView.valueChangedAction)
        
        // autojoin switch
        XCTAssertEqual(sut.autojoinView.titleText, ClearentConstants.Localized.ReaderDetails.autojoinTitle)
        XCTAssertEqual(sut.autojoinView.descriptionText, ClearentConstants.Localized.ReaderDetails.autojoinDescription)
        XCTAssertEqual(sut.autojoinView.isOn, sut.detailsPresenter.currentReader.autojoin)
        XCTAssertNotNil(sut.autojoinView.valueChangedAction)
    }
    
    func testTurnOnAutojoin() throws {
        // Given
        let readerInfo = ReaderInfo(readerName: "Test Reader Name2", customReaderName: nil, batterylevel: nil, signalLevel: nil, isConnected: false, autojoin: true, uuid: nil, serialNumber: nil, version: nil)
        ClearentWrapper.shared.addReaderToRecentlyUsed(reader: readerInfo)
        
        // When
        sut.autojoinView.isOn = true
        sut.autojoinView.switchValueDidChange(sut.autojoinView.switchView)
        
        // Then
        let currentReaderFromDefaults = try XCTUnwrap(ClearentWrapperDefaults.recentlyPairedReaders?.first(where: {$0 == sut.detailsPresenter.currentReader }))
        XCTAssertTrue(currentReaderFromDefaults.autojoin)
        let autojoinReaders = try XCTUnwrap(ClearentWrapperDefaults.recentlyPairedReaders?.filter({ $0.autojoin == true }))
        XCTAssertTrue(autojoinReaders.count == 1)
    }
    
    func testTurnOffAutojoin() throws {
        // Given
        sut.autojoinView.isOn = false
        
        // When
        sut.autojoinView.switchValueDidChange(sut.autojoinView.switchView)
        
        // Then
        let readerFromDefaults = try XCTUnwrap(ClearentWrapperDefaults.recentlyPairedReaders?.first(where: {$0 == sut.detailsPresenter.currentReader }))
        XCTAssertFalse(readerFromDefaults.autojoin)
    }

    func testSetupReaderStatus_signal_available() {
        // Given
        sut.detailsPresenter.currentReader.signalLevel = 0
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertEqual(sut.signalStatusView.iconName, sut.detailsPresenter.readerSignalStatus?.iconName)
        XCTAssertEqual(sut.signalStatusView.title, sut.detailsPresenter.readerSignalStatus?.title)
        XCTAssertFalse(sut.signalStatusView.isHidden)
    }
    
    func testSetupReaderStatus_no_signal() {
        // Given
        sut.detailsPresenter.currentReader.signalLevel = nil
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(sut.signalStatusView.isHidden)
    }
    
    func testSetupReaderStatus_battery_available() {
        // Given
        sut.detailsPresenter.currentReader.batterylevel = 70
        sut.detailsPresenter.currentReader.isConnected = true
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertEqual(sut.batteryStatusView.iconName, sut.detailsPresenter.readerBatteryStatus?.iconName)
        XCTAssertEqual(sut.batteryStatusView.title, sut.detailsPresenter.readerBatteryStatus?.title)
        XCTAssertFalse(sut.batteryStatusView.isHidden)
    }
    
    func testSetupReaderStatus_no_battery() {
        // Given
        sut.detailsPresenter.currentReader.batterylevel = nil
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(sut.batteryStatusView.isHidden)
    }
    
    func testReaderName() {
        XCTAssertEqual(sut.readerName.titleText, ClearentConstants.Localized.ReaderDetails.readerName)
        XCTAssertEqual(sut.readerName.descriptionText, "Test Reader Name")
        XCTAssertTrue(sut.readerName.button.isHidden)
    }

    func testSetupSerialNumber_serialno_available() {
        // Given
        let serialNumber = "s123"
        sut.detailsPresenter.currentReader.serialNumber = serialNumber
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertEqual(sut.serialNumberView.titleText, ClearentConstants.Localized.ReaderDetails.serialNumber)
        XCTAssertEqual(sut.serialNumberView.descriptionText, serialNumber)
        XCTAssertTrue(sut.serialNumberView.button.isHidden)
        XCTAssertFalse(sut.serialNumberView.isHidden)
    }
    
    func testSetupSerialNumber_no_serialno() {
        // Given
        sut.detailsPresenter.currentReader.serialNumber = nil
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(sut.serialNumberView.isHidden)
        
    }
    
    func testSetupVersion_version_available() {
        // Given
        let versionNumber = "v123"
        sut.detailsPresenter.currentReader.version = versionNumber
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertEqual(sut.versionNumberView.titleText, ClearentConstants.Localized.ReaderDetails.version)
        XCTAssertEqual(sut.versionNumberView.descriptionText, versionNumber)
        XCTAssertTrue(sut.versionNumberView.button.isHidden)
        XCTAssertFalse(sut.versionNumberView.isHidden)
    }
    
    func testSetupVersion_no_version() {
        // Given
        sut.detailsPresenter.currentReader.version = nil
        
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(sut.versionNumberView.isHidden)
    }
    
    func testSetupButton() {
        XCTAssertEqual(sut.removeReaderButton.title, ClearentConstants.Localized.ReaderDetails.removeReader)
        XCTAssertEqual(sut.removeReaderButton.borderedButtonTextColor, ClearentUIBrandConfigurator.shared.colorPalette.removeReaderButtonTextColor)
        XCTAssertEqual(sut.removeReaderButton.borderColor, ClearentUIBrandConfigurator.shared.colorPalette.removeReaderButtonBorderColor)
        XCTAssertEqual(sut.removeReaderButton.buttonStyle, .bordered)
        XCTAssertNotNil(sut.removeReaderButton.action)
    }
}

extension ClearentReaderDetailsViewControllerTests: ClearentReaderDetailsDismissProtocol {
    func shutDown(userAction: FlowButtonType) {}
}
