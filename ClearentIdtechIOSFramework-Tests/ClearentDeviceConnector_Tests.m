//
//  ClearentDeviceConnector_Tests.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 4/15/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <ClearentIdtechIOSFramework/ClearentDeviceConnector.h>
#import <ClearentIdtechIOSFramework/ClearentDelegate.h>
#import <ClearentIdtechIOSFramework/ClearentPublicVP3300Delegate.h>
#import <ClearentIdtechIOSFramework/Clearent_VP3300.h>
#import <ClearentIdtechIOSFramework/ClearentVP3300Configuration.h>
#import <ClearentIdtechIOSFramework/ClearentVP3300Config.h>
#import <ClearentIdtechIOSFramework/ClearentCache.h>
#import "TestPublicDelegate.h"

@interface ClearentDeviceConnector_Tests : XCTestCase

@property(nonatomic, strong) id mockClearentVP3300;
@property(nonatomic, strong) id mockIDTechSharedInstance;
@property(nonatomic, strong) TestPublicDelegate *testPublicDelegate;

@property(nonatomic, strong) ClearentDeviceConnector *clearentDeviceConnector;
@property(nonatomic, strong) ClearentDelegate *clearentDelegate;
@property(nonatomic, strong) ClearentVP3300Config *clearentVP3300Config;

@end

@implementation ClearentDeviceConnector_Tests

@synthesize mockClearentVP3300 = _mockClearentVP3300;
@synthesize mockIDTechSharedInstance = _mockIDTechSharedInstance;

SEL mockRunTransactionSelector;

- (void) setUp {
    
    _mockClearentVP3300 = OCMClassMock([Clearent_VP3300 class]);
    _mockIDTechSharedInstance = OCMClassMock([IDT_VP3300 class]);
    
    SEL runTransactionSelector = NSSelectorFromString(@"mockRunTransaction");
    if ([self respondsToSelector:runTransactionSelector]) {
        mockRunTransactionSelector = runTransactionSelector;
    }
    
    _testPublicDelegate = [[TestPublicDelegate alloc]  init];
    _clearentVP3300Config = [[ClearentVP3300Config alloc] init];
    _clearentVP3300Config.clearentBaseUrl = @"baseUrl";
    _clearentVP3300Config.publicKey = @"publicKey";
    
    _clearentDelegate = [[ClearentDelegate alloc] initWithPaymentCallback:_testPublicDelegate clearentVP3300Configuration:_clearentVP3300Config callbackObject:self withSelector:runTransactionSelector idTechSharedInstance:_mockIDTechSharedInstance];
    
    _clearentDeviceConnector = [[ClearentDeviceConnector alloc] init:_clearentDelegate clearentVP3300:_mockClearentVP3300];
}

- (void) tearDown {
    
    [self.mockClearentVP3300 stopMocking];
    [self.mockIDTechSharedInstance stopMocking];
    
}

- (void) testStartConnectionWithFirstConnect {
    
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(true);
    OCMStub([self.mockClearentVP3300 device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMStub([self.mockClearentVP3300 device_getBLEFriendlyName]).andReturn(@"friendlyName");

    [_clearentDeviceConnector startConnection:clearentConnection];
    
    XCTAssertNotNil(_testPublicDelegate.clearentFeedback);
    XCTAssertTrue(_testPublicDelegate.clearentFeedback.feedBackMessageType == CLEARENT_FEEDBACK_BLUETOOTH);
    XCTAssertEqualObjects(@"CONNECTED : friendlyName", _testPublicDelegate.clearentFeedback.message);
    
}

- (void) testStartConnectionWithAudioJackButNotConnected {
    
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initAudioJack];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(false);
    OCMStub([self.mockClearentVP3300 device_isAudioReaderConnected]).andReturn(false);
    OCMStub([self.mockClearentVP3300 device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);

    [_clearentDeviceConnector startConnection:clearentConnection];
    
    XCTAssertNotNil(_testPublicDelegate.clearentFeedback);
    XCTAssertTrue(_testPublicDelegate.clearentFeedback.feedBackMessageType == CLEARENT_FEEDBACK_INFO);
    XCTAssertEqualObjects(@"AUDIO JACK DISCONNECTED", _testPublicDelegate.clearentFeedback.message);
    
}

- (void) testStartConnectionWithNil {

    [_clearentDeviceConnector startConnection:nil];
    XCTAssertEqualObjects(@"CONNECTION PROPERTIES REQUIRED", _testPublicDelegate.message);
}

- (void) testStartAudioJackConnectionNotConnected {
    
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initAudioJack];
    
    [_clearentDeviceConnector startConnection:clearentConnection];
    
    XCTAssertEqualObjects(@"AUDIO JACK DISCONNECTED", _testPublicDelegate.message);
   
}

- (void) testClearSavedDeviceUUIDWhenDeviceUUIDProvided {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"deviceUUID" bluetoothFriendlyName:@"friendlyname"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"newDeviceUUID"];
    
    [_clearentDeviceConnector clearSavedDeviceId:connectionRequest];

    XCTAssertNil([ClearentCache getLastUsedBluetoothDeviceId]);
    XCTAssertNil([ClearentCache getLastUsedBluetoothFriendlyName]);
    
}


- (void) testClearSavedDeviceUUIDAndDisconnectBluetoothIfConnected {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"deviceUUID" bluetoothFriendlyName:@"friendlyname"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithLast5:@"last5"];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(true);
    OCMExpect([self.mockClearentVP3300 device_disconnectBLE]);
    
    [_clearentDeviceConnector clearSavedDeviceId:connectionRequest];

    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNil([ClearentCache getLastUsedBluetoothDeviceId]);
    XCTAssertNil([ClearentCache getLastUsedBluetoothFriendlyName]);
    
}

- (void) testClearSavedDeviceUUIDWhenBLuetoothLast5Provided {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"deviceUUID" bluetoothFriendlyName:@"friendlyname"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithLast5:@"last5"];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(true);
    OCMExpect([self.mockClearentVP3300 device_disconnectBLE]);
    
    [_clearentDeviceConnector clearSavedDeviceId:connectionRequest];

    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNil([ClearentCache getLastUsedBluetoothDeviceId]);
    XCTAssertNil([ClearentCache getLastUsedBluetoothFriendlyName]);
    
}

- (void) testClearSavedDeviceUUIDWhenBluetoothFriendlyNameProvided {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"deviceUUID" bluetoothFriendlyName:@"friendlyname"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"newfriendlyname"];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(true);
    OCMExpect([self.mockClearentVP3300 device_disconnectBLE]);
    
    [_clearentDeviceConnector clearSavedDeviceId:connectionRequest];

    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNil([ClearentCache getLastUsedBluetoothDeviceId]);
    XCTAssertNil([ClearentCache getLastUsedBluetoothFriendlyName]);
    
}

- (void) testClearSavedDeviceUUIDWhenBluetoothSearchProvided {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"deviceUUID" bluetoothFriendlyName:@"friendlyname"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"deviceUUID"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    ClearentConnection *connectionRequest = [[ClearentConnection alloc] initBluetoothSearch];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(true);
    OCMExpect([self.mockClearentVP3300 device_disconnectBLE]);
    
    [_clearentDeviceConnector clearSavedDeviceId:connectionRequest];
    
    OCMVerifyAll(self.mockClearentVP3300);

    XCTAssertNil([ClearentCache getLastUsedBluetoothDeviceId]);
    XCTAssertNil([ClearentCache getLastUsedBluetoothFriendlyName]);
    
}

- (void) testWhenHandlingBluetoothDeviceFoundMessageForStoredDeviceUUID {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"110476C5-A829-369E-FBCA-0DFB02645FFA" bluetoothFriendlyName:@"IDTECH-VP3300-03826"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"110476C5-A829-369E-FBCA-0DFB02645FFA"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
    
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);

}


- (void) testWhenHandlingBluetoothDeviceFoundMessageForLast5Provided_But_Ignored_Use_Stored_Device {
    
    [ClearentCache cacheLastUsedBluetoothDevice:@"110476C5-A829-369E-FBCA-0DFB02645FFA" bluetoothFriendlyName:@"IDTECH-VP3300-03826"];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithLast5:@"03826"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
    
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);

}


- (void) testWhenHandlingBluetoothDeviceFoundMessageWithFriendlyNameProvided_No_Stored_Device {
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"IDTECH-VP3300-03826"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
    
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);

}

- (void) testWhenHandlingBluetoothDeviceFoundMessageWithDeviceUUID_No_Stored_Device {
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"110476C5-A829-369E-FBCA-0DFB02645FFA"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
    
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);

}

- (void) testSkipHandlingBluetoothDeviceFoundMessageWhenAlreadyFound {
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
       
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithDeviceUUID:@"110476C5-A829-369E-FBCA-0DFB02645FFA"];
    _clearentDelegate.clearentConnection = currentConnection;

    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
    
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
     OCMVerifyAll(self.mockClearentVP3300);
    
    _clearentDeviceConnector.foundDeviceWaitingToConnect = true;
    
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);

}

- (void) testWhenHandlingBluetoothDeviceFoundMessageFirstFound_No_Stored_Device {
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = currentConnection;
    
    
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
   
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];

    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);

}

- (void) testRecordBLuetoothDeviceFound {
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = currentConnection;
    
    
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:[OCMArg any]]);
   
    [_clearentDeviceConnector handleBluetoothDeviceFound:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];

    OCMVerifyAll(self.mockClearentVP3300);
    
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    
    
    NSUUID *testNSUUID =  [ [NSUUID  alloc] initWithUUIDString:@"110476C5-A829-369E-FBCA-0DFB02645FFA"];
    
    OCMStub([self.mockIDTechSharedInstance device_connectedBLEDevice]).andReturn(testNSUUID);
   
    [_clearentDeviceConnector recordBluetoothDeviceAsConnected];
    
    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
       
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);
    XCTAssertTrue(bluetoothDevice.connected);
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", [ClearentCache getLastUsedBluetoothDeviceId]);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", [ClearentCache getLastUsedBluetoothFriendlyName]);
}


- (void) testStartBluetoothSearchWithUUID {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"IDTECH-VP3300-03826"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMExpect([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]);
    OCMExpect([self.mockClearentVP3300 device_setBLEFriendlyName:nil]);
   
    [_clearentDeviceConnector startBluetoothSearchWithUUID:@"110476C5-A829-369E-FBCA-0DFB02645FFA"];
    
    OCMVerifyAll(self.mockClearentVP3300);
    
}

- (void) testStartBluetoothSearchWithFullFriendlyName {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"IDTECH-VP3300-03826"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMExpect([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]);
    OCMExpect([self.mockIDTechSharedInstance device_setBLEFriendlyName:[OCMArg any]]);
    
    [_clearentDeviceConnector startBluetoothSearchWithFullFriendlyName:@"IDTECH-VP3300-03826"];
    
    OCMVerifyAll(self.mockClearentVP3300);
}

- (void) testStartBlindBluetoothSearch {
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothWithFriendlyName:@"IDTECH-VP3300-03826"];
    _clearentDelegate.clearentConnection = currentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMExpect([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]);
    OCMExpect([self.mockIDTechSharedInstance device_setBLEFriendlyName:nil]);
    
    [_clearentDeviceConnector startBlindBluetoothSearch];
    
    OCMVerifyAll(self.mockClearentVP3300);
}

- (void) testRecordBluetoothFound {
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    
    ClearentConnection *currentConnection = [[ClearentConnection alloc] initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = currentConnection;
   
    [_clearentDeviceConnector recordFoundBluetoothDevice:@"IDTECH-VP3300-03826" deviceId:@"110476C5-A829-369E-FBCA-0DFB02645FFA"];

    XCTAssertNotNil(_clearentDeviceConnector.bluetoothDevices.firstObject);
    id<ClearentBluetoothDevice> bluetoothDevice = _clearentDeviceConnector.bluetoothDevices.firstObject;
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", bluetoothDevice.deviceId);
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", bluetoothDevice.friendlyName);
    XCTAssertFalse(bluetoothDevice.connected);

}


- (void) testExtractDeviceIdFromIdTechBLEDeviceFoundMessage {
    
    NSString *deviceId = [_clearentDeviceConnector extractDeviceIdFromIdTechBLEDeviceFoundMessage:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    XCTAssertEqualObjects(@"110476C5-A829-369E-FBCA-0DFB02645FFA", deviceId);

}

- (void) testExtractFriendlyNameFromIdTechBLEDeviceFoundMessage {
    
    NSString *friendlyName = [_clearentDeviceConnector extractFriendlyNameFromIdTechBLEDeviceFoundMessage:@"BLE DEVICE FOUND: IDTECH-VP3300-03826 (110476C5-A829-369E-FBCA-0DFB02645FFA)"];
    
    XCTAssertEqualObjects(@"IDTECH-VP3300-03826", friendlyName);

}

- (void) mockRunTransaction {
    NSLog(@"mockRunTransaction");
}

@end
