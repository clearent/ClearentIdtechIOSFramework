//
//  ClearentContactlessConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 9/17/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IDTech/IDT_VP3300.h>
#import "ClearentConfiguration.h"

typedef NS_ENUM(NSUInteger, CONTACTLESS_CONFIGURATION_RETURN_CODE) {
    CONTACTLESS_CONFIGURATION_SUCCESS = 0,
    CONTACTLESS_CONFIGURATION_FAILED = 1,
    CONTACTLESS_CAPKS_FAILED = 2,
    REQUIRED_CONTACTLESS_TAG = 3,
    REQUIRED_9F06_CONTACTLESS_TAG = 4,
    FAILED_TO_RETRIEVE_AIDS_LIST = 5,
    FAILED_TO_REMOVE_UNSUPPORTED_AID = 6,
    FAILED_TO_REMOVE_UNSUPPORTED_GROUP = 7,
    NO_SUPPORTED_AIDS_PROVIDED = 8,
    NO_SUPPORTED_GROUPS_PROVIDED = 9,
    NO_AIDS_PROVIDED = 10,
    CONTACTLESS_AIDS_FAILED = 11,
    CONTACTLESS_GROUP_CONFIGURATION_FAILED = 12,
    CONTACTLESS_DEVICE_IS_DISCONNECTED = 13,
    CONTACTLESS_CONFIGURATION_RETURN_CODE_UNKNOWN = NSUIntegerMax
};

@interface ClearentContactlessConfigurator : NSObject
  @property (nonatomic) CONTACTLESS_CONFIGURATION_RETURN_CODE contactlessConfigurationReturnCode;
- (CONTACTLESS_CONFIGURATION_RETURN_CODE) removeUnsupportedAids:(NSArray*) contactlessSupportedAids sharedController:(IDT_VP3300*) sharedController;
- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureGroups:(NSDictionary*) contactlessGroups sharedController:(IDT_VP3300*) sharedController;
- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureAids:(NSDictionary*) contactlessAids sharedController:(IDT_VP3300*) sharedController;
- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureCapks:(NSDictionary*) contactlessCapks sharedController:(IDT_VP3300*) sharedController;
+ (NSString*) getReturnCodeDisplayName: (int) returnCode;
@end

