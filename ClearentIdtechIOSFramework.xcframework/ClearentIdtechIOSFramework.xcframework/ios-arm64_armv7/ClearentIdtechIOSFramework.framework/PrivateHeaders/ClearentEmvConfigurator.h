//
//  ClearentEmvConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>

#import <IDTech/IDT_VP3300.h>
#import "ClearentConfiguration.h"

typedef enum{
    TERMINAL_MAJOR_5C_FAILED,
    EMV_CONFIGURATION_SUCCESS,
    MAJOR_TAGS_RETRIEVE_FAILED,
    CONTACT_MAJOR_TAGS_UPDATE_FAILED,
    CALL_FAILED,
    JSON_SERIALIZATION_FAILED,
    NO_PAYLOAD,
    NO_MOBILE_DEVICE,
    CONTACT_FAILED,
    CONTACT_CAPKS_FAILED,
    CONTACT_DEVICE_IS_DISCONNECTED
}CONFIGURATION_ERROR_CODE;

@interface ClearentEmvConfigurator : NSObject

    @property (nonatomic) IDT_VP3300 *sharedController;

    - (id)initWithIdtechSharedController:(IDT_VP3300*) sharedController;
    - (CONFIGURATION_ERROR_CODE) configureMajorTags;
    - (CONFIGURATION_ERROR_CODE) configureContactAids:(NSDictionary*) contactAids;
    - (CONFIGURATION_ERROR_CODE) configureContactCapks:(NSDictionary*) contactCapks;

@end
