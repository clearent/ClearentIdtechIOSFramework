//
//  ClearentTransactionTokenRequest.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.
#import "ClearentTransactionTokenRequest.h"
#import <sys/utsname.h>

@implementation ClearentTransactionTokenRequest

- (NSDictionary*) asDictionary {
    NSDictionary* dict;
    if(self.applicationPreferredNameTag9F12 == nil) {
        self.applicationPreferredNameTag9F12 = @"";
    }
    NSDictionary* hostProfileData = self.hostProfileData;
    if(self.emv) {
        dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":@"true",@"device-format":@"IDTECH",@"tlv":self.tlv,@"tlv-encrypted":(self.encrypted  ? @"true" : @"false"),@"track2-data":self.track2Data, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"host-profile":hostProfileData};
    } else if(self.tlv != nil) {
        dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":@"false",@"device-format":@"IDTECH",@"track2-data":self.track2Data, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"tlv":self.tlv,@"host-profile":hostProfileData};
    } else {
        dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":@"false",@"device-format":@"IDTECH",@"track2-data":self.track2Data, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"host-profile":hostProfileData};
    }
    return dict;
}

- (NSString*) asJson {
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

- (NSDictionary*) hostProfileData {
    NSString *osVersion = self.osVersion;
    NSString *deviceName = self.deviceName;
    NSString *sdkVersion = self.sdkVersion;
    return  @{@"platform":@"Apple",@"os-version":osVersion,@"sdk-version":sdkVersion,@"model":deviceName};
}

- (NSString*) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
    if(deviceName == nil) {
        deviceName = @"unknown";
    }
    return deviceName;
}

- (NSString*) osVersion {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *osVersion = [processInfo operatingSystemVersionString];
    if(osVersion == nil) {
        osVersion = @"unknown";
    }
    return osVersion;
}

- (NSString*) sdkVersion {
    return @"1.0.0";
}

@end
