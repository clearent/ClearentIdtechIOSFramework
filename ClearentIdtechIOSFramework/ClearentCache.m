//
//  ClearentCache.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/6/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ClearentCache.h"
#import "Teleport.h"

static NSString *const NSUSERDEFAULT_LAST_USED_BLUETOOTH_DEVICEID = @"LastUsedBluetoothDeviceId";
static NSString *const NSUSERDEFAULT_LAST_USED_BLUETOOTH_FRIENDLYNAME = @"LastUsedBluetoothFriendlyName";
static NSString *const NSUSERDEFAULT_DEVICESERIALNUMBER = @"DeviceSerialNumber";
static NSString *const NSUSERDEFAULT_READERCONFIGURED = @"ReaderConfigured";
static NSString *const NSUSERDEFAULT_CONTACTLESSCONFIGURED = @"ReaderContactlessConfigured";

static NSString *const DEVICESERIALNUMBER_STANDIN = @"9999999999";
static NSString *const CURRENT_DEVICESERIALNUMBER = @"CurrentDeviceSerialNumber";

@implementation ClearentCache

+ (NSString *) getStoredDeviceSerialNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedDeviceSerialNumber = [defaults objectForKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    if(storedDeviceSerialNumber == nil) {
        storedDeviceSerialNumber = DEVICESERIALNUMBER_STANDIN;
    }
    return storedDeviceSerialNumber;
}

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
    [Teleport logInfo:@"Updated the contactless configuration flag cache"];
}

+ (void) updateConfigurationCache:(NSString *) deviceSerialNumber readerConfiguredFlag:(NSString *) readerConfiguredFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceSerialNumber forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    [defaults setObject:readerConfiguredFlag forKey:NSUSERDEFAULT_READERCONFIGURED];
    [Teleport logInfo:[NSString stringWithFormat:@"Updated the reader configuration cache. Device Serial Number is %@. Configured flag is %@", deviceSerialNumber, readerConfiguredFlag]];
}

+ (void) clearConfigurationCache {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    [defaults setObject:nil forKey:NSUSERDEFAULT_READERCONFIGURED];
    [Teleport logInfo:@"Clearing configuration cache"];
}

+ (void) clearContactlessConfigurationCache {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:NSUSERDEFAULT_CONTACTLESSCONFIGURED];
    [Teleport logInfo:@"Clearing contactless configuration cache"];
}

+ (BOOL) isDeviceConfigured:(BOOL)autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration deviceSerialNumber:(NSString *)deviceSerialNumber {
    
    if(!autoConfiguration && !contactlessAutoConfiguration) {
         return YES;
    }
    
    NSString *storedDeviceSerialNumber = [ClearentCache getStoredDeviceSerialNumber];
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
    NSString *currentDeviceSerialNumber = [defaults objectForKey:CURRENT_DEVICESERIALNUMBER];
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
    [defaults setObject:currentDeviceSerialNumber forKey:CURRENT_DEVICESERIALNUMBER];
}

+ (void) cacheLastUsedBluetoothDevice:(NSString*) bluetoothDeviceId bluetoothFriendlyName:(NSString *) bluetoothFriendlyName; {
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


@end

