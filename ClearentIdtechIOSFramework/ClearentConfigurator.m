//
//  ClearentConfigurator.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConfigurator.h"
#import <IDTech/IDTUtility.h>
#import "ClearentLumberjack.h"
#import "ClearentContactlessConfigurator.h"
#import "ClearentCache.h"

static NSString *const ERROR_MSG = @"Failed to configure reader. Confirm internet access and try reconnecting. If this does not work contact support.";
static NSString *const READER_CONFIGURED_MESSAGE = @"Reader configured and ready";
static NSString *const DEVICESERIALNUMBER_STANDIN = @"9999999999";
static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";

@implementation ClearentConfigurator

ClearentContactlessConfigurator* _clearentContactlessConfigurator;

- (instancetype) init: (NSString*)clearentBaseUrl publicKey:(NSString*)publicKey callbackObject:(id)callbackObject withSelector:(SEL)selector sharedController:(IDT_VP3300*) sharedController {
    self = [super init];
    if (self) {
        _sharedController = sharedController;
        self.callbackObject = callbackObject;
        self.publicKey = publicKey;
        self.baseUrl = clearentBaseUrl;
        self.selector = selector;
        _clearentContactlessConfigurator = [[ClearentContactlessConfigurator alloc] init];
    }
    return self;
}

-(void) configure: (NSString*)kernelVersion  deviceSerialNumber:(NSString*) deviceSerialNumber autoConfiguration:(BOOL) autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration {
    
    if(deviceSerialNumber  == nil) {
        [self notifyError:@"Device Serial Number not found. Connect device"];
        return;
    }
    
    if(self.baseUrl == nil) {
        [self notifyError:@"Base url is required for device configuration and transaction processing"];
        return;
    }
    
    //we use the cache to stop configurating every time they connect. If they want to override the cache they can use the clearConfigurationCache & clearContactlessConfigurationCache
    //in Clearent_VP3300.
     NSString *storedDeviceSerialNumber = [ClearentCache getCurrentDeviceSerialNumber];
     NSString *readerConfiguredFlag = [ClearentCache getReaderConfiguredFlag];
     NSString *readerContactlessConfiguredFlag = [ClearentCache getReaderContactlessConfiguredFlag];
          
     if(storedDeviceSerialNumber != nil && [storedDeviceSerialNumber isEqualToString:deviceSerialNumber]) {
        if(readerConfiguredFlag != nil && [readerConfiguredFlag isEqualToString:@"true"]) {
            [ClearentLumberjack logInfo:@"Reader already configured. Disable contact configuration"];
            autoConfiguration = false;
        }
        if(readerContactlessConfiguredFlag != nil && [readerContactlessConfiguredFlag isEqualToString:@"true"]) {
            [ClearentLumberjack logInfo:@"Reader already configured. Disable contactless configuration"];
            contactlessAutoConfiguration = false;
        }
     } else if(storedDeviceSerialNumber != nil && (autoConfiguration || contactlessAutoConfiguration)) {
        [ClearentCache clearConfigurationCache];
        [ClearentCache clearContactlessConfigurationCache];
     };
    
    if(!autoConfiguration) {
        [ClearentLumberjack logInfo:@"Skipping emv contact configuration"];
    }
    
    if(!contactlessAutoConfiguration) {
        [ClearentLumberjack logInfo:@"Skipping contactless configuration"];
    }
    
    if(!autoConfiguration && !contactlessAutoConfiguration) {
        BOOL isDeviceConfigured = [ClearentCache isDeviceConfigured:autoConfiguration contactlessAutoConfiguration:contactlessAutoConfiguration deviceSerialNumber:deviceSerialNumber];
        if(!isDeviceConfigured) {
            [self cacheConfiguredReader: deviceSerialNumber];
        }
        [ClearentLumberjack logInfo:@"ClearentConfigurator:both config flags are disabled"];
        [self notifyInfo:READER_CONFIGURED_MESSAGE];
        return;
    }
    
    [self increaseStandByTime];
    
    [self fetchConfiguration:autoConfiguration contactlessAutoConfiguration:contactlessAutoConfiguration deviceSerialNumber:deviceSerialNumber kernelVersion:kernelVersion];
}

- (void)fetchConfiguration:(BOOL)autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration deviceSerialNumber:(NSString *)deviceSerialNumber kernelVersion:(NSString *)kernelVersion {
    [ClearentLumberjack logInfo:@"Call Clearent to get configuration"];
    ClearentConfigFetcher *clearentConfigFetcher = [[ClearentConfigFetcher alloc] init:[NSURLSession sharedSession] baseUrl:self.baseUrl deviceSerialNumber:deviceSerialNumber kernelVersion:kernelVersion publicKey:self.publicKey];
    
    ClearentConfigFetcherResponse clearentConfigFetcherResponse = ^(NSDictionary *json) {
        if(json != nil) {
            [self notifyInfo:@"Retrieved configuration"];
            [self configure:json autoConfiguration:autoConfiguration contactlessAutoConfiguration:contactlessAutoConfiguration deviceSerialNumber:deviceSerialNumber];
        } else {
            [self notifyError:@"Device failed to retrieve configuration."];
            [self notifyError:@"Check connectivity (wifi). Configuration is required for successful transaction processing"];
        }
    };
    
    [clearentConfigFetcher fetchConfiguration: clearentConfigFetcherResponse];
}

- (void) configure: (NSDictionary*) jsonConfiguration autoConfiguration:(BOOL) autoConfiguration contactlessAutoConfiguration:(BOOL) contactlessAutoConfiguration deviceSerialNumber:(NSString*) deviceSerialNumber {
    
    ClearentConfiguration *clearentConfiguration = [self createClearentConfiguration:autoConfiguration contactlessAutoConfiguration:contactlessAutoConfiguration jsonConfiguration:jsonConfiguration];
    
    bool contactReady = true;
    bool contactlessReady = true;
    NSString *configurationMessage = READER_CONFIGURED_MESSAGE;
    
    if(clearentConfiguration.autoConfiguration) {
        CONFIGURATION_ERROR_CODE  configureContactReturnCode = [self configureContact:clearentConfiguration];
        if(configureContactReturnCode != EMV_CONFIGURATION_SUCCESS) {
            contactReady = false;
        }
    }
    
    if(clearentConfiguration.contactlessAutoConfiguration) {
        CONTACTLESS_CONFIGURATION_RETURN_CODE configureContactlessReturnCode = [self configureContactless:clearentConfiguration sharedController:_sharedController];
        if(configureContactlessReturnCode != CONTACTLESS_CONFIGURATION_SUCCESS) {
            contactlessReady = false;
        }
    }
    
    if(contactReady && contactlessReady) {
        [self notifyInfo:configurationMessage];
        [ClearentLumberjack logInfo:@"🍻🍻🍻🍻🍻 READER CONFIGURED BY IOS FRAMEWORK 🍻🍻🍻🍻🍻"];
        [self cacheConfiguredReader: deviceSerialNumber];
        if(contactlessAutoConfiguration) {
            [ClearentCache updateContactlessFlagCache:@"true"];
        }
        //[self tagTheReaderWithConfigurationInfo: deviceSerialNumber];
    }
}

- (void) tagTheReaderWithConfigurationInfo: (NSString*) deviceSerialNumber {
    if(![_sharedController isConnected]) {
        return;
    }
    
    if(deviceSerialNumber != nil && [deviceSerialNumber isEqualToString:DEVICESERIALNUMBER_STANDIN]) {
        [ClearentLumberjack logInfo:@"Not tag the reader if device serial number is all nines"];
        return;
    }
    
    NSDictionary* terminalData;
    RETURN_CODE emv_retrieveTerminalDataRt = [_sharedController emv_retrieveTerminalData:&terminalData];
    if (RETURN_CODE_DO_SUCCESS == emv_retrieveTerminalDataRt) {
        [terminalData setValue:[IDTUtility stringToData:@"Clearent"] forKey:@"DFED20"];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yymmdd";
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        
        [terminalData setValue:[IDTUtility stringToData:dateString]  forKey:@"DFED21"];
        
        NSString *configurationVersion = [NSString stringWithFormat:@"ios v1.1.0 %@", deviceSerialNumber];
        
        [terminalData setValue:[IDTUtility stringToData:configurationVersion] forKey:@"DFED22"];
        
        RETURN_CODE emv_setTerminalDataRt = [_sharedController emv_setTerminalData:terminalData];
        if (RETURN_CODE_DO_SUCCESS == emv_setTerminalDataRt) {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Reader has been tagged %@", configurationVersion]];
        } else{
            [ClearentLumberjack logError:[NSString stringWithFormat:@"Failed to tag reader %@", configurationVersion]];
        }
    } else {
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"failed to tag reder for device serial number %@", deviceSerialNumber]];
    }
       
}
- (ClearentConfiguration*) createClearentConfiguration:(BOOL)autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration jsonConfiguration:(NSDictionary *)jsonConfiguration {
    ClearentConfiguration *clearentConfiguration = [[ClearentConfiguration alloc] initWithJson:jsonConfiguration];
    clearentConfiguration.autoConfiguration = autoConfiguration;
    clearentConfiguration.contactlessAutoConfiguration = contactlessAutoConfiguration;
    return clearentConfiguration;
}

- (CONFIGURATION_ERROR_CODE) configureContact:(ClearentConfiguration*) clearentConfiguration {
    CONFIGURATION_ERROR_CODE emvConfigReturnCode = EMV_CONFIGURATION_SUCCESS;
    [ClearentLumberjack logInfo:@"Emv Contact Configuration Started"];
    ClearentEmvConfigurator *clearentEmvConfigurator = [[ClearentEmvConfigurator alloc] initWithIdtechSharedController:self->_sharedController];
    
    if(clearentConfiguration.autoConfiguration) {
        [self notifyInfo:@"Emv Contact Configuration - General (1 of 3)"];
        int majorTagsRt = [clearentEmvConfigurator configureMajorTags];
        if(majorTagsRt != EMV_CONFIGURATION_SUCCESS) {
            [self notifyError:[NSString stringWithFormat:@"Emv Contact Configuration - General Failed %@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]]];
            emvConfigReturnCode = majorTagsRt;
        }
        if(clearentConfiguration != nil && clearentConfiguration.isValid) {
            [self notifyInfo:@"Emv Contact Configuration - Application Ids (2 of 3)"];
            int contactAidsRt = [clearentEmvConfigurator configureContactAids:clearentConfiguration.contactAids];
            if(contactAidsRt != EMV_CONFIGURATION_SUCCESS) {
                [self notifyError:[NSString stringWithFormat:@"Emv Contact Configuration - Application Ids Failed %@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]]];
                emvConfigReturnCode = contactAidsRt;
            }
            [self notifyInfo:@"Emv Contact Configuration - Add Public Keys (3 of 3)"];
            int publicKeysRt  = [clearentEmvConfigurator configureContactCapks:clearentConfiguration.publicKeys];
            if(publicKeysRt != EMV_CONFIGURATION_SUCCESS) {
              [self notifyError:[NSString stringWithFormat:@"Emv Contact Configuration - Add Public Keys %@,%@", ERROR_MSG, [NSString stringWithFormat:@"%d",majorTagsRt]]];
                emvConfigReturnCode = publicKeysRt;
            }
        } else {
            emvConfigReturnCode = CONTACT_FAILED;
        }
    }
    [ClearentLumberjack logInfo:@"Emv Contact Configuration done"];
    return emvConfigReturnCode;
}

- (CONTACTLESS_CONFIGURATION_RETURN_CODE) configureContactless:(ClearentConfiguration*) clearentConfiguration sharedController:(IDT_VP3300*) sharedController {
    [ClearentLumberjack logInfo:@"Starting Contactless Configuration"];
    CONTACTLESS_CONFIGURATION_RETURN_CODE contactlessConfigurationReturnCode = CONTACTLESS_CONFIGURATION_SUCCESS;
//    [self notifyInfo:@"Contactless Configuration - Remove Unsupported Application Ids (1 of 4)"];
//    contactlessConfigurationReturnCode = [_clearentContactlessConfigurator removeUnsupportedAids:clearentConfiguration.contactlessSupportedAids sharedController:sharedController];
//    if(contactlessConfigurationReturnCode != CONTACTLESS_CONFIGURATION_SUCCESS) {
//        [self notifyError:[NSString stringWithFormat:@"Contactless Configuration - Remove Unsupported Application Ids Failed %@", [ClearentContactlessConfigurator  getReturnCodeDisplayName: contactlessConfigurationReturnCode]]];
//        return contactlessConfigurationReturnCode;
//    }
    [self notifyInfo:@"Contactless Configuration - Add Groups (1 of 3)"];
    contactlessConfigurationReturnCode = [_clearentContactlessConfigurator configureGroups:clearentConfiguration.contactlessGroups sharedController:sharedController];
    if(contactlessConfigurationReturnCode != CONTACTLESS_CONFIGURATION_SUCCESS) {
         [self notifyError:[NSString stringWithFormat:@"Contactless Configuration - Add groups Failed %@", [ClearentContactlessConfigurator  getReturnCodeDisplayName: contactlessConfigurationReturnCode]]];
        return contactlessConfigurationReturnCode;
    }
    [self notifyInfo:@"Contactless Configuration - Add Application Ids (2 of 3)"];
    contactlessConfigurationReturnCode = [_clearentContactlessConfigurator configureAids:clearentConfiguration.contactlessAids sharedController:sharedController];
    if(contactlessConfigurationReturnCode != CONTACTLESS_CONFIGURATION_SUCCESS) {
        [self notifyError:[NSString stringWithFormat:@"Contactless Configuration - Add Application Ids Failed %@", [ClearentContactlessConfigurator  getReturnCodeDisplayName: contactlessConfigurationReturnCode]]];
        return contactlessConfigurationReturnCode;
    }
     [self notifyInfo:@"Contactless Configuration - Add Public Keys (3 of 3)"];
    contactlessConfigurationReturnCode = [_clearentContactlessConfigurator configureCapks:clearentConfiguration.contactlessPublicKeys sharedController:sharedController];
    if(contactlessConfigurationReturnCode != CONTACTLESS_CONFIGURATION_SUCCESS) {
        [self notifyError:[NSString stringWithFormat:@"Contactless Configuration - Add Public Keys Failed %@", [ClearentContactlessConfigurator  getReturnCodeDisplayName: contactlessConfigurationReturnCode]]];
        return contactlessConfigurationReturnCode;
    }
    [self notifyInfo:@"Contactless Configuration done"];
    return contactlessConfigurationReturnCode;
}


- (void) notifyInfo:(NSString*)message {
    [ClearentLumberjack logInfo:message];
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
    [self.callbackObject performSelector:self.selector withObject:message];
    #pragma GCC diagnostic pop
}

- (void) notifyError:(NSString*)message {
    [ClearentLumberjack logError:message];
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
    [self.callbackObject performSelector:self.selector withObject:message];
     #pragma GCC diagnostic pop
}

- (NSData*) getClockDateAsYYYYMMDD {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    return [IDTUtility hexToData:dateString];
}


- (NSData*) getClockTimeAsHHMM {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HHMM";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    return [IDTUtility hexToData:timeString];
}
    
-(void) increaseStandByTime {
    NSData* response;
    RETURN_CODE increaseStandByTimeRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0xF0 subCommand:0x00 data:[IDTUtility hexToData:@"05FF"] response:&response];
    if(RETURN_CODE_DO_SUCCESS != increaseStandByTimeRt) {
        [ClearentLumberjack logInfo:@"Failed to increase stand by time to 255 seconds"];
    } else {
        [ClearentLumberjack logInfo:@"Stand by time increased to 255 seconds"];
    }
}

-(void) cacheConfiguredReader: (NSString*) deviceSerialNumber {
    if(deviceSerialNumber != nil) {
        NSString *firstTenOfDeviceSerialNumber = nil;
        if (deviceSerialNumber != nil && [deviceSerialNumber length] >= 10) {
            firstTenOfDeviceSerialNumber = [deviceSerialNumber substringToIndex:10];
        } else {
            firstTenOfDeviceSerialNumber = deviceSerialNumber;
        }
        [ClearentCache updateConfigurationCache:firstTenOfDeviceSerialNumber readerConfiguredFlag:@"true"];
    }
}

@end
