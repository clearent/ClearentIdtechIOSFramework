//
//  ClearentEmvConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentEmvConfigurator.h"

static NSString *const EMV_DIP_ENTRY_MODE_TAG = @"05";
static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";
static NSString *const ERROR_MSG = @"Failed to configure VIVOpay. Confirm internet access and try reconnecting. If this does not work contact support.";

@implementation ClearentEmvConfigurator

+ (NSString*) configure:(NSDictionary*) clearentConfiguration {
    NSString *allErrors = @"";
    int majorTagsRt = self.configureMajorTags;
    if(majorTagsRt != EMV_CONFIGURATION_SUCCESS) {
        allErrors = [NSString stringWithFormat:@"%@%@", allErrors, [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]]];
    }
    if(clearentConfiguration != nil) {
        int clearentConfigurationRt = [self configureUsingClearentConfiguration:clearentConfiguration];
        if(clearentConfigurationRt != EMV_CONFIGURATION_SUCCESS) {
            allErrors = [NSString stringWithFormat:@"%@%@", allErrors, [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",clearentConfigurationRt]]];
        }
    } else {
        allErrors = [NSString stringWithFormat:@"%@%@", allErrors, [NSString stringWithFormat:@"%@,%@", ERROR_MSG, @"Skipped configuring VIVOpay because clearent configuration was not found"]];
    }
    if(![allErrors isEqualToString:@""]) {
        return allErrors;
    }
    return @"VIVOpay configured and ready";
}

+ (int) configureMajorTags {
    NSMutableDictionary *tags;
    
    [[IDT_VP3300 sharedController] emv_setTerminalMajorConfiguration:5];
    
    RETURN_CODE retrieveTerminalDataRt = [[IDT_VP3300 sharedController] emv_retrieveTerminalData:&tags];
    if (RETURN_CODE_DO_SUCCESS == retrieveTerminalDataRt) {
        [tags setObject:[IDTUtility hexToData:@"D0DC20D0C41E1400"] forKey:@"DFEE1E"];
        [tags setObject:[IDTUtility hexToData:EMV_DIP_ENTRY_MODE_TAG] forKey:IDTECH_EMV_ENTRY_MODE_EMV_TAG];
    } else{
        return MAJOR_TAGS_RETRIEVE_FAILED;
    }
    RETURN_CODE setTerminalDateRt = [[IDT_VP3300 sharedController] emv_setTerminalData:tags];
    if (RETURN_CODE_DO_SUCCESS == setTerminalDateRt) {
        NSLog(@"Contact Major tags set");
    } else{
        return CONTACT_MAJOR_TAGS_UPDATE_FAILED;
    }
    return EMV_CONFIGURATION_SUCCESS;
}

+ (int) configureUsingClearentConfiguration:(NSDictionary*) clearentConfiguration {
    NSDictionary *payload = [clearentConfiguration objectForKey:@"payload"];
    if(payload == nil) {
        return NO_PAYLOAD;
    }
    NSDictionary *mobileDevice = [payload objectForKey:@"mobile-device"];
    if(payload == nil) {
        return NO_MOBILE_DEVICE;
    }
    NSDictionary *contactAids = [mobileDevice objectForKey:@"contact-aids"];
    if(contactAids != nil) {
        int contactAidsRt = [self configureContactAids:contactAids];
        if(contactAidsRt != EMV_CONFIGURATION_SUCCESS) {
            return contactAidsRt;
        }
    }
    
    NSDictionary *publicKeys = [mobileDevice objectForKey:@"ca-public-keys"];
    if(publicKeys != nil) {
        int publicKeysRt  = [self configureContactCapks:publicKeys];
        if(publicKeysRt != EMV_CONFIGURATION_SUCCESS) {
            return publicKeysRt;
        }
    }
    return EMV_CONFIGURATION_SUCCESS;
}

+ (int) configureContactAids:(NSDictionary*) contactAids {
    bool allSuccessful = true;
    for(NSDictionary *contactAid in contactAids) {
        NSString *name = [contactAid objectForKey:@"name"];
        NSDictionary *values = [contactAid objectForKey:@"aid-values"];
        RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_setApplicationData:name configData:values];
        if (RETURN_CODE_DO_SUCCESS == rt) {
            NSLog(@"contact aid loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:rt];
            NSLog(@"contact aid failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        return CONTACT_FAILED;
    }
    return EMV_CONFIGURATION_SUCCESS;
}

+ (int) configureContactCapks:(NSDictionary*) contactCapks {
    bool allSuccessful = true;
    for(NSDictionary *contactCapk in contactCapks) {
        NSString *name = [contactCapk objectForKey:@"name"];
        NSString *rid = [contactCapk objectForKey:@"rid"];
        NSString *keyIndex = [contactCapk objectForKey:@"key-index"];
        NSString *hashAlgorithm = [contactCapk objectForKey:@"hash-algorithm"];
        NSString *hashValue = [contactCapk objectForKey:@"hash-value"];
        NSString *modulus = [contactCapk objectForKey:@"modulus"];
        NSString *modulusLength = [contactCapk objectForKey:@"big-endian-modulus-length"];
        NSString *encryptionAlgorithm = [contactCapk objectForKey:@"encryption-algorithm"];
        NSString *keyExponent = [contactCapk objectForKey:@"key-exponent"];
        
        NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,keyIndex,hashAlgorithm,encryptionAlgorithm,hashValue,keyExponent,modulusLength,modulus, nil];
        
        NSString* combined = [testKeyArray componentsJoinedByString:@""];
        
        NSData* capk = [IDTUtility hexToData:combined];
        RETURN_CODE capkRt = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            NSLog(@"contact capk loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:capkRt];
            NSLog(@"contact capk failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        return CONTACT_CAPKS_FAILED;
    }
    return EMV_CONFIGURATION_SUCCESS;
}
@end


