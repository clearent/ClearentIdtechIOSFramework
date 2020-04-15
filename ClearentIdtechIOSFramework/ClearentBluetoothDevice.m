//
//  ClearentBluetoothDevice.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/31/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import "ClearentBluetoothDevice.h"

@implementation ClearentBluetoothDevice

- (instancetype) init:(NSString*)friendlyName deviceId:(NSString*) deviceId {
    self = [super init];
    if (self) {
        _friendlyName = friendlyName;
        _deviceId = deviceId;
    }
    return self;
}

@end
