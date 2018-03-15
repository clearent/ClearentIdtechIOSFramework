//
//  ClearentTransactionTokenRequest.m
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentTransactionTokenRequest.h"

@implementation ClearentTransactionTokenRequest

- (NSDictionary*) asDictionary {
    NSDictionary* dict = @{@"tlv":self.tlv,@"tlv-encrypted":(self.encrypted  ? @"true" : @"false"),@"device-format":@"IDTECH",@"firmware-version":self.firmwareVersion,@"device-serial-number":self.deviceSerialNumber};
    return dict;
}

- (NSString*) asJson {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}
@end
