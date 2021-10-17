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
#import "ClearentLumberjack.h"

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
        [ClearentLumberjack logInfo:@"Contact Terminal Major Set to 5"];
        NSLog(@"Contact Terminal Major Set to 5");
    } else {
        NSString *error =[_sharedController device_getResponseCodeString:emvSetTerminalMajorConfigurationRt];
        [ClearentLumberjack logError:[NSString stringWithFormat:@"Failed to set terminal to 5 %@", error]];
        NSLog(@"Failed to set terminal to 5 %@",[NSString stringWithFormat:@"%@", error]);
        
        [NSThread sleepForTimeInterval:0.8f];
        if(![_sharedController isConnected]) {
            [ClearentLumberjack logError:@"Reader is disconnected prior to trying set the major configuration a second time"];
            return CONTACT_DEVICE_IS_DISCONNECTED;
        } else {
            RETURN_CODE emvSetTerminalMajorConfigurationRt = [_sharedController emv_setTerminalMajorConfiguration:terminalMajorConfiguration];
            if (RETURN_CODE_DO_SUCCESS != emvSetTerminalMajorConfigurationRt) {
                [ClearentLumberjack logError:@"Tried to set the major configuration a second time but it failed"];
                return TERMINAL_MAJOR_5C_FAILED;
            }
        }
    }
    
    NSString *defaultTlvData = @"5f3601029f1a0208409f3501219f33036028c89f4005f000f0a0019f1e085465726d696e616c9f150212349f160f3030303030303030303030303030309f1c0838373635343332319f4e0146df260101df1008656e667265737a68df110100df270100dfee150101dfee160100dfee170105dfee180180dfee1e08d08c20d0c41e1400dfee1f0180dfee1b083030303130353030dfee20013cdfee21010adfee2203323c3c";
    NSData *defaultTlvTags = [IDTUtility hexToData:defaultTlvData.uppercaseString];
    if(![_sharedController isConnected]) {
        return CONTACT_DEVICE_IS_DISCONNECTED;
    }
    RETURN_CODE setDefaultRt = [_sharedController emv_setTerminalData:[IDTUtility TLVtoDICT:defaultTlvTags]];
    if (RETURN_CODE_DO_SUCCESS == setDefaultRt) {
        [ClearentLumberjack logInfo:@"Emv Entry mode changed from 07 to 05"];
    } else{
        [ClearentLumberjack logError:@"Failed to retrieve major tags"];
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
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contact aid loaded %@", name]];
            NSLog(@"contact aid loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[_sharedController device_getResponseCodeString:rt];
            [ClearentLumberjack logError:[NSString stringWithFormat:@"contact aid failed to load %@,%@", name, error]];
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
    
    bool allSuccessful = true;
    
    NSArray *capkList;
    RETURN_CODE emv_retrieveCAPKListRt = [_sharedController  emv_retrieveCAPKList:&capkList];
    if (RETURN_CODE_DO_SUCCESS == emv_retrieveCAPKListRt) {
        NSLog(@"Successfully retrieved list of configured contact capk");
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Successfully removed all currently configured contact capk"]];
        for(NSString *nameAndKeyIndex in capkList) {
            NSString *name = [nameAndKeyIndex substringToIndex:[nameAndKeyIndex length] - 2];
            NSString *keyIndex = [nameAndKeyIndex substringFromIndex: [nameAndKeyIndex length] - 2];
            NSLog(@"contact capk name %@",[NSString stringWithFormat:@"%@", name]);
            NSLog(@"contact capk keyindex %@",[NSString stringWithFormat:@"%@", keyIndex]);
            RETURN_CODE emv_removeCAPKRt = [_sharedController  emv_removeCAPK:name index:keyIndex];
            if (RETURN_CODE_DO_SUCCESS == emv_removeCAPKRt) {
                NSLog(@"contact capk removed %@",[NSString stringWithFormat:@"%@", nameAndKeyIndex]);
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contact capk removed %@", nameAndKeyIndex]];
            } else {
                NSLog(@"contact capk not removed %@",[NSString stringWithFormat:@"%@", nameAndKeyIndex]);
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contact capk not removed %@", nameAndKeyIndex]];
                allSuccessful = false;
            }
        }
    } else{
        NSLog(@"Failed to get list of contact capk");
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Failed to get list of contact capk"]];
        allSuccessful = false;
    }
    
    if(!allSuccessful) {
        return CONTACT_CAPKS_FAILED;
    }
    
    CONFIGURATION_ERROR_CODE configureContactCapksReturnCode = EMV_CONFIGURATION_SUCCESS;
    
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
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contact capk loaded %@", name]];
            NSLog(@"contact capk loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[_sharedController device_getResponseCodeString:capkRt];
            [ClearentLumberjack logError:[NSString stringWithFormat:@"contact capk failed to load %@,%@", name, error]];
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


