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
#import "TestPublicDelegate.h"

@interface ClearentDeviceConnector_Tests : XCTestCase

@property(nonatomic, strong) id mockClearentVP3300;
@property(nonatomic, strong) id mockIDTechSharedInstance;
@property(nonatomic, strong) TestPublicDelegate *testPublicDelegate;
@end

@implementation ClearentDeviceConnector_Tests

@synthesize mockClearentVP3300 = _mockClearentVP3300;
@synthesize mockIDTechSharedInstance = _mockIDTechSharedInstance;

SEL mockRunTransactionSelector;

ClearentDeviceConnector *clearentDeviceConnector;

ClearentDelegate *clearentDelegate;

ClearentVP3300Config *clearentVP3300Config;

- (void)setUp {
    
    _mockClearentVP3300 = OCMClassMock([Clearent_VP3300 class]);
    _mockIDTechSharedInstance = OCMClassMock([IDT_VP3300 class]);
    
    SEL runTransactionSelector = NSSelectorFromString(@"mockRunTransaction");
    if ([self respondsToSelector:runTransactionSelector]) {
        mockRunTransactionSelector = runTransactionSelector;
    }
    
    _testPublicDelegate = [[TestPublicDelegate alloc]  init];
    clearentVP3300Config = [[ClearentVP3300Config alloc] init];
    clearentVP3300Config.clearentBaseUrl = @"baseUrl";
    clearentVP3300Config.publicKey = @"publicKey";
    
    clearentDelegate = [[ClearentDelegate alloc] initWithPaymentCallback:_testPublicDelegate clearentVP3300Configuration:clearentVP3300Config callbackObject:self withSelector:runTransactionSelector idTechSharedInstance:_mockIDTechSharedInstance];
    
    clearentDeviceConnector = [[ClearentDeviceConnector alloc] init:clearentDelegate clearentVP3300:_mockClearentVP3300];
}

- (void)tearDown {
     [self.mockClearentVP3300 stopMocking];
}

- (void) testStartConnectionWithFirstConnect {
    
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    [clearentDeviceConnector startConnection:clearentConnection];
    
    OCMStub([self.mockClearentVP3300 device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMExpect([self.mockClearentVP3300 device_enableBLEDeviceSearch:[OCMArg any]]);
    
}

- (void) testStartConnectionWithNil {

    [clearentDeviceConnector startConnection:nil];
    XCTAssertEqualObjects(@"CONNECTION PROPERTIES REQUIRED", _testPublicDelegate.message);
}

- (void) testStartAudioJackConnectionNotConnected {
    
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initAudioJack];
    
    [clearentDeviceConnector startConnection:clearentConnection];
    
    XCTAssertEqualObjects(@"AUDIO JACK NOT CONNECTED", _testPublicDelegate.message);
   
}

- (void) mockRunTransaction {
    NSLog(@"mockRunTransaction");
}

@end
