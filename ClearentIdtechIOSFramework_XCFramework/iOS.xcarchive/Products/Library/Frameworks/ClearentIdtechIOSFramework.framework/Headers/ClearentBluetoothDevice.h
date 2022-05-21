//
//  ClearentBluetoothDevice.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/31/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ClearentBluetoothDevice <NSObject>

- (NSString*) friendlyName;
- (NSString*) deviceId;
- (BOOL) connected;

@end

@interface ClearentBluetoothDevice: NSObject <ClearentBluetoothDevice>

@property (nonatomic) NSString *friendlyName;
@property (nonatomic) NSString *deviceId;
@property (nonatomic) BOOL connected;

- (instancetype) init:(NSString*)friendlyName deviceId:(NSString*) deviceId;

@end

