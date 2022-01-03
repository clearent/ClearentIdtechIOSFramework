//
//  ClearentCache.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/6/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ClearentCache.h"
#import "ClearentLumberjack.h"

static NSString *const NSUSERDEFAULT_KERNEL_VERSION = @"KernelVersion";
static NSString *const NSUSERDEFAULT_FIRMWARE_VERSION = @"FirmwareVersion";
static NSString *const NSUSERDEFAULT_LAST_USED_BLUETOOTH_DEVICEID = @"LastUsedBluetoothDeviceId";
static NSString *const NSUSERDEFAULT_LAST_USED_BLUETOOTH_FRIENDLYNAME = @"LastUsedBluetoothFriendlyName";
static NSString *const NSUSERDEFAULT_DEVICESERIALNUMBER = @"DeviceSerialNumber";
static NSString *const NSUSERDEFAULT_READERCONFIGURED = @"ReaderConfigured";
static NSString *const NSUSERDEFAULT_CONTACTLESSCONFIGURED = @"ReaderContactlessConfigured";

static NSString *const DEVICESERIALNUMBER_STANDIN = @"9999999999";

@implementation ClearentCache

+ (NSString *) getReaderConfiguredFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:NSUSERDEFAULT_READERCONFIGURED];
}

+ (NSString *) getReaderContactlessConfiguredFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:NSUSERDEFAULT_CONTACTLESSCONFIGURED];
}

+ (void) updateContactlessFlagCache:(NSString *) readerContactlessConfiguredFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:readerContactlessConfiguredFlag forKey:NSUSERDEFAULT_CONTACTLESSCONFIGURED];
    [ClearentLumberjack logInfo:@"Updated the contactless configuration flag cache"];
}

+ (void) updateConfigurationCache:(NSString *) deviceSerialNumber readerConfiguredFlag:(NSString *) readerConfiguredFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceSerialNumber forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    [defaults setObject:readerConfiguredFlag forKey:NSUSERDEFAULT_READERCONFIGURED];
    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Updated the reader configuration cache. Device Serial Number is %@. Configured flag is %@", deviceSerialNumber, readerConfiguredFlag]];
}

+ (void) clearConfigurationCache {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    [defaults setObject:nil forKey:NSUSERDEFAULT_READERCONFIGURED];
    [ClearentLumberjack logInfo:@"Clearing configuration cache"];
}

+ (void) clearContactlessConfigurationCache {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:NSUSERDEFAULT_CONTACTLESSCONFIGURED];
    [ClearentLumberjack logInfo:@"Clearing contactless configuration cache"];
}

+ (BOOL) isDeviceConfigured:(BOOL)autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration deviceSerialNumber:(NSString *)deviceSerialNumber {
    
    if(!autoConfiguration && !contactlessAutoConfiguration) {
         return YES;
    }
    
    NSString *storedDeviceSerialNumber = [ClearentCache getCurrentDeviceSerialNumber];
    NSString *readerConfiguredFlag = [ClearentCache getReaderConfiguredFlag];
    NSString *readerContactlessConfiguredFlag = [ClearentCache getReaderContactlessConfiguredFlag];
    
    if(autoConfiguration && contactlessAutoConfiguration) {
        if(storedDeviceSerialNumber != nil && [storedDeviceSerialNumber isEqualToString:deviceSerialNumber]) {
            if(readerConfiguredFlag != nil && [readerConfiguredFlag isEqualToString:@"true"] && readerContactlessConfiguredFlag != nil && [readerContactlessConfiguredFlag isEqualToString:@"true"]) {
                return YES;
            }
        }
    } else if(autoConfiguration && !contactlessAutoConfiguration) {
        if(storedDeviceSerialNumber != nil && [storedDeviceSerialNumber isEqualToString:deviceSerialNumber]) {
            if(readerConfiguredFlag != nil && [readerConfiguredFlag isEqualToString:@"true"]) {
                return YES;
            }
        }
    } else if(!autoConfiguration && contactlessAutoConfiguration) {
        if(storedDeviceSerialNumber != nil && [storedDeviceSerialNumber isEqualToString:deviceSerialNumber]) {
            if(readerContactlessConfiguredFlag != nil && [readerContactlessConfiguredFlag isEqualToString:@"true"]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (NSString *) getCurrentDeviceSerialNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentDeviceSerialNumber = [defaults objectForKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    if(currentDeviceSerialNumber == nil) {
        currentDeviceSerialNumber = DEVICESERIALNUMBER_STANDIN;
    }
    return currentDeviceSerialNumber;
}

+ (void) cacheCurrentDeviceSerialNumber:(NSString *) currentDeviceSerialNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(currentDeviceSerialNumber == nil) {
        currentDeviceSerialNumber = DEVICESERIALNUMBER_STANDIN;
    }
    [defaults setObject:currentDeviceSerialNumber forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
}

+ (void) cacheLastUsedBluetoothDevice:(NSString*) bluetoothDeviceId bluetoothFriendlyName:(NSString *) bluetoothFriendlyName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:bluetoothDeviceId forKey:NSUSERDEFAULT_LAST_USED_BLUETOOTH_DEVICEID];
    [defaults setObject:bluetoothFriendlyName forKey:NSUSERDEFAULT_LAST_USED_BLUETOOTH_FRIENDLYNAME];
}

+ (NSString *) getLastUsedBluetoothDeviceId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:NSUSERDEFAULT_LAST_USED_BLUETOOTH_DEVICEID];
}

+ (NSString *) getLastUsedBluetoothFriendlyName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:NSUSERDEFAULT_LAST_USED_BLUETOOTH_FRIENDLYNAME];
}

+ (void) cacheReaderProfile:(NSString *) kernelVersion firmwareVersion:(NSString *) firmwareVersion deviceSerialNumber: (NSString *) deviceSerialNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:kernelVersion forKey:NSUSERDEFAULT_KERNEL_VERSION];
    [defaults setObject:firmwareVersion forKey:NSUSERDEFAULT_FIRMWARE_VERSION];
    [defaults setObject:deviceSerialNumber forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    
}

+ (NSString *) getKernelVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:NSUSERDEFAULT_KERNEL_VERSION];
}


+ (NSString *) getFirmwareVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:NSUSERDEFAULT_FIRMWARE_VERSION];
}

+ (void) clearReaderProfile {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    [defaults setObject:nil forKey:NSUSERDEFAULT_FIRMWARE_VERSION];
    [defaults setObject:nil forKey:NSUSERDEFAULT_KERNEL_VERSION];
    [ClearentLumberjack logInfo:@"Clearing cached reader profile"];
}


+ (BOOL) isReaderProfileCached {
    
    NSString *deviceSerialNumber = [ClearentCache getCurrentDeviceSerialNumber];
    NSString *kernelVersion = [ClearentCache getKernelVersion];
    NSString *firmwareVersion = [ClearentCache getFirmwareVersion];
    
    if(deviceSerialNumber == nil || kernelVersion == nil || firmwareVersion == nil) {
        return NO;
    }
    
    if(deviceSerialNumber != nil && [deviceSerialNumber isEqualToString:DEVICESERIALNUMBER_STANDIN]) {
        [ClearentLumberjack logInfo:@"Device Serial Number cached as nines. Consider cache busted"];
        return NO;
    }
    
    return YES;
}

@end

