//
//  ClearentConnection.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 4/15/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClearentIdtechIOSFramework/ClearentConnection.h>

@interface ClearentConnection_Tests: XCTestCase

@end

@implementation ClearentConnection_Tests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testInitWithBluetoothFirstConnect {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    XCTAssertTrue(BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(BLUETOOTH == clearentConnection.connectionType);
    XCTAssertTrue(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertFalse(clearentConnection.searchBluetooth);
    XCTAssertTrue(10 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.bluetoothDeviceId);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertNil(clearentConnection.lastFiveDigitsOfDeviceSerialNumber);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:10 connectionType:bluetooth connectToFirstBluetoothFound:TRUE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:FALSE bluetoothDeviceId:none", logMessage);
    
}


- (void) testInitWithBluetoothSearch {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothSearch];
    XCTAssertTrue(BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(BLUETOOTH == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertTrue(clearentConnection.searchBluetooth);
    XCTAssertTrue(10 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.bluetoothDeviceId);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertNil(clearentConnection.lastFiveDigitsOfDeviceSerialNumber);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:10 connectionType:bluetooth connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:TRUE bluetoothDeviceId:none", logMessage);
}

- (void) testInitWithBluetoothSearchWithMaxScanTime {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothSearchWithMaxScanTime:15];
    XCTAssertTrue(BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(BLUETOOTH == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertTrue(clearentConnection.searchBluetooth);
    XCTAssertTrue(15 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.bluetoothDeviceId);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertNil(clearentConnection.lastFiveDigitsOfDeviceSerialNumber);
    
    NSString *logMessage = [clearentConnection createLogMessage];
      XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:15 connectionType:bluetooth connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:TRUE bluetoothDeviceId:none", logMessage);
}

- (void) testInitBluetoothWithLast5 {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothWithLast5:@"12345"];
    XCTAssertTrue(BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(BLUETOOTH == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertFalse(clearentConnection.searchBluetooth);
    XCTAssertTrue(10 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.bluetoothDeviceId);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertEqualObjects(@"12345", clearentConnection.lastFiveDigitsOfDeviceSerialNumber);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:12345 bluetoothMaximumScanInSeconds:10 connectionType:bluetooth connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:FALSE bluetoothDeviceId:none", logMessage);
}

- (void) testInitBluetoothWithFriendlyName {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"friendlyname"];
    XCTAssertTrue(BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(BLUETOOTH == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertFalse(clearentConnection.searchBluetooth);
    XCTAssertTrue(10 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.bluetoothDeviceId);
    XCTAssertEqualObjects(@"friendlyname", clearentConnection.fullFriendlyName);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:10 connectionType:bluetooth connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:friendlyname searchBluetooth:FALSE bluetoothDeviceId:none", logMessage);
}

- (void) testInitBluetoothWithDeviceUUID {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    XCTAssertTrue(BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(BLUETOOTH == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertFalse(clearentConnection.searchBluetooth);
    XCTAssertTrue(10 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertEqualObjects(@"deviceUUID", clearentConnection.bluetoothDeviceId);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:10 connectionType:bluetooth connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:FALSE bluetoothDeviceId:provided", logMessage);
}




- (void) testInitWithAudiojack {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initAudioJack];
    XCTAssertTrue(0 == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(AUDIO_JACK == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertFalse(clearentConnection.searchBluetooth);
    XCTAssertTrue(0 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.bluetoothDeviceId);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertNil(clearentConnection.lastFiveDigitsOfDeviceSerialNumber);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:0 connectionType:audio jack connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:FALSE bluetoothDeviceId:none", logMessage);
    
}

- (void) testIsDeviceKnownWithLast5 {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothWithLast5:@"12345"];
    XCTAssertTrue(clearentConnection.isDeviceKnown);
    
    clearentConnection.lastFiveDigitsOfDeviceSerialNumber = @"";
    XCTAssertFalse(clearentConnection.isDeviceKnown);
    
    clearentConnection.lastFiveDigitsOfDeviceSerialNumber = @"";
    XCTAssertFalse(clearentConnection.isDeviceKnown);
    
}

- (void) testIsDeviceKnownWithFriendlyName {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"friendlyname"];
    XCTAssertTrue(clearentConnection.isDeviceKnown);
    
    clearentConnection.fullFriendlyName = @"";
    XCTAssertFalse(clearentConnection.isDeviceKnown);
    
    clearentConnection.fullFriendlyName = @"";
    XCTAssertFalse(clearentConnection.isDeviceKnown);
    
}

- (void) testIsDeviceKnownWithDeviceUUID {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    XCTAssertTrue(clearentConnection.isDeviceKnown);
    
    clearentConnection.bluetoothDeviceId = @"";
    XCTAssertFalse(clearentConnection.isDeviceKnown);
    
    clearentConnection.bluetoothDeviceId = @"";
    XCTAssertFalse(clearentConnection.isDeviceKnown);
    
}

- (void) testIsDeviceKnownWhenNoneProvided {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    XCTAssertFalse(clearentConnection.isDeviceKnown);
}

- (void) testCreateIDTechFormattedFriendlyname {
    XCTAssertEqualObjects(@"IDTECH-VP3300-12345", [ClearentConnection createFullIdTechFriendlyName:@"12345"]);
}

@end
