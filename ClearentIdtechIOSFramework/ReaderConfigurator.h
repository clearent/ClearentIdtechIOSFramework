//
//  ReaderConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 5/29/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    CONFIGURATION_SUCCESS,
    TIME_FAILED,
    DATE_FAILED,
    MAJOR_TAGS_RETRIEVE_FAILED,
    MAJOR_TAGS_UPDATE_FAILED,
    CALL_FAILED,
    JSON_SERIALIZATION_FAILED,
    NO_PAYLOAD,
    NO_MOBILE_DEVICE,
    REQUIRED_CONTACTLESS_TAG,
    CONTACT_FAILED,
    CONTACTLESS_FAILED,
    CONTACTLESS_NO_COMBINED_TLV,
    CONTACT_CAPKS_FAILED,
    CONTACTLESS_CAPKS_FAILED
}CONFIGURATION_ERROR_CODE;

@interface ReaderConfigurator : NSObject
+ (NSString*) configure:(NSDictionary*)clearentConfiguration;
@end
