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

- (instancetype)initWithIdtechSharedController:(IDT_VP3300*) sharedController {
    self = [super init];
    if (self) {
        _sharedController = sharedController;
    }
    return self;
}

- (int) initClock {
    RETURN_CODE dateRt = [self initClockDate];
    RETURN_CODE timeRt = [self initClockTime];
    if (RETURN_CODE_DO_SUCCESS == dateRt && RETURN_CODE_DO_SUCCESS == timeRt) {
        NSLog(@"Clock Initialized");
    } else {
        return CLOCK_FAILED;
    }
    return CLOCK_CONFIGURATION_SUCCESS;
}

- (int) initClockDate {
    NSData *clockDate = [self getClockDateAsYYYYMMDD];
    NSData *result;
    return [_sharedController device_sendIDGCommand:0x25 subCommand:0x03 data:clockDate response:&result];
}

- (NSData*) getClockDateAsYYYYMMDD {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    return [IDTUtility hexToData:dateString];
}

- (int) initClockTime {
    NSData *timeDate = [self getClockTimeAsHHMM];
    NSData *result;
    return [_sharedController device_sendIDGCommand:0x25 subCommand:0x01 data:timeDate response:&result];
}

- (NSData*) getClockTimeAsHHMM {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HHMM";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    return [IDTUtility hexToData:timeString];
}

@end
