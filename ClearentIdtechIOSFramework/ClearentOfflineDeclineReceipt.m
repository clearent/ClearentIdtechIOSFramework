//
//  ClearentOfflineDeclineReceipt.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 8/13/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//
#import "ClearentOfflineDeclineReceipt.h"
#import "ClearentUtils.h"
@implementation ClearentOfflineDeclineReceipt

- (NSDictionary*) asDictionary {
    NSDictionary* dict;
    if(self.applicationPreferredNameTag9F12 == nil) {
        self.applicationPreferredNameTag9F12 = @"";
    }
    NSDictionary* hostProfileData = [ClearentUtils hostProfileData];
    
    if(self.maskedTrack2Data == nil || [self.maskedTrack2Data isEqualToString:@""]) {
        self.maskedTrack2Data = @"";
    }
    if(self.tlv == nil || [self.tlv isEqualToString:@""]) {
        self.tlv = @"";
    }
    if(self.amount == nil || [self.amount isEqualToString:@""]) {
        self.amount = @"";
    }
    if(self.emailAddress == nil || [self.emailAddress isEqualToString:@""]) {
        self.emailAddress = @"";
    }
    dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber, @"device-format":@"IDTECH",@"tlv":self.tlv, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"host-profile":hostProfileData,@"masked-track2-data":self.maskedTrack2Data,@"amount":self.amount,@"email":self.emailAddress};
    
    return dict;
}

- (NSString*) asJson {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

@end

