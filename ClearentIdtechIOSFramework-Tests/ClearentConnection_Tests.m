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

- (void) setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testInitWithBluetoothFirstConnect {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
   // XCTAssertTrue(CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_BLUETOOTH == clearentConnection.connectionType);
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
  //  XCTAssertTrue(CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_BLUETOOTH == clearentConnection.connectionType);
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
  //  XCTAssertTrue(CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_BLUETOOTH == clearentConnection.connectionType);
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
  //  XCTAssertTrue(CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_BLUETOOTH == clearentConnection.connectionType);
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
  //  XCTAssertTrue(CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_BLUETOOTH == clearentConnection.connectionType);
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
  //  XCTAssertTrue(CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_BLUETOOTH == clearentConnection.connectionType);
    XCTAssertFalse(clearentConnection.connectToFirstBluetoothFound);
    XCTAssertFalse(clearentConnection.searchBluetooth);
    XCTAssertTrue(10 == clearentConnection.bluetoothMaximumScanInSeconds);
    XCTAssertNil(clearentConnection.fullFriendlyName);
    XCTAssertEqualObjects(@"deviceUUID", clearentConnection.bluetoothDeviceId);
    
    NSString *logMessage = [clearentConnection createLogMessage];
    XCTAssertEqualObjects(@" Connection properties lastFiveDigitsOfDeviceSerialNumber:none bluetoothMaximumScanInSeconds:10 connectionType:bluetooth connectToFirstBluetoothFound:FALSE readerInterfaceMode:unknown fullFriendlyName:none searchBluetooth:FALSE bluetoothDeviceId:deviceUUID", logMessage);
}


- (void) testInitWithAudiojack {
    ClearentConnection *clearentConnection = [[ClearentConnection alloc] initAudioJack];
   // XCTAssertTrue(0 == clearentConnection.bluetoothAdvertisingInterval);
    XCTAssertTrue(CLEARENT_READER_INTERFACE_3_IN_1 == clearentConnection.readerInterfaceMode);
    XCTAssertTrue(CLEARENT_AUDIO_JACK == clearentConnection.connectionType);
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

- (void) testNewConnectionRequestWhenLast5isDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithLast5:@"12345"];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithLast5:@"55555"];
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
    connectionRequest.lastFiveDigitsOfDeviceSerialNumber = @"12345";
    XCTAssertFalse([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenFriendlyNameisDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"friendlyname1"];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"friendlyname2"];
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
    connectionRequest.fullFriendlyName = @"friendlyname1";
    XCTAssertFalse([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenDeviceUUIDisDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID1"];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID2"];
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
    connectionRequest.bluetoothDeviceId = @"deviceUUID1";
    XCTAssertFalse([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenConnectionTypeIsDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothFirstConnect];
    connectionRequest.connectionType = CLEARENT_AUDIO_JACK;
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenBluetoothMaximumScanTimeIsDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothFirstConnect];
    connectionRequest.bluetoothMaximumScanInSeconds = 50;
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenReaderInterfaceModeIsDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothFirstConnect];
    connectionRequest.readerInterfaceMode = CLEARENT_READER_INTERFACE_2_IN_1;
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenBluetoothSearchIsEnabled {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothFirstConnect];
    connectionRequest.searchBluetooth = true;
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}


- (void) testNewConnectionRequestWhenBluetoothFirstConnectIsDifferent {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothFirstConnect];
    connectionRequest.connectToFirstBluetoothFound = false;
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

- (void) testNewConnectionRequestWhenBluetoothSearchChangedToFindByDeviceUUID {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothSearch];
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    XCTAssertTrue([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]);
    
}

@end
