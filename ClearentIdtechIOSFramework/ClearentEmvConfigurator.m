//
//  ClearentEmvConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentEmvConfigurator.h"
#import <IDTech/IDTUtility.h>
#import "Teleport.h"

static NSString *const EMV_DIP_ENTRY_MODE_TAG = @"05";
static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";
static NSString *const ERROR_MSG = @"Failed to configure reader. Confirm internet access and try reconnecting. If this does not work contact support.";
static NSString *const READER_CONFIGURED_MESSAGE = @"Reader configured and ready";

@implementation ClearentEmvConfigurator

- (instancetype)initWithIdtechSharedController:(IDT_VP3300*) sharedController {
    self = [super init];
    if (self) {
        _sharedController = sharedController;
    }
    return self;
}

- (CONFIGURATION_ERROR_CODE) configureMajorTags {
    CONFIGURATION_ERROR_CODE configureMajorTagsReturnCode = EMV_CONFIGURATION_SUCCESS;
    int terminalMajorConfiguration = 5;
    [NSThread sleepForTimeInterval:0.3f];
    if(![_sharedController isConnected]) {
        return CONTACT_DEVICE_IS_DISCONNECTED;
    }
    RETURN_CODE emvSetTerminalMajorConfigurationRt = [_sharedController emv_setTerminalMajorConfiguration:terminalMajorConfiguration];
    if (RETURN_CODE_DO_SUCCESS == emvSetTerminalMajorConfigurationRt) {
        [Teleport logInfo:@"Contact Terminal Major Set to 5"];
        NSLog(@"Contact Terminal Major Set to 5");
    } else {
        NSString *error =[_sharedController device_getResponseCodeString:emvSetTerminalMajorConfigurationRt];
        [Teleport logError:[NSString stringWithFormat:@"Failed to set terminal to 5 %@", error]];
        NSLog(@"Failed to set terminal to 5 %@",[NSString stringWithFormat:@"%@", error]);
        
        [NSThread sleepForTimeInterval:0.8f];
        if(![_sharedController isConnected]) {
            [Teleport logError:@"Reader is disconnected prior to trying set the major configuration a second time"];
            return CONTACT_DEVICE_IS_DISCONNECTED;
        } else {
            RETURN_CODE emvSetTerminalMajorConfigurationRt = [_sharedController emv_setTerminalMajorConfiguration:terminalMajorConfiguration];
            if (RETURN_CODE_DO_SUCCESS != emvSetTerminalMajorConfigurationRt) {
                [Teleport logError:@"Tried to set the major configuration a second time but it failed"];
                return TERMINAL_MAJOR_5C_FAILED;
            }
        }
    }
    
    NSString *defaultTlvData = @"5f3601029f1a0208409f3501219f33036028c89f4005f000f0a0019f1e085465726d696e616c9f150212349f160f3030303030303030303030303030309f1c0838373635343332319f4e2231303732312057616c6b65722053742e20437970726573732c204341202c5553412edf260101df1008656e667265737a68df110100df270100dfee150101dfee160100dfee170105dfee180180dfee1e08d09c20d0c41e1400dfee1f0180dfee1b083030303130353030dfee20013cdfee21010adfee2203323c3c";
    NSData *defaultTlvTags = [IDTUtility hexToData:defaultTlvData.uppercaseString];
    if(![_sharedController isConnected]) {
        return CONTACT_DEVICE_IS_DISCONNECTED;
    }
    RETURN_CODE setDefaultRt = [_sharedController emv_setTerminalData:[IDTUtility TLVtoDICT:defaultTlvTags]];
    if (RETURN_CODE_DO_SUCCESS == setDefaultRt) {
        [Teleport logInfo:@"Emv Entry mode changed from 07 to 05"];
    } else{
        [Teleport logError:@"Failed to retrieve major tags"];
        configureMajorTagsReturnCode = MAJOR_TAGS_RETRIEVE_FAILED;
    }
    
    return configureMajorTagsReturnCode;
}

- (CONFIGURATION_ERROR_CODE) configureContactAids:(NSDictionary*) contactAids {
    CONFIGURATION_ERROR_CODE configureContactCapksReturnCode = EMV_CONFIGURATION_SUCCESS;
    bool allSuccessful = true;
    for(NSDictionary *contactAid in contactAids) {
        NSString *name = [contactAid objectForKey:@"name"];
        NSDictionary *values = [contactAid objectForKey:@"aid-values"];
        if(![_sharedController isConnected]) {
            return CONTACT_DEVICE_IS_DISCONNECTED;
        }
        RETURN_CODE rt = [_sharedController emv_setApplicationData:name configData:values];
        if (RETURN_CODE_DO_SUCCESS == rt) {
            [Teleport logInfo:[NSString stringWithFormat:@"contact aid loaded %@", name]];
            NSLog(@"contact aid loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[_sharedController device_getResponseCodeString:rt];
            [Teleport logError:[NSString stringWithFormat:@"contact aid failed to load %@,%@", name, error]];
            NSLog(@"contact aid failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        configureContactCapksReturnCode = CONTACT_FAILED;
    }
    return configureContactCapksReturnCode;
}

- (CONFIGURATION_ERROR_CODE) configureContactCapks:(NSDictionary*) contactCapks {
    
    CONFIGURATION_ERROR_CODE configureContactCapksReturnCode = EMV_CONFIGURATION_SUCCESS;
    
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
        if(![_sharedController isConnected]) {
            return CONTACT_DEVICE_IS_DISCONNECTED;
        }
        RETURN_CODE capkRt = [_sharedController emv_setCAPKFile:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            [Teleport logInfo:[NSString stringWithFormat:@"contact capk loaded %@", name]];
            NSLog(@"contact capk loaded %@",[NSString stringWithFormat:@"%@", name]);
            [Teleport logInfo:[NSString stringWithFormat:@"contact capk loaded  %@", name]];
        } else{
            NSString *error =[_sharedController device_getResponseCodeString:capkRt];
            [Teleport logError:[NSString stringWithFormat:@"contact capk failed to load %@,%@", name, error]];
            NSLog(@"contact capk failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        configureContactCapksReturnCode = CONTACT_CAPKS_FAILED;
    }
    return configureContactCapksReturnCode;
}

@end


