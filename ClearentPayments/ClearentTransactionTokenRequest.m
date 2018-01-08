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
    //NSDictionary* dict = @{@"cvm":self.cvm, @"track2Data":self.track2Data, @"entryMode":self.entryMode, @"ksn":self.ksn};
    NSDictionary* dict = @{@"tlv":self.tlv};
    return dict;
}

- (NSString*) asJson {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}
@end
