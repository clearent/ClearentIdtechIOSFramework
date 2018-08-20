//
//  ClearentConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentClockConfigurator.h"
#import "ClearentEmvConfigurator.h"
#import "ClearentConfiguration.h"
#import "ClearentConfigFetcher.h"

@interface ClearentConfigurator : NSObject

    @property(nonatomic) NSString *baseUrl;
    @property(nonatomic) NSString *publicKey;
    @property(nonatomic) SEL selector;
    @property(nonatomic) id callbackObject;
    @property (assign, getter=isConfigured) BOOL configured;
    @property (nonatomic) IDT_VP3300 *sharedController;

    - (id) init : (NSString*)clearentBaseUrl
        publicKey:(NSString*)publicKey
        callbackObject:(id)callbackObject
        withSelector:(SEL)selector
        sharedController:(IDT_VP3300*) sharedController;
    - (void) configure: (NSString*)kernelVersion deviceSerialNumber:(NSString*) deviceSerialNumber;
    - (void) configure: (NSDictionary*) jsonConfiguration;
    - (void) notify:(NSString*)message;

@end
