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
static NSString *const ERROR_MSG = @"Failed to configure reader. Confirm internet access and try reconnecting. If this does not work contact support.";

@implementation ClearentEmvConfigurator

- (instancetype)initWithIdtechSharedController:(IDT_VP3300*) sharedController {
    self = [super init];
    if (self) {
        _sharedController = sharedController;
    }
    return self;
}

- (NSString*) configure:(ClearentConfiguration*) clearentConfiguration {
    NSString *allErrors = @"";
    int majorTagsRt = self.configureMajorTags;
    if(majorTagsRt != EMV_CONFIGURATION_SUCCESS) {
        allErrors = [NSString stringWithFormat:@"%@%@", allErrors, [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]]];
    }
    if(clearentConfiguration != nil && clearentConfiguration.isValid) {
        int clearentConfigurationRt = [self configureUsingClearentConfiguration:clearentConfiguration];
        if(clearentConfigurationRt != EMV_CONFIGURATION_SUCCESS) {
            allErrors = [NSString stringWithFormat:@"%@%@", allErrors, [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",clearentConfigurationRt]]];
        }
    } else {
        allErrors = [NSString stringWithFormat:@"%@%@", allErrors, [NSString stringWithFormat:@"%@,%@", ERROR_MSG, @"Skipped configuring reader because clearent configuration was not found"]];
    }
    if(![allErrors isEqualToString:@""]) {
        return allErrors;
    }
    return @"Reader configured and ready";
}

- (int) configureMajorTags {
    int terminalMajorConfiguration = 5;
    
    RETURN_CODE emvSetTerminalMajorConfigurationRt = [_sharedController emv_setTerminalMajorConfiguration:terminalMajorConfiguration];
    if (RETURN_CODE_DO_SUCCESS == emvSetTerminalMajorConfigurationRt) {
        NSLog(@"Contact Terminal Major Set to 5");
    } else {
        NSString *error =[_sharedController device_getResponseCodeString:emvSetTerminalMajorConfigurationRt];
        NSLog(@"Failed to set terminal to 5 %@",[NSString stringWithFormat:@"%@", error]);
        return TERMINAL_MAJOR_5C_FAILED;
    }
    
    NSString *defaultTlvData = @"5f3601029f1a0208409f3501219f33036028c89f4005f000f0a0019f1e085465726d696e616c9f150212349f160f3030303030303030303030303030309f1c0838373635343332319f4e2231303732312057616c6b65722053742e20437970726573732c204341202c5553412edf260101df1008656e667265737a68df110100df270100dfee150101dfee160100dfee170105dfee180180dfee1e08d09c20d0c41e1400dfee1f0180dfee1b083030303130353030dfee20013cdfee21010adfee2203323c3c";
    NSData *defaultTlvTags = [IDTUtility hexToData:defaultTlvData.uppercaseString];
    RETURN_CODE setDefaultRt = [_sharedController emv_setTerminalData:[IDTUtility TLVtoDICT:defaultTlvTags]];
    if (RETURN_CODE_DO_SUCCESS == setDefaultRt) {
        NSLog(@"Emv Entry mode changed from 07 to 05");
    } else{
        return MAJOR_TAGS_RETRIEVE_FAILED;
    }
    return EMV_CONFIGURATION_SUCCESS;
}

- (int) configureUsingClearentConfiguration:(ClearentConfiguration*) clearentConfiguration {
    int contactAidsRt = [self configureContactAids:clearentConfiguration.contactAids];
    if(contactAidsRt != EMV_CONFIGURATION_SUCCESS) {
        return contactAidsRt;
    }
    
    int publicKeysRt  = [self configureContactCapks:clearentConfiguration.publicKeys];
    if(publicKeysRt != EMV_CONFIGURATION_SUCCESS) {
        return publicKeysRt;
    }
    return EMV_CONFIGURATION_SUCCESS;
}

- (int) configureContactAids:(NSDictionary*) contactAids {
    bool allSuccessful = true;
    for(NSDictionary *contactAid in contactAids) {
        NSString *name = [contactAid objectForKey:@"name"];
        NSDictionary *values = [contactAid objectForKey:@"aid-values"];
        RETURN_CODE rt = [_sharedController emv_setApplicationData:name configData:values];
        if (RETURN_CODE_DO_SUCCESS == rt) {
            NSLog(@"contact aid loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[_sharedController device_getResponseCodeString:rt];
            NSLog(@"contact aid failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        return CONTACT_FAILED;
    }
    return EMV_CONFIGURATION_SUCCESS;
}

- (int) configureContactCapks:(NSDictionary*) contactCapks {
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
        RETURN_CODE capkRt = [_sharedController emv_setCAPKFile:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            NSLog(@"contact capk loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[_sharedController device_getResponseCodeString:capkRt];
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


