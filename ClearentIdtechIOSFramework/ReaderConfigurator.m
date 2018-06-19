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
    //TODO Do we want to fail using the reader if any part of the configuration fails ?
//    if(majorTagsRt != CONFIGURATION_SUCCESS) {
//        return [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]];
//    }
    if(clearentConfiguration != nil) {
        int clearentConfigurationRt = [self clearentConfiguration:clearentConfiguration];
        if(clearentConfigurationRt != CONFIGURATION_SUCCESS) {
            return [NSString stringWithFormat:@"%@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",clearentConfigurationRt]];
        }
    } else {
         NSLog(@"Skip configuring AIDs and CAPKs...");
    }
    return @"READER CONFIGURED";
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
        //TODO
//        if(contactAidsRt != CONFIGURATION_SUCCESS) {
//            return contactAidsRt;
//        }
    }
    
    NSDictionary *contactlessAids = [mobileDevice objectForKey:@"contactless-aids"];
    if(contactlessAids != nil) {
        int contactlessAidsRt = [self configureContactlessAids:contactlessAids];
        //TODO
//        if(contactlessAidsRt != CONFIGURATION_SUCCESS) {
//            return contactlessAidsRt;
//        }
    }
    
    NSDictionary *publicKeys = [mobileDevice objectForKey:@"ca-public-keys"];
    if(publicKeys != nil) {
            int publicKeysRt  = [self configureContactlessCapks:publicKeys];
        //TODO 
            //        if(publicKeysRt != CONFIGURATION_SUCCESS) {
            //            return publicKeysRt;
            //        }
    }
    return CONFIGURATION_SUCCESS;
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
            //return CONTACT_FAILED;
        }
    }
    if(!allSuccessful) {
        return CONTACT_FAILED;
    }
    return CONFIGURATION_SUCCESS;
}

//TODO refactor this..
+ (int) configureContactlessAids:(NSDictionary*) contactlessAids {
    bool allSuccessful = true;
    for(NSDictionary *contactlessAid in contactlessAids) {
        NSString *name = [contactlessAid objectForKey:@"name"];
        NSDictionary *values = [contactlessAid objectForKey:@"aid-values"];
        NSString *group = [contactlessAid objectForKey:@"group"];
        if(group != nil) {
            NSString *tlvCombinedApplicationData = @"";
            
            //Add required first tag FFE4
            NSString *requiredFFE4Tag1 = @"FFE4";
            NSString *requiredFFE4TagValue = [values objectForKey:requiredFFE4Tag1];
            if(requiredFFE4Tag1 == nil) {
                return REQUIRED_CONTACTLESS_TAG;
            }
            int requiredFFE4TlvLength = [[NSNumber numberWithLong:requiredFFE4TagValue.length / 2] intValue];
            NSString *requiredFFE4TlvLengthTwoDec = [NSString stringWithFormat:@"%02d",requiredFFE4TlvLength];
            NSString *requiredFFE4Tlv = [NSString stringWithFormat:@"%@%@%@", requiredFFE4Tag1, requiredFFE4TlvLengthTwoDec,requiredFFE4TagValue];
            tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, requiredFFE4Tlv];
            
            //Add required second tag 9F06
            NSString *required9F06Tag1 = @"9F06";
            NSString *required9F06TagValue = [values objectForKey:required9F06Tag1];
            if(required9F06Tag1 == nil) {
                return REQUIRED_9F06_CONTACTLESS_TAG;
            }
            int required9F06TlvLength = [[NSNumber numberWithLong:required9F06TagValue.length / 2] intValue];
            NSString *required9F06TlvLengthTwoDec = [NSString stringWithFormat:@"%02d",required9F06TlvLength];
            NSString *required9F06Tlv = [NSString stringWithFormat:@"%@%@%@", required9F06Tag1, required9F06TlvLengthTwoDec,required9F06TagValue];
            tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, required9F06Tlv];
    
            int groupInt = group.intValue;
            //Set the application data first: FFE4 - group 9F06 - aid FFE1 - partial selection enabled FFE6 - disabled false
            
            //Do not include FFE6 in non system aids.
            //TODO review these. These probably will never change and can remain hard coded. setting Application Data for contactless is like providing a header in c.
            //the main configuration for contactless is in the configuration group
            if(groupInt == 8) {
                tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, @"FFE10101"];
            } else if(groupInt == 6) {
                tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, @"FFE10101FFE50110"];
            } else if(groupInt == 5) {
                tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, @"FFE10101FFE60100FFE50110FFE30114"];
            } else if(groupInt == 10) {
                tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, @"FFE10101FFE60100FFE50110"];
            } else {
                tlvCombinedApplicationData = [NSString stringWithFormat:@"%@%@", tlvCombinedApplicationData, @"FFE10101FFE60100FFE50110"];
            }
                
            NSMutableDictionary *groupDictionary;
    
            RETURN_CODE getConfigurationGroupRt = [[IDT_VP3300 sharedController]  ctls_getConfigurationGroup:groupInt response:&groupDictionary];
            
            if (RETURN_CODE_DO_SUCCESS == getConfigurationGroupRt) {
               NSLog(@"The configuration group exists. Update it. %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
            } else {
                NSLog(@"The configuration group does not exist. Add before setting application data %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
            }
            
            
            NSString *tlvCombinedForConfigGroup = @"";
            tlvCombinedForConfigGroup = [NSString stringWithFormat:@"%@%@", tlvCombinedForConfigGroup, requiredFFE4Tlv];
            for(id key in values) {
                if(![key isEqualToString:@"FFE4"] && ![key isEqualToString:@"9F06"]) {
                    NSString *emvTag = key;
                    NSString *emvValue = [values objectForKey:key];
                    int tlvLength = [[NSNumber numberWithLong:emvValue.length / 2] intValue];
                    NSString *tlvLengthTwoDec = [NSString stringWithFormat:@"%02d",tlvLength];
                    NSString *tlv = [NSString stringWithFormat:@"%@%@%@", emvTag, tlvLengthTwoDec,emvValue];
                    tlvCombinedForConfigGroup = [NSString stringWithFormat:@"%@%@", tlvCombinedForConfigGroup, tlv];
                }
            }
            if(tlvCombinedForConfigGroup != nil) {
                NSData* tlvData;
                
                //TODO Worked with IDTech to figure out what was failing. We need to take these tags and move them to the external configuration
                if(groupInt == 5) {
                    //took the default 0 configuration group and prefix it with FFE40105 change DF64 to 01 9f09 - 0096 9f33 - 6028C8 df5b 05 9f1b set to zeroes
                    NSString *defaultVisaTags = @"FFE401055f2a0208405f3601029a031408109c01009f02060000000000019f03060000000000009f090200969f150200009f160f0000000000000000000000000000009f1a0208409f1b04000000009f1c0800000000000000009f21031201179f33036028C89f3501229f400560000010019f4e1e0000000000000000000000000000000000000000000000000000000000009f5301009f6604800040009f7c140000000000000000000000000000000000000000df640101df650100df660100df680100df6a0101df7503003000df7c0100df7d0100df7f0100df891b0101dfed0100dfed020400000001dfed030100dfed040101dfed050101dfed060100dfed070100dfee3b0400bc614edfee3c00dfee3d00dfef2500dfef4b0312b600ffee1d0504042a0c31ffee200205dcfff003020000fff106000000010000fff2083030303030303030fff30207fffff403010001fff506000000008000fff70100fff80100fff90103fffa020000fffb0100fffd05f850acf800fffe05f850aca000ffff050000000000df5b0105";
                    tlvData = [IDTUtility hexToData:defaultVisaTags];
                } else if(groupInt == 9 ) {
                    //TODO break these out into our configuration. Group 9 is Mastercard 9f33 - 602808
                     NSString *defaultTags = @"FFE401095f2a0208405f3601029a03ffffff9c01009f03060000000000009f090200029f150211119f1a0208409f1b04000017709f1c0800000000000000009f2103ffffff9f33036028089f3501229f3901919f400560000010019f5301009f6d0200019f7c1400000000000000000000000000000000000000009f7e0100df28030008e8df29030068e8df811a039f6a04df811e0110df812406000000030000df812506000000030000df812c0100fff106000000010000fff2083030303030303030fff506000000008000fffc0101fffd05f45084800cfffe05f45084800cffff05000000000";
                    tlvData = [IDTUtility hexToData:defaultTags];
                } else {
                    tlvData = [IDTUtility hexToData:tlvCombinedForConfigGroup];
                }
                //Then, set/associate the configuration group
                RETURN_CODE rt = [[IDT_VP3300 sharedController] ctls_setConfigurationGroup:tlvData];
                if (RETURN_CODE_DO_SUCCESS == rt) {
                    NSLog(@"contactless group added/updated %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
                        
                    //Try to load the app data, for now regardless of what happened at the group level.
                    NSData *setApplicationData = [IDTUtility hexToData:tlvCombinedApplicationData];
                    int setApplicationDataRt = [[IDT_VP3300 sharedController] ctls_setApplicationData:setApplicationData];
                        
                    if (RETURN_CODE_DO_SUCCESS == setApplicationDataRt) {
                        NSLog(@"contactless setApplicationData successful %@",[NSString stringWithFormat:@"name %@,group %@", name, group]);
                    } else{
                        NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:setApplicationDataRt];
                        NSLog(@"contactless setApplicationData unsuccessful %@",[NSString stringWithFormat:@"name %@,error %@", name, error]);
                        allSuccessful = false;
                    }
                        
                } else{
                    NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:rt];
                    NSLog(@"contactless group failed to add/update %@",[NSString stringWithFormat:@"name %@,error %@", name, error]);
                    allSuccessful = false;
                }
            } else {
                allSuccessful = false;
            }
            if(groupInt == 5) {
                NSMutableDictionary *group1AidDictionary;
                int  ctlsRetrieveApplicationDataRt = [[IDT_VP3300 sharedController] ctls_retrieveApplicationData:@"A0000000031010" response:&group1AidDictionary];
                if (RETURN_CODE_DO_SUCCESS == ctlsRetrieveApplicationDataRt) {
                    //set the group to 5 instead of 0
                    NSString *tlvCombined = @"FFE401059F0607A0000000031010";
                    for(id key in group1AidDictionary) {
                        if(![key isEqualToString:@"FFE4"] && ![key isEqualToString:@"9F06"] && ![key isEqualToString:@"FFE2"] && ![key isEqualToString:@"FFE9"] && ![key isEqualToString:@"FFEA"]
                           && ![key isEqualToString:@"FFE3"]) {
                            NSString *emvTag = key;
                            NSString* emvValue = [IDTUtility dataToHexString:[group1AidDictionary objectForKey:key]];
                            int tlvLength = [[NSNumber numberWithLong:emvValue.length / 2] intValue];
                            NSString *tlvLengthTwoDec = [NSString stringWithFormat:@"%02d",tlvLength];
                            NSString *tlv = [NSString stringWithFormat:@"%@%@%@", emvTag, tlvLengthTwoDec,emvValue];
                            tlvCombined = [NSString stringWithFormat:@"%@%@", tlvCombined, tlv];
                        }
                    }
                    NSData *setApplicationData = [IDTUtility hexToData:tlvCombined];
                    int  ctlsRetrieveApplicationDataRt = [[IDT_VP3300 sharedController] ctls_setApplicationData:setApplicationData];
                    if (RETURN_CODE_DO_SUCCESS == ctlsRetrieveApplicationDataRt) {
                        NSLog(@"Switched group 0 to group 5 %@",[NSString stringWithFormat:@"name %@", name]);
                    } else {
                        NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:ctlsRetrieveApplicationDataRt];
                        NSLog(@"Failed to switch group 0 to group 5 %@",[NSString stringWithFormat:@"name %@,error %@", name, error]);
                        allSuccessful = false;
                    }
                }
            }
            if(groupInt == 9) {
                 NSMutableDictionary *group1AidDictionary;
                int  ctlsRetrieveApplicationDataRt = [[IDT_VP3300 sharedController] ctls_retrieveApplicationData:@"A0000000041010" response:&group1AidDictionary];
                if (RETURN_CODE_DO_SUCCESS == ctlsRetrieveApplicationDataRt) {
                    //set the group to 9 instead of 1
                    NSString *tlvCombined = @"FFE401099F0607A0000000041010";
                    for(id key in group1AidDictionary) {
                        if(![key isEqualToString:@"FFE4"] && ![key isEqualToString:@"9F06"] && ![key isEqualToString:@"FFE2"] && ![key isEqualToString:@"FFE9"] && ![key isEqualToString:@"FFEA"]
                           && ![key isEqualToString:@"FFE3"]) {
                            NSString *emvTag = key;
                            NSString* emvValue = [IDTUtility dataToHexString:[group1AidDictionary objectForKey:key]];                        
                            int tlvLength = [[NSNumber numberWithLong:emvValue.length / 2] intValue];
                            NSString *tlvLengthTwoDec = [NSString stringWithFormat:@"%02d",tlvLength];
                            NSString *tlv = [NSString stringWithFormat:@"%@%@%@", emvTag, tlvLengthTwoDec,emvValue];
                            tlvCombined = [NSString stringWithFormat:@"%@%@", tlvCombined, tlv];
                        }
                    }
                    NSData *setApplicationData = [IDTUtility hexToData:tlvCombined];
                    int  ctlsRetrieveApplicationDataRt = [[IDT_VP3300 sharedController] ctls_setApplicationData:setApplicationData];
                    if (RETURN_CODE_DO_SUCCESS == ctlsRetrieveApplicationDataRt) {
                         NSLog(@"Switched group 1 to group 9 %@",[NSString stringWithFormat:@"name %@", name]);
                    } else {
                        NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:ctlsRetrieveApplicationDataRt];
                        NSLog(@"Failed to switch group 1 to group 9 %@",[NSString stringWithFormat:@"name %@,error %@", name, error]);
                        allSuccessful = false;
                    }
                }
            }
        } else {
            NSLog(@"Group is required for contactless aid %@", name);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        return CONTACTLESS_FAILED;
    }
    return CONFIGURATION_SUCCESS;
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
    return CONFIGURATION_SUCCESS;
}

+ (int) configureContactlessCapks:(NSDictionary*) contactlessCapks {
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
        RETURN_CODE capkRt = [[IDT_VP3300 sharedController] ctls_setCAPK:capk];
        if (RETURN_CODE_DO_SUCCESS == capkRt) {
            NSLog(@"contactless capk loaded %@",[NSString stringWithFormat:@"%@", name]);
        } else{
            NSString *error =[[IDT_VP3300 sharedController] device_getResponseCodeString:capkRt];
            NSLog(@"contactless capk failed to load %@",[NSString stringWithFormat:@"%@,%@", name, error]);
            allSuccessful = false;
        }
    }
    if(!allSuccessful) {
        return CONTACTLESS_CAPKS_FAILED;
    }
    return CONFIGURATION_SUCCESS;
}
@end

