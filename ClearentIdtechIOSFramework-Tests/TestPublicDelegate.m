//
//  TestPublicDelegate.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 4/15/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TestPublicDelegate.h"

@implementation TestPublicDelegate

- (void) isReady {
    _readyFlag = true;
}

- (void) successTransactionToken:(ClearentTransactionToken *) clearentTransactionToken {
    _clearentTransactionToken = clearentTransactionToken;
}

- (void) deviceConnected {
    _deviceConnectedFlag = true;
}

- (void) deviceDisconnected {
    _deviceConnectedFlag = false;
}

- (void) plugStatusChange:(BOOL)deviceInserted {
    _deviceInserted = deviceInserted;
    _plugStatusChangeCalled = true;
}

- (void) feedback:(ClearentFeedback*) clearentFeedback {
    _clearentFeedback = clearentFeedback;
}

- (void) deviceMessage: (NSString*) message {
    _message = message;
}

- (void) bluetoothDevices:(NSArray<ClearentBluetoothDevice*>*) bluetoothDevices {
    _bluetoothDevices = [bluetoothDevices copy];
}

- (void)successfulTransactionToken:(NSString *)jsonString {
    //deprecated
}

@end

