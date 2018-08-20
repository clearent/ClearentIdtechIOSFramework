//
//  ClearentTransactionTokenRequest.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.
#import "ClearentTransactionTokenRequest.h"

@implementation ClearentTransactionTokenRequest

- (NSDictionary*) asDictionary {
    NSDictionary* dict;
    if(self.applicationPreferredNameTag9F12 == nil) {
        self.applicationPreferredNameTag9F12 = @"";
    }
    if(self.emv) {
        dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":@"true",@"device-format":@"IDTECH",@"tlv":self.tlv,@"tlv-encrypted":(self.encrypted  ? @"true" : @"false"),@"track2-data":self.track2Data, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12};
    } else if(self.tlv != nil) {
        dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":@"false",@"device-format":@"IDTECH",@"track2-data":self.track2Data, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12,@"tlv":self.tlv};
    } else {
        dict = @{@"kernel-version":self.kernelVersion,@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber,@"emv":@"false",@"device-format":@"IDTECH",@"track2-data":self.track2Data, @"application-preferred-name-tag-9f12":self.applicationPreferredNameTag9F12};
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
