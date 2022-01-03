//
//  ClearentCache.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/6/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentCache : NSObject

+ (NSString *) getReaderConfiguredFlag;
+ (NSString *) getReaderContactlessConfiguredFlag;
+ (void) updateConfigurationCache:(NSString *) deviceSerialNumber readerConfiguredFlag:(NSString *) readerConfiguredFlag;
+ (void) updateContactlessFlagCache:(NSString *) readerContactlessConfiguredFlag;
+ (void) clearConfigurationCache;
+ (void) clearContactlessConfigurationCache;
+ (BOOL) isDeviceConfigured:(BOOL)autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration deviceSerialNumber:(NSString *)deviceSerialNumber;
+ (NSString *) getCurrentDeviceSerialNumber;
+ (void) cacheCurrentDeviceSerialNumber:(NSString *) currentDeviceSerialNumber;

+ (void) cacheLastUsedBluetoothDevice:(NSString*) bluetoothDeviceId bluetoothFriendlyName:(NSString *) bluetoothFriendlyName;

+ (NSString *) getLastUsedBluetoothDeviceId;
+ (NSString *) getLastUsedBluetoothFriendlyName;

+ (void) cacheReaderProfile:(NSString *) kernelVersion firmwareVersion:(NSString *) firmwareVersion deviceSerialNumber: (NSString *) deviceSerialNumber;

+ (NSString *) getKernelVersion;

+ (NSString *) getFirmwareVersion;

+ (void) clearReaderProfile;

+ (BOOL) isReaderProfileCached;

@end
