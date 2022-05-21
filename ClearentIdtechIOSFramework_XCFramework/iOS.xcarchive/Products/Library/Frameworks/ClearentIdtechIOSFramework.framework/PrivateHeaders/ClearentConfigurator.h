//
//  ClearentConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentEmvConfigurator.h"
#import "ClearentConfiguration.h"
#import "ClearentConfigFetcher.h"

typedef enum{
    CLOCK_CONFIGURATION_SUCCESS,
    CLOCK_FAILED,
}CLOCK_CONFIGURATION_ERROR_CODE;

@interface ClearentConfigurator : NSObject

    @property(nonatomic) NSString *baseUrl;
    @property(nonatomic) NSString *publicKey;
    @property(nonatomic) SEL selector;
    @property(nonatomic) id callbackObject;
    @property (nonatomic) IDT_VP3300 *sharedController;

    - (id) init : (NSString*)clearentBaseUrl
        publicKey:(NSString*)publicKey
        callbackObject:(id)callbackObject
        withSelector:(SEL)selector
        sharedController:(IDT_VP3300*) sharedController;

    -(void) configure: (NSString*)kernelVersion  deviceSerialNumber:(NSString*) deviceSerialNumber autoConfiguration:(BOOL) autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration;
    - (void) configure: (NSDictionary*) jsonConfiguration autoConfiguration:(BOOL) autoConfiguration contactlessAutoConfiguration:(BOOL) contactlessAutoConfiguration deviceSerialNumber:(NSString*) deviceSerialNumber;
    - (void) notifyInfo:(NSString*)message;
    - (void) notifyError:(NSString*)message;
    - (NSData*) getClockDateAsYYYYMMDD;
    - (NSData*) getClockTimeAsHHMM;
    -(void) cacheConfiguredReader: (NSString*) deviceSerialNumber;
@end
