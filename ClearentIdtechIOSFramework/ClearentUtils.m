//
//  ClearentUtils.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentUtils.h"
#import <sys/utsname.h>
#import "Teleport.h"

static NSString *const NSUSERDEFAULT_DEVICESERIALNUMBER = @"DeviceSerialNumber";
static NSString *const NSUSERDEFAULT_READERCONFIGURED = @"ReaderConfigured";
static NSString *const DEVICESERIALNUMBER_STANDIN = @"9999999999";
static NSString *const SDK_VERSION = @"1.0.26";
static NSString *const DATE_FORMAT = @"yyyy-MM-dd-HH-mm-ss-SSS-zzz";
static NSString *const PLATFORM = @"IOS";
static NSString *const DEFAULT_EMBEDDED_VALUE = @"LOG";

@implementation ClearentUtils

+ (NSString *) createExchangeChainId:(NSString*) embeddedValue {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:DATE_FORMAT];
    NSDate *now = [[NSDate alloc] init];
    NSString *dateTime = [dateFormat stringFromDate:now];
    if(embeddedValue == nil) {
        return [NSString stringWithFormat:@"%@-%@-%@", PLATFORM, DEFAULT_EMBEDDED_VALUE, dateTime];
    } else {
        return [NSString stringWithFormat:@"%@-%@-%@", PLATFORM, embeddedValue, dateTime];
    }
}

+ (NSString *) getStoredDeviceSerialNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedDeviceSerialNumber = [defaults objectForKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    if(storedDeviceSerialNumber == nil) {
        storedDeviceSerialNumber = DEVICESERIALNUMBER_STANDIN;
    }
    return storedDeviceSerialNumber;
}

+ (void) updateConfigurationCache:(NSString *) deviceSerialNumber readerConfiguredFlag:(NSString *) readerConfiguredFlag {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceSerialNumber forKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    [defaults setObject:readerConfiguredFlag forKey:NSUSERDEFAULT_READERCONFIGURED];
    [defaults synchronize];
    [Teleport logInfo:@"Updated the reader configuration cache"];
}


+ (NSString*) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine
                                              encoding:NSUTF8StringEncoding];
    if(deviceName == nil) {
        deviceName = @"unknown";
    }
    return deviceName;
}

+ (NSString*) osVersion {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *osVersion = [processInfo operatingSystemVersionString];
    if(osVersion == nil) {
        osVersion = @"unknown";
    }
    return osVersion;
}

+ (NSString*) sdkVersion {
    return SDK_VERSION;
}

+ (NSDictionary*) hostProfileData {
    return  @{@"platform":@"Apple",@"os-version":[ClearentUtils osVersion],@"sdk-version":[ClearentUtils sdkVersion],@"model":[ClearentUtils deviceName]};
}

@end
