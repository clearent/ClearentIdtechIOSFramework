//
//  ClearentClockConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentClockConfigurator.h"

@implementation ClearentClockConfigurator

+ (int) initClockDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSData *clockDate = [IDTUtility hexToData:dateString];
    NSData *result;
    RETURN_CODE dateRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x25 subCommand:0x03 data:clockDate response:&result];
    if (RETURN_CODE_DO_SUCCESS == dateRt) {
        NSLog(@"Clock Date Initialized");
    } else {
        return DATE_FAILED;
    }
    return CLOCK_CONFIGURATION_SUCCESS;
}

+ (int) initClockTime {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HHMM";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    NSData *timeDate = [IDTUtility hexToData:timeString];
    NSData *result;
    RETURN_CODE timeRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x25 subCommand:0x01 data:timeDate response:&result];
    if (RETURN_CODE_DO_SUCCESS == timeRt) {
        NSLog(@"Clock Time Initialized");
    } else {
        return TIME_FAILED;
    }
    return CLOCK_CONFIGURATION_SUCCESS;
}

@end
