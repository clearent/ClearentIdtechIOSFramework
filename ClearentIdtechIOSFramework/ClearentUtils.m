//
//  ClearentUtils.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentUtils.h"

@implementation ClearentUtils

+ (NSString *) createExchangeChainId:(NSString*) embeddedValue {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd-HH-mm-ss-SSS-zzz"];
    NSDate *now = [[NSDate alloc] init];
    NSString *dateTime = [dateFormat stringFromDate:now];
    if(embeddedValue == nil) {
        return [NSString stringWithFormat:@"%@-%@-%@", @"IOS", @"LOG", dateTime];
    } else {
        return [NSString stringWithFormat:@"%@-%@-%@", @"IOS", embeddedValue, dateTime];
    }
}

@end
