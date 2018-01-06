//
//  ClearentTransactionTokenRequest.m
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentTransactionTokenRequest.h"

@implementation ClearentTransactionTokenRequest

- (NSString*) asJson {
    NSMutableDictionary *contentDictionary = [[NSMutableDictionary alloc]init];
    [contentDictionary setValue:self.cvm forKey:@"cvm"];
    [contentDictionary setValue:self.track2Data forKey:@"track2Data"];
    [contentDictionary setValue:self.entryMode forKey:@"entryMode"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:contentDictionary
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}
@end
