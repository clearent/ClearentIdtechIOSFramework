//
//  ClearentConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConfigurator.h"

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
    if(self.isConfigured) {
        [self notify:READER_CONFIGURED_MESSAGE];
        return;
    }
    if(deviceSerialNumber  == nil) {
        [self notify:@"Connect device"];
        return;
    }
    if(self.baseUrl == nil) {
        [self notify:@"Configuration url is required for device configuration"];
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedDeviceSerialNumber = [defaults objectForKey:NSUSERDEFAULT_DEVICESERIALNUMBER];
    NSString *readerConfiguredFlag = [defaults objectForKey:NSUSERDEFAULT_READERCONFIGURED];
    if(readerConfiguredFlag != nil && [readerConfiguredFlag isEqualToString:@"true"]) {
        if(storedDeviceSerialNumber != nil && [storedDeviceSerialNumber isEqualToString:deviceSerialNumber]) {
            [self notify:READER_CONFIGURED_MESSAGE];
            return;
        }
    }
    
    [self initClock];

    ClearentConfigFetcher *clearentConfigFetcher = [[ClearentConfigFetcher alloc] init:[NSURLSession sharedSession] baseUrl:self.baseUrl deviceSerialNumber:deviceSerialNumber kernelVersion:kernelVersion publicKey:self.publicKey];
    
    ClearentConfigFetcherResponse clearentConfigFetcherResponse = ^(NSDictionary *json) {
        if(json != nil) {
            [self configure:json];
        } else {
            [self notify:@"Device failed to retrieve configuration"];
        }
    };
    
    [clearentConfigFetcher fetchConfiguration: clearentConfigFetcherResponse];
}

- (void) configure: (NSDictionary*) jsonConfiguration {
    ClearentConfiguration *clearentConfiguration = [[ClearentConfiguration alloc] initWithJson:jsonConfiguration];
    ClearentEmvConfigurator *clearentEmvConfigurator = [[ClearentEmvConfigurator alloc] initWithIdtechSharedController:self->_sharedController];
    NSString *readerConfigurationMessage = [clearentEmvConfigurator configure:clearentConfiguration];
    [self notify:readerConfigurationMessage];
    self.configured = YES;
}

-(void) initClock{
    ClearentClockConfigurator *clearentClockConfigurator = [[ClearentClockConfigurator alloc] initWithIdtechSharedController:_sharedController];
    int clockRt = [clearentClockConfigurator initClock];
    if(clockRt != CLOCK_CONFIGURATION_SUCCESS) {
       [self notify:@"Failed to configure device clock"];
    }
}

- (void) notify:(NSString*)message {
    [self.callbackObject performSelector:self.selector withObject:message];
}

@end
