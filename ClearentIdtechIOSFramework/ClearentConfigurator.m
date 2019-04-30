//
//  ClearentConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConfigurator.h"
#import <IDTech/IDTUtility.h>
#import "Teleport.h"

static NSString *const NSUSERDEFAULT_DEVICESERIALNUMBER = @"DeviceSerialNumber";
static NSString *const NSUSERDEFAULT_READERCONFIGURED = @"ReaderConfigured";
static NSString *const READER_CONFIGURED_MESSAGE = @"Reader configured and ready";

@implementation ClearentConfigurator

- (instancetype) init: (NSString*)clearentBaseUrl publicKey:(NSString*)publicKey callbackObject:(id)callbackObject withSelector:(SEL)selector sharedController:(IDT_VP3300*) sharedController {
    self = [super init];
    if (self) {
        _sharedController = sharedController;
        self.callbackObject = callbackObject;
        self.publicKey = publicKey;
        self.baseUrl = clearentBaseUrl;
        self.selector = selector;
        self.configured = NO;
    }
    return self;
}

-(void) configure: (NSString*)kernelVersion  deviceSerialNumber:(NSString*) deviceSerialNumber {
    if(deviceSerialNumber  == nil) {
        [self notifyInfo:@"Connect device"];
        return;
    }
    if(self.baseUrl == nil) {
        [self notifyInfo:@"Configuration url is required for device configuration"];
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedDeviceSerialNumber = [defaults objectForKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    NSString *readerConfiguredFlag = [defaults objectForKey:NSUSERDEFAULT_READERCONFIGURED];
    if(readerConfiguredFlag != nil && [readerConfiguredFlag isEqualToString:@"true"]) {
        if(storedDeviceSerialNumber != nil && [storedDeviceSerialNumber isEqualToString:deviceSerialNumber]) {
            [self notifyInfo:READER_CONFIGURED_MESSAGE];
            return;
        }
    }
    
    [self initClock];
    [self increaseStandByTime];

    ClearentConfigFetcher *clearentConfigFetcher = [[ClearentConfigFetcher alloc] init:[NSURLSession sharedSession] baseUrl:self.baseUrl deviceSerialNumber:deviceSerialNumber kernelVersion:kernelVersion publicKey:self.publicKey];
    
    ClearentConfigFetcherResponse clearentConfigFetcherResponse = ^(NSDictionary *json) {
        if(json != nil) {
            [self notifyInfo:@"Retrieved configuration"];
            [self configure:json];
        } else {
            [self notifyError:@"Device failed to retrieve configuration"];
        }
    };
    
    [clearentConfigFetcher fetchConfiguration: clearentConfigFetcherResponse];
}

- (void) configure: (NSDictionary*) jsonConfiguration {
    ClearentConfiguration *clearentConfiguration = [[ClearentConfiguration alloc] initWithJson:jsonConfiguration];
    ClearentEmvConfigurator *clearentEmvConfigurator = [[ClearentEmvConfigurator alloc] initWithIdtechSharedController:self->_sharedController];
    NSString *readerConfigurationMessage = [clearentEmvConfigurator configure:clearentConfiguration];
    [self notifyInfo:readerConfigurationMessage];
    self.configured = YES;
}

-(void) initClock{
    int clockRt = [self initDateAndTime];
    if(clockRt != CLOCK_CONFIGURATION_SUCCESS) {
       [self notifyError:@"Failed to configure device clock"];
    }
}

- (void) notifyInfo:(NSString*)message {
    [Teleport logInfo:message];
    [self.callbackObject performSelector:self.selector withObject:message];
}

- (void) notifyError:(NSString*)message {
    [Teleport logError:message];
    [self.callbackObject performSelector:self.selector withObject:message];
}

- (int) initDateAndTime {
    RETURN_CODE dateRt = [self initClockDate];
    RETURN_CODE timeRt = [self initClockTime];
    if (RETURN_CODE_DO_SUCCESS == dateRt && RETURN_CODE_DO_SUCCESS == timeRt) {
        [Teleport logInfo:@"Clock Initialized"];
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
    
-(void) increaseStandByTime{
    NSData* response;
    RETURN_CODE increaseStandByTimeRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0xF0 subCommand:0x00 data:[IDTUtility hexToData:@"053C"] response:&response];
    if(RETURN_CODE_DO_SUCCESS != increaseStandByTimeRt) {
        [self notifyError:@"Failed to increase stand by time to 60 seconds"];
    } else {
        [Teleport logInfo:@"Stand by time increased to 60 seconds"];
    }
}
    
@end
