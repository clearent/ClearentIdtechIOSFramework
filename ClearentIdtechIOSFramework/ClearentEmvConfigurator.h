//
//  ClearentEmvConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "IDTech/IDT_VP3300.h"
#import "IDTech/IDTUtility.h"

typedef enum{
    EMV_CONFIGURATION_SUCCESS,
    MAJOR_TAGS_RETRIEVE_FAILED,
    CONTACT_MAJOR_TAGS_UPDATE_FAILED,
    CALL_FAILED,
    JSON_SERIALIZATION_FAILED,
    NO_PAYLOAD,
    NO_MOBILE_DEVICE,
    CONTACT_FAILED,
    CONTACT_CAPKS_FAILED
}CONFIGURATION_ERROR_CODE;

@interface ClearentEmvConfigurator : NSObject
+ (NSString*) configure:(NSDictionary*)clearentConfiguration;
@end
