//
//  ReaderConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 5/29/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReaderConfigurator.h"
#import "IDTech/IDT_VP3300.h"
#import "IDTech/IDTUtility.h"

static NSString *const EMV_DIP_ENTRY_MODE_TAG = @"05";
static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";
static NSString *const ERROR_MSG = @"Failed to configure reader. Confirm internet access and try reconnecting reader. If this does not work contact support.";

@implementation ReaderConfigurator

+ (NSString*) configure:(NSDictionary*) clearentConfiguration {
    int dateRt = self.initClockDate;
    if(dateRt != CONFIGURATION_SUCCESS) {
        return [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",dateRt]];
    }
    int timeRt = self.initClockTime;
    if(timeRt != CONFIGURATION_SUCCESS) {
        return [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",timeRt]];
    }
    int majorTagsRt = self.configureMajorTags;
    if(majorTagsRt != CONFIGURATION_SUCCESS) {
        return [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]];
    }
    int aidsRt = [self clearentConfiguration:clearentConfiguration];
    if(aidsRt != CONFIGURATION_SUCCESS) {
        return [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",aidsRt]];
    }
    return @"Reader Configuration Completed";
}

+ (int) initClockDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSData *clockDate = [IDTUtility hexToData:dateString];
    NSData *result;
    RETURN_CODE dateRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x25 subCommand:0x03 data:clockDate response:&result];
    if (RETURN_CODE_DO_SUCCESS == dateRt) {
        NSLog(@"Clock Date Initialized");
    } else {
        NSString *errorResult = [[IDT_VP3300 sharedController] device_getResponseCodeString:dateRt];
        NSLog(@"Failed to configure real time clock date: %@",errorResult);
        return DATE_FAILED;
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) initClockTime {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HHMM";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    NSData *timeDate = [IDTUtility hexToData:timeString];
    NSData *result;
    RETURN_CODE timeRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x25 subCommand:0x01 data:timeDate response:&result];
    if (RETURN_CODE_DO_SUCCESS == timeRt) {
        NSLog(@"Clock Time Initialized");
    } else {
        return TIME_FAILED;
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) configureMajorTags {
    NSMutableDictionary *tags;
    
    [[IDT_VP3300 sharedController] emv_setTerminalMajorConfiguration:5];
    
    RETURN_CODE retrieveTerminalDataRt = [[IDT_VP3300 sharedController] emv_retrieveTerminalData:&tags];
    if (RETURN_CODE_DO_SUCCESS == retrieveTerminalDataRt) {
        [tags setObject:@"D0DC20D0C41E1400" forKey:@"DFEE1E"];
        [tags setObject:EMV_DIP_ENTRY_MODE_TAG forKey:IDTECH_EMV_ENTRY_MODE_EMV_TAG];
    } else{
        return MAJOR_TAGS_RETRIEVE_FAILED;
    }
    RETURN_CODE setTerminalDateRt = [[IDT_VP3300 sharedController] emv_setTerminalData:tags];
    if (RETURN_CODE_DO_SUCCESS == setTerminalDateRt) {
        //TODO MOVE THE MAJOR AND MINOR TAGS BACK HERE ANDSEE IF EVERYTHING STILL WORKS
        //idtech custom tags should be configured upfront.
        [tags setObject:@"D0DC20D0C41E1400" forKey:@"DFEE1E"];
        //TODO expose a method the developer can pass in a json file to set application ids
        //Set emv entry mode
        [tags setObject:EMV_DIP_ENTRY_MODE_TAG forKey:IDTECH_EMV_ENTRY_MODE_EMV_TAG];
    } else{
        return MAJOR_TAGS_RETRIEVE_FAILED;
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) clearentConfiguration:(NSDictionary*) clearentConfiguration {
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
        if(contactAidsRt != CONFIGURATION_SUCCESS) {
            return contactAidsRt;
        }
    }
    NSDictionary *contactlessAids = [mobileDevice objectForKey:@"contactless-aids"];
    if(contactlessAids != nil) {
        int contactlessAidsRt = [self configureContactlessAids:contactlessAids];
        if(contactlessAidsRt != CONFIGURATION_SUCCESS) {
            return contactlessAidsRt;
        }
    }
    NSDictionary *contactCapks = [mobileDevice objectForKey:@"contact-ca-public-keys"];
    if(contactCapks != nil) {
        int contactCapksRt  = [self configureContactCapks:contactCapks];
        if(contactCapksRt != CONFIGURATION_SUCCESS) {
            return contactCapksRt;
        }
    }
    NSDictionary *contactlessCapks = [mobileDevice objectForKey:@"contactless-ca-public-keys"];
    if(contactlessCapks != nil) {
        int contactlessCapksRt  = [self configureContactlessCapks:contactlessCapks];
        if(contactlessCapksRt != CONFIGURATION_SUCCESS) {
            return contactlessCapksRt;
        }
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) configureContactAids:(NSDictionary*) contactAids {
    for(NSDictionary *contactAid in contactAids) {
        NSString *name = [contactAid objectForKey:@"name"];
        NSDictionary *values = [contactAid objectForKey:@"aid-values"];
        RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_setApplicationData:name configData:values];
        if (RETURN_CODE_DO_SUCCESS == rt) {
            NSLog(@"contact aid loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:rt];
            NSLog(@"contact aid failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            return CONTACT_FAILED;
        }
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) configureContactlessAids:(NSDictionary*) contactlessAids {
    for(NSDictionary *contactlessAid in contactlessAids) {
        NSString *name = [contactlessAid objectForKey:@"name"];
        NSDictionary *values = [contactlessAid objectForKey:@"aid-values"];
        NSString *group = [contactlessAid objectForKey:@"group"];
        RETURN_CODE rt;
        if(group != nil){
            NSString *tlvCombined = @"";
            NSString *requiredTag = @"FFE4";
            NSString *requiredTagValue = [values objectForKey:requiredTag];
            if(requiredTag == nil) {
                return REQUIRED_CONTACTLESS_TAG;
            }
            int requiredTlvLength = [[NSNumber numberWithLong:requiredTagValue.length / 2] intValue];
            NSString *requiredTlvLengthTwoDec = [NSString stringWithFormat:@"%02d",requiredTlvLength];
            NSString *requiredTlv = [NSString stringWithFormat:@"%@%@%@", requiredTag, requiredTlvLengthTwoDec,requiredTagValue];
            tlvCombined = [NSString stringWithFormat:@"%@%@", tlvCombined, requiredTlv];
            for(id key in values) {
                if(![key isEqualToString:@"FFE4"]) {
                    NSString *emvTag = key;
                    NSString *emvValue = [values objectForKey:key];
                    int tlvLength = [[NSNumber numberWithLong:emvValue.length / 2] intValue];
                    NSString *tlvLengthTwoDec = [NSString stringWithFormat:@"%02d",tlvLength];
                    NSString *tlv = [NSString stringWithFormat:@"%@%@%@", emvTag, tlvLengthTwoDec,emvValue];
                    tlvCombined = [NSString stringWithFormat:@"%@%@", tlvCombined, tlv];
                }
            }
            if(tlvCombined != nil) {
                NSData* tlvData = [IDTUtility hexToData:tlvCombined];
                rt = [[IDT_VP3300 sharedController] ctls_setConfigurationGroup:tlvData];
            } else {
                return CONTACTLESS_NO_COMBINED_TLV;
            }
        } else {
            rt = [[IDT_VP3300 sharedController] emv_setApplicationData:name configData:values];
        }
        if (RETURN_CODE_DO_SUCCESS == rt) {
            NSLog(@"contactless aid loaded %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:rt];
            NSLog(@"contactless aid failed to load %@",[NSString stringWithFormat:@"name %@,error %@", name, error]);
            return CONTACTLESS_FAILED;
        }
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) configureContactCapks:(NSDictionary*) contactCapks {
    for(NSDictionary *contactCapk in contactCapks) {
        NSString *name = [contactCapk objectForKey:@"name"];
        NSDictionary *values = [contactCapk objectForKey:@"aid-values"];
        NSString *rid = [values objectForKey:@"rid"];
        NSString *keyIndex = [values objectForKey:@"key-index"];
        NSString *hashAlgorithm = [values objectForKey:@"hash-algorithm"];
        NSString *hashValue = [values objectForKey:@"hash-value"];
        NSString *modulus = [values objectForKey:@"modulus"];
        NSString *modulusLength = [values objectForKey:@"big-endian-modulus-length"];
        NSString *encryptionAlgorithm = [values objectForKey:@"encryption-algorithm"];
        NSString *keyExponent = [values objectForKey:@"key-exponent"];
        
        NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,keyIndex,hashAlgorithm,encryptionAlgorithm,hashValue,keyExponent,modulusLength,modulus, nil];
        
        NSString* combined = [testKeyArray componentsJoinedByString:@""];
        
        NSData* capk = [IDTUtility hexToData:combined];
        RETURN_CODE capkRt = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            NSLog(@"contact capk loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:capkRt];
            NSLog(@"contact capk failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            return CONTACT_CAPKS_FAILED;
        }
    }
    return CONFIGURATION_SUCCESS;
}

+ (int) configureContactlessCapks:(NSDictionary*) contactlessCapks {
    for(NSDictionary *contactlessCapk in contactlessCapks) {
        NSString *name = [contactlessCapk objectForKey:@"name"];
        NSDictionary *values = [contactlessCapk objectForKey:@"aid-values"];
        NSString *rid = [values objectForKey:@"rid"];
        NSString *keyIndex = [values objectForKey:@"key-index"];
        NSString *hashAlgorithm = [values objectForKey:@"hash-algorithm"];
        NSString *hashValue = [values objectForKey:@"hash-value"];
        NSString *modulus = [values objectForKey:@"modulus"];
        NSString *modulusLength = [values objectForKey:@"big-endian-modulus-length"];
        NSString *encryptionAlgorithm = [values objectForKey:@"encryption-algorithm"];
        NSString *keyExponent = [values objectForKey:@"key-exponent"];
        NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,keyIndex,hashAlgorithm,encryptionAlgorithm,hashValue,keyExponent,modulusLength,modulus, nil];
        NSString* combined = [testKeyArray componentsJoinedByString:@""];
        NSData* capk = [IDTUtility hexToData:combined];
        RETURN_CODE capkRt = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            NSLog(@"contactless capk loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:capkRt];
            NSLog(@"contactless capk failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            return CONTACTLESS_CAPKS_FAILED;
        }
    }
    return CONFIGURATION_SUCCESS;
}
@end

