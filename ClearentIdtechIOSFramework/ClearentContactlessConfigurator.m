//
//  ClearentContactlessConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 9/17/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentContactlessConfigurator.h"
#import <IDTech/IDTUtility.h>
#import "ClearentLumberjack.h"

static NSString *const EMV_DIP_ENTRY_MODE_TAG = @"05";
static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";
static NSString *const ERROR_MSG = @"Failed to configure reader. Confirm internet access and try reconnecting. If this does not work contact support.";
static NSString *const CONTACTLESS_CONFIGURED_MESSAGE = @"Reader configured for contactless";

@implementation ClearentContactlessConfigurator

- (CONTACTLESS_CONFIGURATION_RETURN_CODE) removeUnsupportedAids:(NSArray*) contactlessSupportedAids sharedController:(IDT_VP3300*) sharedController {
    if(contactlessSupportedAids == nil) {
        return NO_SUPPORTED_AIDS_PROVIDED;
    }
    CONTACTLESS_CONFIGURATION_RETURN_CODE contactlessConfigurationReturnCode = CONTACTLESS_CONFIGURATION_SUCCESS;
    NSArray *configuredAidsList;
    RETURN_CODE retrieveAIDListReturnCode = [sharedController ctls_retrieveAIDList:&configuredAidsList];
    if (RETURN_CODE_DO_SUCCESS == retrieveAIDListReturnCode) {
        [ClearentLumberjack logInfo:@"Remove unsupported contactless aids"];
        for(NSData *configuredContactlessAid in configuredAidsList) {
            NSString *aidtoRemove = [IDTUtility dataToHexString:configuredContactlessAid];
            if(![contactlessSupportedAids containsObject:aidtoRemove]) {
                if(![sharedController isConnected]) {
                    return CONTACTLESS_DEVICE_IS_DISCONNECTED;
                }
                RETURN_CODE removeApplicationDataReturnCode = [[IDT_VP3300 sharedController] ctls_removeApplicationData:aidtoRemove];
                if (RETURN_CODE_DO_SUCCESS == removeApplicationDataReturnCode) {
                    NSLog(@"Removed unsupported from contactless %@",[NSString stringWithFormat:@"aid %@", configuredContactlessAid]);
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Removed unsupported contactless aid %@", configuredContactlessAid]];
                } else {
                    NSLog(@"Failed to remove unsupported contactless %@",[NSString stringWithFormat:@"aid %@", configuredContactlessAid]);
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Failed to remove unsupported contactless aid %@", configuredContactlessAid]];
                    contactlessConfigurationReturnCode = FAILED_TO_REMOVE_UNSUPPORTED_AID;
                }
            }
        }
    } else {
        [ClearentLumberjack logInfo:@"Failed to retrieve contactless aids list"];
        return FAILED_TO_RETRIEVE_AIDS_LIST;
    }
    return contactlessConfigurationReturnCode;
}

- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureGroups:(NSDictionary*) contactlessGroups sharedController:(IDT_VP3300*) sharedController {
    if(contactlessGroups == nil) {
        return NO_SUPPORTED_GROUPS_PROVIDED;
    }
     bool allSuccessful = true;
    
     for(NSDictionary *contactlessGroup in contactlessGroups) {
        NSString *name = [contactlessGroup objectForKey:@"name"];
        NSString *group = [contactlessGroup objectForKey:@"group"];
        NSString *tlvValues = [contactlessGroup objectForKey:@"configuration-tlv"];
        
        NSData *groupTlvData = [IDTUtility hexToData:tlvValues];
        if(![sharedController isConnected]) {
            return CONTACTLESS_DEVICE_IS_DISCONNECTED;
        }
        RETURN_CODE returnCode = [sharedController ctls_setConfigurationGroup:groupTlvData];
        if (RETURN_CODE_DO_SUCCESS == returnCode) {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contactless group added/updated  name %@,group %@", name, group]];
            NSLog(@"contactless group added/updated %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
        } else {
            allSuccessful = false;
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contactless group added/updated failed name %@,group %@", name, group]];
            NSLog(@"contactless group added/updated failed %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
        }
     }
    
    if(!allSuccessful) {
        return CONTACTLESS_GROUP_CONFIGURATION_FAILED;
    }
    
    return CONTACTLESS_CONFIGURATION_SUCCESS;
}

- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureAids:(NSDictionary*) contactlessAids sharedController:(IDT_VP3300*) sharedController {
    if(contactlessAids == nil) {
        return NO_AIDS_PROVIDED;
    }
    bool allSuccessful = true;
    for(NSDictionary *contactlessAid in contactlessAids) {
        NSString *name = [contactlessAid objectForKey:@"name"];
        NSString *configurationTlv = [contactlessAid objectForKey:@"configuration-tlv"];
        NSData *setApplicationData2 = [IDTUtility hexToData:configurationTlv.uppercaseString];
        if(![sharedController isConnected]) {
            return CONTACTLESS_DEVICE_IS_DISCONNECTED;
        }
        int setApplicationDataRt2 = [[IDT_VP3300 sharedController] ctls_setApplicationData:setApplicationData2];
        if (RETURN_CODE_DO_SUCCESS == setApplicationDataRt2) {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contactless aid applied  name %@", name]];
            NSLog(@"contactless aid applied %@",[NSString stringWithFormat:@"name %@", name]);
        } else {
            allSuccessful = false;
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:setApplicationDataRt2];
            NSLog(@"contactless setApplicationData unsuccessful %@",[NSString stringWithFormat:@"name %@,error %@", name, error]);
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contactless add applied failed name %@", name]];
            NSLog(@"contactless aid applied   failed %@",[NSString stringWithFormat:@"name %@", name]);
        }
    }
    
    if(!allSuccessful) {
        return CONTACTLESS_AIDS_FAILED;
    }
    
     return CONTACTLESS_CONFIGURATION_SUCCESS;
}

- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureCapks:(NSDictionary*) contactlessCapks sharedController:(IDT_VP3300*) sharedController {
    RETURN_CODE removeCapkRt = [[IDT_VP3300 sharedController] ctls_removeAllCAPK];
    if (RETURN_CODE_DO_SUCCESS == removeCapkRt) {
        NSLog(@"Successfully removed all currently configured contactless capk");
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Successfully removed all currently configured contactless capk"]];
    } else {
        return CONTACTLESS_CAPKS_FAILED;
    }
    
    bool allSuccessful = true;
    for(NSDictionary *contactlessCapk in contactlessCapks) {
        NSString *name = [contactlessCapk objectForKey:@"name"];
        NSString *rid = [contactlessCapk objectForKey:@"rid"];
        NSString *keyIndex = [contactlessCapk objectForKey:@"key-index"];
        NSString *hashAlgorithm = [contactlessCapk objectForKey:@"hash-algorithm"];
        NSString *hashValue = [contactlessCapk objectForKey:@"hash-value"];
        NSString *modulus = [contactlessCapk objectForKey:@"modulus"];
        NSString *modulusLength = [contactlessCapk objectForKey:@"big-endian-modulus-length"];
        NSString *encryptionAlgorithm = [contactlessCapk objectForKey:@"encryption-algorithm"];
        NSString *keyExponent = [contactlessCapk objectForKey:@"key-exponent"];
        NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,keyIndex,hashAlgorithm,encryptionAlgorithm,hashValue,keyExponent,modulusLength,modulus, nil];
        NSString* combined = [testKeyArray componentsJoinedByString:@""];
        NSData* capk = [IDTUtility hexToData:combined];
        if(![sharedController isConnected]) {
            return CONTACTLESS_DEVICE_IS_DISCONNECTED;
        }
        RETURN_CODE capkRt = [sharedController ctls_setCAPK:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            NSLog(@"contactless capk loaded %@",[NSString stringWithFormat:@"%@", name]);
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contactless capk loaded name %@", name]];
        } else{
            NSString *error =[sharedController device_getResponseCodeString:capkRt];
            NSLog(@"contactless capk failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"contactless capk failed to load name %@,error %@", name, error]];
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        return CONTACTLESS_CAPKS_FAILED;
    }
    return CONTACTLESS_CONFIGURATION_SUCCESS;
}

+ (NSString*) getReturnCodeDisplayName:(int) returnCode {
    switch(returnCode) {
        case CONTACTLESS_CONFIGURATION_SUCCESS:
            return @"Contactless Configuration Success";
        case CONTACTLESS_CONFIGURATION_FAILED:
            return @"Contactless Configuration Failed";
        case CONTACTLESS_CAPKS_FAILED:
            return @"Contactless Public keys Failed";
        case REQUIRED_CONTACTLESS_TAG:
            return @"Contactless Tag required";
        case REQUIRED_9F06_CONTACTLESS_TAG:
            return @"Contactless 9F06 Tag requried";
        case FAILED_TO_RETRIEVE_AIDS_LIST:
            return @"Contactless failed to retrieve AIDs list from reader";
        case FAILED_TO_REMOVE_UNSUPPORTED_AID:
            return @"Failed to remove unsupported Aid";
        case FAILED_TO_REMOVE_UNSUPPORTED_GROUP:
            return @"Failed to remove unsupported group";
        case NO_SUPPORTED_AIDS_PROVIDED:
            return @"No supported Aids provided";
        case NO_SUPPORTED_GROUPS_PROVIDED:
            return @"No supported groups provided";
        case NO_AIDS_PROVIDED:
            return @"No contactless application ids provided";
        case CONTACTLESS_AIDS_FAILED:
            return @"Configuring Contactless Application Ids failed";
        case CONTACTLESS_GROUP_CONFIGURATION_FAILED:
            return @"Configuring Groups failed";
    }
    return @"Unknown contactless error";
}

@end



