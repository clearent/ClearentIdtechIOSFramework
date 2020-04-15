//
//  TestPublicDelegate.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/15/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClearentIdtechIOSFramework/ClearentPublicVP3300Delegate.h>
#import <ClearentIdtechIOSFramework/ClearentTransactionToken.h>
#import <ClearentIdtechIOSFramework/ClearentFeedback.h>

@interface TestPublicDelegate : NSObject<Clearent_Public_IDTech_VP3300_Delegate>

@property (nonatomic) BOOL readyFlag;
@property (nonatomic) BOOL deviceConnectedFlag;
@property (nonatomic) BOOL deviceInserted;
@property (nonatomic) BOOL plugStatusChangeCalled;
@property (nonatomic) NSString *message;
@property (nonatomic) ClearentFeedback *clearentFeedback;
@property (nonatomic) ClearentTransactionToken *clearentTransactionToken;
@property (nonatomic) NSArray<ClearentBluetoothDevice> *bluetoothDevices;

@end

