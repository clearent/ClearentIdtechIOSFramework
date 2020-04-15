//
//  ClearentBluetoothDevice.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 4/15/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClearentIdtechIOSFramework/ClearentBluetoothDevice.h>

@interface ClearentBluetoothDevice_Tests : XCTestCase

@end

@implementation ClearentBluetoothDevice_Tests

- (void) testPopulate {
    
    ClearentBluetoothDevice *clearentBluetoothDevice = [[ClearentBluetoothDevice alloc] init:@"friendlyname" deviceId:@"deviceUUID"];

    clearentBluetoothDevice.connected = false;
    
    XCTAssertEqualObjects(@"friendlyname", clearentBluetoothDevice.friendlyName);
    XCTAssertEqualObjects(@"deviceUUID", clearentBluetoothDevice.deviceId);
    XCTAssertFalse(clearentBluetoothDevice.connected);

}


@end
