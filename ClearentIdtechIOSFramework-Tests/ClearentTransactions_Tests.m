//
//  ClearentTransactions_Tests.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 4/20/20.
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
#import <ClearentIdtechIOSFramework/ClearentTransactions.h>
#import "TestPublicDelegate.h"

@interface ClearentTransactions_Tests : XCTestCase

@property(nonatomic, strong) id mockClearentVP3300;
@property(nonatomic, strong) id mockIDTechSharedInstance;
@property(nonatomic, strong) TestPublicDelegate *testPublicDelegate;

@property(nonatomic, strong) ClearentDeviceConnector *clearentDeviceConnector;
@property(nonatomic, strong) ClearentDelegate *clearentDelegate;
@property(nonatomic, strong) ClearentVP3300Config *clearentVP3300Config;
@property(nonatomic, strong) ClearentTransactions *clearentTransactions;

@end

@implementation ClearentTransactions_Tests

@synthesize mockClearentVP3300 = _mockClearentVP3300;
@synthesize mockIDTechSharedInstance = _mockIDTechSharedInstance;

SEL mockRunTransactionSelector2;

- (void) setUp {
    
    _mockClearentVP3300 = OCMClassMock([Clearent_VP3300 class]);
    _mockIDTechSharedInstance = OCMClassMock([IDT_VP3300 class]);
    
    SEL runTransactionSelector = NSSelectorFromString(@"mockRunTransaction");
    if ([self respondsToSelector:runTransactionSelector]) {
        mockRunTransactionSelector2 = runTransactionSelector;
    }
    
    _testPublicDelegate = [[TestPublicDelegate alloc]  init];
    _clearentVP3300Config = [[ClearentVP3300Config alloc] init];
    _clearentVP3300Config.clearentBaseUrl = @"baseUrl";
    _clearentVP3300Config.publicKey = @"publicKey";
    
    _clearentDelegate = [[ClearentDelegate alloc] initWithPaymentCallback:_testPublicDelegate clearentVP3300Configuration:_clearentVP3300Config callbackObject:self withSelector:runTransactionSelector idTechSharedInstance:_mockIDTechSharedInstance];
    
    _clearentTransactions = [[ClearentTransactions alloc] init:_clearentDelegate clearentVP3300:_mockClearentVP3300];
    
    _clearentDeviceConnector = [[ClearentDeviceConnector alloc] init:_clearentDelegate clearentVP3300:_mockClearentVP3300];
}

- (void) tearDown {
    [self.mockClearentVP3300 stopMocking];
    [self.mockIDTechSharedInstance stopMocking];
}

- (void) testStartTransactionWithBluetoothFirstConnect_Success {
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    OCMStub([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMStub([self.mockIDTechSharedInstance device_getBLEFriendlyName]).andReturn(@"friendlyName");

    ClearentResponse *clearentResponse = [_clearentTransactions startTransaction:clearentPayment clearentConnection:clearentConnection];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    XCTAssertTrue(_clearentDelegate.runStoredPaymentAfterConnecting);
    
}

- (void) testStartTransactionWithBluetoothFirstConnect_Retry_Transaction_After_Disocnnected_State_When_Transaction_Requested {
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    
    OCMStub([self.mockClearentVP3300 isConnected]).andReturn(true);
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(false);
    OCMStub([self.mockIDTechSharedInstance device_enableBLEDeviceSearch:[OCMArg any]]).andReturn(true);
    OCMStub([self.mockIDTechSharedInstance device_getBLEFriendlyName]).andReturn(@"friendlyName");

    ClearentResponse *clearentResponse = [_clearentTransactions startTransaction:clearentPayment clearentConnection:clearentConnection];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    
}

- (void) testHandleAStartTransactionResult_Success {

    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_DO_SUCCESS];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"TRANSACTION STARTED", clearentResponse.response);
    
}

- (void) testHandleAStartTransactionResult_Disconnect {

    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_ERR_DISCONNECT];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    XCTAssertTrue(_clearentTransactions.retriedTransactionAfterDisconnect);
    
}

- (void) testBluetooth_HandleAStartTransactionResult_Previous_Transaction_In_Progress_Not_Cancelled {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_cancelTransaction]).andReturn(RETURN_CODE_SDK_BUSY_CMD);
    OCMExpect([self.mockClearentVP3300 device_disconnectBLE]);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_SDK_BUSY_CMD];
    
    OCMVerifyAll(self.mockClearentVP3300);
             
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    XCTAssertTrue(_clearentTransactions.retriedTransactionAfterDisconnect);
    
}

- (void) testBluetooth_HandleAStartTransactionResult_Previous_Transaction_In_Progress_Cancelled {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_cancelTransaction]).andReturn(RETURN_CODE_DO_SUCCESS);
    OCMExpect([self.mockIDTechSharedInstance device_disconnectBLE]);
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    
    OCMStub([self.mockIDTechSharedInstance device_startTransaction:5 amtOther:5 type:0 timeout:30 tags:[OCMArg any] forceOnline:[OCMArg any]  fallback:[OCMArg any]]).andReturn(RETURN_CODE_DO_SUCCESS);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_SDK_BUSY_CMD];
    
    OCMVerifyAll(self.mockClearentVP3300);
             
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"TRANSACTION STARTED", clearentResponse.response);
    
}

- (void) testBluetooth_HandleAStartTransactionResult_Previous_Transaction_In_Progress_Cancelled_But_New_Trans_Failed {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    _clearentDelegate.clearentPayment = clearentPayment;
    
    OCMStub([self.mockIDTechSharedInstance device_cancelTransaction]).andReturn(RETURN_CODE_DO_SUCCESS);
    OCMExpect([self.mockIDTechSharedInstance device_disconnectBLE]);
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    
    OCMStub([self.mockIDTechSharedInstance device_startTransaction:clearentPayment.amount amtOther:clearentPayment.amtOther type:clearentPayment.type timeout:clearentPayment.timeout tags:clearentPayment.tags forceOnline:clearentPayment.forceOnline  fallback:clearentPayment.fallback]).andReturn(RETURN_CODE_SDK_BUSY_CMD);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_SDK_BUSY_CMD];
    
    OCMVerifyAll(self.mockClearentVP3300);
             
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    
}

- (void) testBluetooth_HandleAStartTransactionResult_GeneralFailure_Not_Cancelled {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_cancelTransaction]).andReturn(RETURN_CODE_SDK_BUSY_CMD);
    OCMExpect([self.mockClearentVP3300 device_disconnectBLE]);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_ERR_OTHER_];
    
    OCMVerifyAll(self.mockClearentVP3300);
             
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    XCTAssertTrue(_clearentTransactions.retriedTransactionAfterDisconnect);
    
}

- (void) testBluetooth_HandleAStartTransactionResult_GeneralFailure_Cancelled {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    OCMStub([self.mockIDTechSharedInstance device_cancelTransaction]).andReturn(RETURN_CODE_DO_SUCCESS);
    OCMExpect([self.mockIDTechSharedInstance device_disconnectBLE]);
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    
    OCMStub([self.mockIDTechSharedInstance device_startTransaction:5 amtOther:5 type:0 timeout:30 tags:[OCMArg any] forceOnline:[OCMArg any]  fallback:[OCMArg any]]).andReturn(RETURN_CODE_DO_SUCCESS);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_ERR_OTHER_];
    
    OCMVerifyAll(self.mockClearentVP3300);
             
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"TRANSACTION STARTED", clearentResponse.response);
    
}

- (void) testBluetooth_HandleAStartTransactionResult_GeneralFailure_But_New_Trans_Failed {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    _clearentDelegate.clearentPayment = clearentPayment;
    
    OCMStub([self.mockIDTechSharedInstance device_cancelTransaction]).andReturn(RETURN_CODE_DO_SUCCESS);
    OCMExpect([self.mockIDTechSharedInstance device_disconnectBLE]);
    OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    
    OCMStub([self.mockIDTechSharedInstance device_startTransaction:clearentPayment.amount amtOther:clearentPayment.amtOther type:clearentPayment.type timeout:clearentPayment.timeout tags:clearentPayment.tags forceOnline:clearentPayment.forceOnline  fallback:clearentPayment.fallback]).andReturn(RETURN_CODE_SDK_BUSY_CMD);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_ERR_OTHER_];
    
    OCMVerifyAll(self.mockClearentVP3300);
             
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    
}


- (void) testHandleAStartTransactionResult_Bluetooth_Connection_Error {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initBluetoothFirstConnect];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    _clearentDelegate.clearentPayment = clearentPayment;
    
    OCMExpect([self.mockIDTechSharedInstance device_disconnectBLE]);
   // OCMStub([self.mockIDTechSharedInstance isConnected]).andReturn(true);
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_NEO_TIMEOUT];
    
    OCMVerifyAll(self.mockClearentVP3300);
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_DO_SUCCESS);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_SUCCESS);
    XCTAssertEqualObjects(@"PRESS BUTTON ON READER", clearentResponse.response);
    XCTAssertTrue(_clearentTransactions.retriedTransactionAfterDisconnect);
    XCTAssertTrue(_clearentDelegate.runStoredPaymentAfterConnecting);
    
}

- (void) testHandleAStartTransactionResult_General_Connection_Error {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initAudioJack];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    _clearentDelegate.clearentPayment = clearentPayment;
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_NEO_TIMEOUT];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_NEO_TIMEOUT);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_FAIL);
    XCTAssertEqualObjects(@"DEVICE NOT CONNECTED", clearentResponse.response);
    XCTAssertFalse(_clearentTransactions.retriedTransactionAfterDisconnect);
    XCTAssertFalse(_clearentDelegate.runStoredPaymentAfterConnecting);
    
}

- (void) testHandleAStartTransactionResult_Invalid_Transaction_Error {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initAudioJack];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    _clearentDelegate.clearentPayment = clearentPayment;
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_ERR_INVALID_PARAMETER_];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_ERR_INVALID_PARAMETER_);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_FAIL);
    XCTAssertEqualObjects(@"INVALID TRANSACTION", clearentResponse.response);
    XCTAssertFalse(_clearentTransactions.retriedTransactionAfterDisconnect);
    XCTAssertFalse(_clearentDelegate.runStoredPaymentAfterConnecting);
    
}

- (void) testHandleAStartTransactionResult_Unhandled_Transaction_Error {

    ClearentConnection *clearentConnection = [[ClearentConnection alloc]  initAudioJack];
    _clearentDelegate.clearentConnection = clearentConnection;
    
    ClearentPayment *clearentPayment = [[ClearentPayment alloc] initSale];
    clearentPayment.amount = 1.00;
    _clearentDelegate.clearentPayment = clearentPayment;
    
    ClearentResponse *clearentResponse = [_clearentTransactions handleStartTransactionResult:RETURN_CODE_UNSUPPORTED_COMMAND_];
    
    XCTAssertNotNil(clearentResponse);
    XCTAssertTrue(clearentResponse.idtechReturnCode == RETURN_CODE_UNSUPPORTED_COMMAND_);
    XCTAssertTrue(clearentResponse.responseType == RESPONSE_FAIL);
    XCTAssertEqualObjects(@"TRANSACTION FAILED", clearentResponse.response);
    XCTAssertFalse(_clearentTransactions.retriedTransactionAfterDisconnect);
    XCTAssertFalse(_clearentDelegate.runStoredPaymentAfterConnecting);
    
}


@end
