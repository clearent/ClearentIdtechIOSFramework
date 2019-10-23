//
//  ClearentTransactionTokenRequest.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.
#import "ClearentTransactionTokenRequest.h"
#import "ClearentUtils.h"

@implementation ClearentTransactionTokenRequest

- (NSDictionary*) asDictionary {
    NSDictionary* dict;
    if(self.applicationPreferredNameTag9F12 == nil) {
        self.applicationPreferredNameTag9F12 = @"";
    }
    NSDictionary* hostProfileData = [ClearentUtils hostProfileData];
    if(self.encrypted) {
        if(self.maskedTrack2Data == nil || [self.maskedTrack2Data isEqualToString:@""]) {
            self.maskedTrack2Data = @"";
        }
        if(self.ksn == nil || [self.ksn isEqualToString:@""]) {
            self.ksn = @"";
        }
        if(self.tlv != nil) {
            dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":(self.emv  ? @"true" : @"false"),@"device-format":@"IDTECH",@"tlv":self.tlv,@"tlv-encrypted":(self.encrypted  ? @"true" : @"false"),@"track2-data":self.track2Data,@"ksn":self.ksn, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"host-profile":hostProfileData,@"masked-track2-data":self.maskedTrack2Data};
        } else {
            dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":(self.emv  ? @"true" : @"false"),@"device-format":@"IDTECH",@"tlv-encrypted":(self.encrypted  ? @"true" : @"false"),@"track2-data":self.track2Data,@"ksn":self.ksn, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"host-profile":hostProfileData,@"masked-track2-data":self.maskedTrack2Data};
        }
    } else if(self.emv) {
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

@end
