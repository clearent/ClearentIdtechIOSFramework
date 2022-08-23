//
//  ClearentDelegate.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.

#import "ClearentDelegate.h"
#import "ClearentConfigurator.h"
#import <IDTech/IDTUtility.h>
#import "ClearentUtils.h"
#import "ClearentLumberjack.h"
#import "ClearentCache.h"
#import "ClearentOfflineDeclineReceipt.h"
#import "ClearentPayment.h"
#import <AVFoundation/AVFoundation.h>

int getEntryMode (NSString* rawEntryMode);
BOOL isSupportedEmvEntryMode (int entryMode);

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
static NSString *const TRACK2_DATA_IDTECH_UNENCRYPTED_TAG = @"DFEE23";
static NSString *const TRACK1_DATA_EMV_TAG = @"56";
static NSString *const ENTRY_MODE_EMV_TAG = @"9F39";
static NSString *const TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG = @"9F6B";
static NSString *const MASTERCARD_GROUP_FF8105_TAG = @"FF8105";
static NSString *const MASTERCARD_GROUP_FF8106_TAG = @"FF8106";
static NSString *const IDTECH_DFEF4D_CIPHERTEXT_TAG = @"DFEF4D";

static NSString *const KSN_TAG = @"FFEE12";
static NSString *const TAC_DEFAULT = @"DF13";
static NSString *const TAC_DENIAL = @"DF14";
static NSString *const TAC_ONLINE = @"DF15";
static NSString *const DEVICE_SERIAL_NUMBER_EMV_TAG = @"DF78";
static NSString *const KERNEL_VERSION_EMV_TAG = @"DF79";

static NSString *const KERNEL_VERSION = @"EMV Common L2 V1.10.037";

static NSString *const DEVICE_SERIAL_NUMBER_PLACEHOLDER = @"9999999999";
static NSString *const KERNEL_BASE_VERSION = @"EMV Common L2 V1.10";
static NSString *const KERNEL_VERSION_INCREMENTAL = @".037";

static NSString *const CONTACTLESS_ERROR_CODE_TAG = @"FFEE1F";
static NSString *const CONTACTLESS_ERROR_CODE_NONE = @"00";
static NSString *const CONTACTLESS_ERROR_CODE_GO_TO_CONTACT_INTERFACE = @"02";
static NSString *const CONTACTLESS_ERROR_CODE_GO_TO_OTHER_INTERFACE = @"04";
static NSString *const CONTACTLESS_ERROR_CODE_GO_TO_MAGSTRIPE_INTERFACE = @"06";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_RETURNED_ERROR_STATUS = @"20";
static NSString *const CONTACTLESS_ERROR_CODE_COLLISION_ERROR = @"21";
static NSString *const CONTACTLESS_ERROR_CODE_AMOUNT_OVER_MAXIMUM_LIMIT = @"22";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_BLOCKED = @"25";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_EXPIRED = @"26";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_UNSUPPORTED = @"27";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_DID_NOT_RESPOND = @"30";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_GENERATED_AAC = @"42";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_SSA_OR_DDA_FAILED = @"44";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_MISSING_CA_PUBLIC_KEY = @"50";
static NSString *const CONTACTLESS_ERROR_CODE_CARD_FAILED_TO_RECOVER_ISSUER_PUBLIC_KEY = @"51";
static NSString *const CONTACTLESS_ERROR_CODE_PROCESSING_RESTRICTIONS_FAILED = @"55";

static NSString *const READER_CONFIGURED_FLAG_LETTER_P_IN_HEX = @"50";
static NSString *const MERCHANT_NAME_AND_LOCATION_HIJACKED_AS_PRECONFIGURED_FLAG  = @"9F4E";

/// <#Description#>
@implementation ClearentDelegate

ClearentConfigurator *_clearentConfigurator;
id<ClearentVP3300Configuration> _clearentVP3300Configuration;

BOOL previousSwipeWasCardWithChip = NO;
BOOL userToldToUseMagStripe = NO;
BOOL userToldToUseChipReader = NO;
BOOL contactlessIsProcessing = NO;

BOOL sentCardReadSuccessMessage = NO;

BOOL processingCurrentRequest = NO;

int countNumberOfShortBeeps = 0;

NSTimer *monitorCardRemovalTimer;

BOOL userNotifiedOfTimeOut = NO;

BOOL transactionIsInProcess = NO;

NSDictionary *enhancedMessages;


- (instancetype) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey idTechSharedInstance: (IDT_VP3300*) idTechSharedInstance  {
    
    self = [super init];
    
    if (self) {
        
        self.publicDelegate = publicDelegate;
        self.idTechSharedInstance = idTechSharedInstance;
        self.baseUrl = clearentBaseUrl;
        self.publicKey = publicKey;
        SEL configurationCallbackSelector = @selector(deviceMessage:);
        _clearentConfigurator = [[ClearentConfigurator alloc] init:self.baseUrl publicKey:self.publicKey callbackObject:self withSelector:configurationCallbackSelector sharedController:_idTechSharedInstance];
        self.autoConfiguration = false;
        self.contactlessAutoConfiguration = false;
        self.clearentPayment = nil;
        self.configured = NO;
        self.contactless = NO;

    }
    return self;
}

- (instancetype) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration
idTechSharedInstance: (IDT_VP3300*) idTechSharedInstance {
    
    self = [super init];
    
    if (self) {
        
        [self setClearentVP3300Configuration:clearentVP3300Configuration];
        _idTechSharedInstance = idTechSharedInstance;
        self.baseUrl = clearentVP3300Configuration.clearentBaseUrl;
        self.publicKey = clearentVP3300Configuration.publicKey;
        self.publicDelegate = publicDelegate;
        self.autoConfiguration = clearentVP3300Configuration.contactAutoConfiguration;
        self.contactlessAutoConfiguration = clearentVP3300Configuration.contactlessAutoConfiguration;
        self.clearentPayment = nil;
        if(!self.autoConfiguration && !self.contactlessAutoConfiguration) {
            self.configured = YES;
        } else {
            self.configured = NO;
        }
        self.contactless = clearentVP3300Configuration.contactless;
        SEL configurationCallbackSelector = @selector(deviceMessage:);
        _clearentConfigurator = [[ClearentConfigurator alloc] init:self.baseUrl publicKey:self.publicKey callbackObject:self withSelector:configurationCallbackSelector sharedController:_idTechSharedInstance];
        
        
        [self setEnhancedMessaging];
       
    }
    return self;
}

- (void) setEnhancedMessaging {
    
    
    NSString *bundlePath =
      [[NSBundle mainBundle] pathForResource:@"ClearentIdtechMessages"
                                      ofType:@"bundle"];
    if ([bundlePath length] > 0){
        
        NSBundle *resourcesBundle = [NSBundle bundleWithPath:bundlePath];
        if (resourcesBundle != nil){
            NSString *enhancedMessagingFilePath =
                  [resourcesBundle pathForResource:@"enhancedmessages-v1"
                                            ofType:@"txt"
                                       inDirectory:nil];
            if ([enhancedMessagingFilePath length] > 0){
                
                NSError *error;
                NSString *fileContents = [NSString stringWithContentsOfFile:enhancedMessagingFilePath encoding:NSUTF8StringEncoding error:&error];

                if (error) {
                    NSLog(@"Error reading file: %@", error.localizedDescription);
                } else {

                    NSLog(@"contents: %@", fileContents);
                    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
                    NSLog(@"items = %d", [listArray count]);
                
                    enhancedMessages = [NSDictionary dictionaryWithContentsOfFile:enhancedMessagingFilePath];
                }
                
            }
        }
    }
    
   
     if(nil != enhancedMessages && enhancedMessages.count > 0) {
         NSLog(@"ENHANCED MESSAGING INITIALIZED");
     } else {
         NSLog(@"NO ENHANCED MESSAGING");
     }
}

- (instancetype) initWithPaymentCallback : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration callbackObject:(id)callbackObject withSelector:(SEL)runTransactionSelector idTechSharedInstance: (IDT_VP3300*) idTechSharedInstance {
    self = [self initWithConfig: publicDelegate clearentVP3300Configuration:clearentVP3300Configuration idTechSharedInstance:idTechSharedInstance];
    if (self) {
        _runTransactionSelector = runTransactionSelector;
        _callbackObject = callbackObject;
    }
    return self;
}

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines {
    
    if(processingCurrentRequest) {
        [ClearentLumberjack logInfo:@"CLEARENT PROCESSING STARTED. STOP LCDDISPLAY COMM"];
        return;
    }
    
    switch (mode) {
        case 0x10:
            [ClearentLumberjack logInfo:@"prompt 10"];
            break;
        case 0x03:
            [ClearentLumberjack logInfo:@"prompt 3"];
            break;
        case 0x01:
            [ClearentLumberjack logInfo:@"prompt 1"];
            break;
        case 0x02:
            [ClearentLumberjack logInfo:@"prompt 2"];
            break;
        case 0x08:{
            [_idTechSharedInstance emv_callbackResponseLCD:mode selection:1];
            return;
        }
            break;
        default:
            break;
    }
   
    NSMutableArray *updatedArray = [[NSMutableArray alloc]initWithCapacity:1];
    
    if (lines != nil) {
        for (NSString* message in lines) {
            if(message != nil) {
                if(!self.contactless && [message isEqualToString:@"PLEASE SWIPE,"]) {
                    [ClearentLumberjack logError:@"contactless is not enabled. Switch PLEASE SWIPE to old message"];
                    [updatedArray addObject:@"INSERT/SWIPE"];
                    [self deviceMessage:CLEARENT_USER_ACTION_2_IN_1_MESSAGE];
                } else  if(!self.contactless && [message isEqualToString:@"TAP, OR INSERT"]) {
                    [ClearentLumberjack logError:@"contactless is not enabled. Switch TAP OR INSERT to old message"];
                    [updatedArray addObject:@"CARD"];
                } else if([message isEqualToString:@"TERMINATED"]) {
                    [ClearentLumberjack logError:@"IDTech framework terminated the request."];
                    [self deviceMessage:CLEARENT_TRANSACTION_TERMINATED];
                }  else if([message isEqualToString:@"TERMINATE"]) {
                    [ClearentLumberjack logError:@"IDTech framework terminated the request."];
                    [self deviceMessage:CLEARENT_TRANSACTION_TERMINATE];
                }  else if([message isEqualToString:@"USE MAGSTRIPE"]) {
                    userToldToUseMagStripe = YES;
                    [ClearentLumberjack logError:@"IDTech framework USE MAGSTRIPE."];
                    [self deviceMessage:CLEARENT_USE_MAGSTRIPE];
                } else if([message isEqualToString:@"CARD"] && (userToldToUseMagStripe || userToldToUseChipReader)) {
                     [ClearentLumberjack logError:@"do not show CARD message to help with messaging of restarts of the transaction"];
                } else if([message isEqualToString:@"INSERT/SWIPE"] && (userToldToUseMagStripe || userToldToUseChipReader)) {
                    [ClearentLumberjack logError:@"do not show INSERT/SWIPE message to help with messaging of restarts of the transaction"];
                } else if([message isEqualToString:@"USE CHIP READER"]) {
                    userToldToUseChipReader = YES;
                    if(!userToldToUseMagStripe) {
                        [self deviceMessage:CLEARENT_CHIP_FOUND_ON_SWIPE];
                        [ClearentLumberjack logInfo:@"Clearent is handling the use chip reader message."];
                    } else {
                        [ClearentLumberjack logError:@"User told to use magstripe even though use chip reader message came back."];
                    }
                } else if([message isEqualToString:@"DECLINED"]) {
                    //NSLog(@"This is not really a decline. Clearent is creating a transaction token for later use.");
                } else if([message isEqualToString:@"APPROVED"]) {
                   // NSLog(@"This is not really an approval. Clearent is creating a transaction token for later use.");
                } else {
                   [ClearentLumberjack logInfo:message];
                   [self deviceMessage:message];
                   [updatedArray addObject:message];
                }
            }
        }
        
        if(updatedArray.count > 0) {
            if ([self.publicDelegate respondsToSelector:@selector(lcdDisplay:lines:)]) {
                [self.publicDelegate lcdDisplay:(int)mode  lines:(NSArray*)updatedArray];
            }
        }
    }
}


- (void) plugStatusChange: (BOOL) deviceInserted {
    
    if (deviceInserted) {
        if ([[AVAudioSession sharedInstance] outputVolume] < 1.0) {
            [self deviceMessage:CLEARENT_AUDIO_JACK_LOW_VOLUME];
        } else{
            [self deviceMessage:CLEARENT_CONNECTING_AUDIO_JACK];
            [_idTechSharedInstance device_connectToAudioReader];
        }
    }
    
    if ([self.publicDelegate respondsToSelector:@selector(plugStatusChange:)]) {
       [self.publicDelegate plugStatusChange:deviceInserted];
    }
}


-(void) deviceConnected {
    
    if(self.clearentConnection != nil) {
        
        if(self.clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            [self deviceMessage:CLEARENT_BLUETOOTH_CONNECTED];
            [_clearentDeviceConnector recordBluetoothDeviceAsConnected];
            [_clearentDeviceConnector resetBluetoothAfterConnected];
        }
        
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"%@%@", @"connected ", [self.clearentConnection createLogMessage]]];
        
    }
    
    if([_idTechSharedInstance device_isAudioReaderConnected]) {
        [self deviceMessage:CLEARENT_AUDIO_JACK_CONNECTED];
    }
    
    if(self.clearentConnection != nil) {
    
       if([ClearentCache isReaderProfileCached]) {
           [ClearentLumberjack logInfo:@"deviceConnected:Connection obj provided and Reader Profile cached. Skip communication with reader"];
       } else {
           [ClearentLumberjack logInfo:@"deviceConnected:Connection obj provided and Reader Profile not cached. Get dsn,kernel,and firmware version"];
           [self setReaderProfile];
       }
    } else {
        [ClearentLumberjack logInfo:@"deviceConnected:No connection obj provided. Get dsn,kernel,and firmware version"];
        [self setReaderProfile];
    }
    
    if ([self.publicDelegate respondsToSelector:@selector(deviceConnected)]) {
        [self.publicDelegate deviceConnected];
    }
    
    if(!self.autoConfiguration && !self.contactlessAutoConfiguration) {
        [self deviceMessage:CLEARENT_READER_CONFIGURED_MESSAGE];
    } else {
        [self applyClearentConfiguration];
    }
}

- (void) setReaderProfile {

    self.deviceSerialNumber = [self getDeviceSerialNumber];
    self.firmwareVersion = [self getFirmwareVersion];
    self.kernelVersion = [self getKernelVersion];
    
}

-(void) applyClearentConfiguration {
    [ClearentLumberjack logError:@"⚠️ applyClearentConfiguration"];
    [self deviceMessage:CLEARENT_DEVICE_CONNECTED_WAITING_FOR_CONFIG];
    [_clearentConfigurator configure:self.kernelVersion deviceSerialNumber:self.deviceSerialNumber autoConfiguration:self.autoConfiguration contactlessAutoConfiguration:self.contactlessAutoConfiguration];
}

- (NSString *) getFirmwareVersion {
    NSString *firmwareVersion = CLEARENT_INVALID_FIRMWARE_VERSION;
    return firmwareVersion;
}


- (NSString *) getKernelVersion {
    return KERNEL_VERSION;
}

- (NSString*) getDeviceSerialNumber {

    [self setDeviceSerialNumberWhenConnectedAndProvided];

    if(self.deviceSerialNumber == nil) {
        NSString *deviceSerialNumber = [self getDeviceSerialNumberFromReader ];

        if(deviceSerialNumber != nil) {
            [ClearentCache cacheCurrentDeviceSerialNumber:deviceSerialNumber];
            return deviceSerialNumber;
        }
    } else {
        return self.deviceSerialNumber;
    }

    [ClearentLumberjack logError:@"⚠️ FAILED TO IDENTIFY DSN. USE ALL NINES"];

    return DEVICE_SERIAL_NUMBER_PLACEHOLDER;
}

- (void) setDeviceSerialNumberWhenConnectedAndProvided {

    if(self.clearentConnection != nil && [_idTechSharedInstance isConnected]) {

       if(self.clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil && ![self.clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]) {

        NSString *fullIdTechFriendlyName = [ClearentConnection createFullIdTechFriendlyName:self.clearentConnection.lastFiveDigitsOfDeviceSerialNumber];

        [ClearentCache cacheCurrentDeviceSerialNumber:fullIdTechFriendlyName];

        self.deviceSerialNumber = fullIdTechFriendlyName;
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Connected with provided last 5 of dsn %@%@", @" friendlyName ", self.deviceSerialNumber]];

      } else if(self.clearentConnection.fullFriendlyName != nil && ![self.clearentConnection.fullFriendlyName isEqualToString:@""]) {

        [ClearentCache cacheCurrentDeviceSerialNumber:self.clearentConnection.fullFriendlyName];
        self.deviceSerialNumber = self.clearentConnection.fullFriendlyName;
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Conncted with provided full friendlyName %@%@", @" friendlyName ", self.deviceSerialNumber]];

      }
    }

}

- (NSString *) getDeviceSerialNumberFromReader {

    NSString *firstTenOfDeviceSerialNumber;

    if([_idTechSharedInstance isConnected]) {
        NSString *result;
        [ClearentLumberjack logInfo:@"ASKING READER FOR DSN"];
        RETURN_CODE config_getSerialNumberRt = [_idTechSharedInstance config_getSerialNumber:&result];
        if (RETURN_CODE_DO_SUCCESS == config_getSerialNumberRt) {
            if (result != nil && [result length] >= 10) {
                firstTenOfDeviceSerialNumber = [result substringToIndex:10];
            } else {
                firstTenOfDeviceSerialNumber = result;
            }
            NSString *logErrorMessage =[NSString stringWithFormat:@"DSN FOUND %@",firstTenOfDeviceSerialNumber];
            [ClearentLumberjack logInfo:logErrorMessage];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"getDeviceSerialNumberFromReader fail %@",[_idTechSharedInstance device_getResponseCodeString:config_getSerialNumberRt]];
            [ClearentLumberjack logError:logErrorMessage];
        }
    } else {
        [ClearentLumberjack logError:@"CANNOT ASK FOR DSN BECAUSE READER IS DISCONNECTED"];
    }


    return firstTenOfDeviceSerialNumber;
}

-(void) deviceDisconnected {
    
    if(self.clearentConnection != nil) {
        
        if (self.clearentConnection.connectionType == CLEARENT_BLUETOOTH && (self.clearentConnection.connectToFirstBluetoothFound || [self.clearentConnection isDeviceKnown])) {
            [self deviceMessage:CLEARENT_BLUETOOTH_DISCONNECTED];
        } else if (self.clearentConnection.connectionType == CLEARENT_AUDIO_JACK) {
            [self deviceMessage:CLEARENT_AUDIO_JACK_DISCONNECTED];
        }
        
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"%@%@", @"connected ", [self.clearentConnection createLogMessage]]];
        
    }
        
    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Device disconnected"]];
    
    if ([self.publicDelegate respondsToSelector:@selector(deviceDisconnected)]) {
        [self.publicDelegate deviceDisconnected];
    }
    
}

- (void) deviceMessage:(NSString*)message {
    
    if(message == nil) {
        [ClearentLumberjack logInfo:@"deviceMessage:message nil"];
        return;
    }
    
    if(([message isEqualToString:@""] || [message isEqualToString:@" "])) {
        [ClearentLumberjack logInfo:@"deviceMessage:No Message"];
        return;
    }
    
    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"%@:%@", @"deviceMessage", message]];
    
    if([message isEqualToString:CLEARENT_READER_CONFIGURED_MESSAGE]) {
        [ClearentLumberjack logInfo:@"➡️ Framework notified reader is ready"];
        self.configured = YES;
        
        if(self.runStoredPaymentAfterConnecting) {
            self.runStoredPaymentAfterConnecting = FALSE;
            [self.callbackObject performSelector:self.runTransactionSelector];
        }
        return;
    }

    if([message isEqualToString:@"RETURN_CODE_SDK_BUSY_MSR"]) {
        return;
    }
    
    if([message isEqualToString:@"POWERING UNIPAY"]) {
        if ([self.publicDelegate respondsToSelector:@selector(deviceMessage:)]) {
            [self.publicDelegate deviceMessage:CLEARENT_POWERING_UP];
        }
        return;
    }
    
    if([message isEqualToString:@"RETURN_CODE_LOW_VOLUME"]) {
        if ([self.publicDelegate respondsToSelector:@selector(deviceMessage:)]) {
            [self.publicDelegate deviceMessage:CLEARENT_AUDIO_JACK_LOW_VOLUME];
        }
        return;
    }
    
    //TODO ugly solution. we need to stop idtech messages being sent back if we know we are in the middle of processing a successful read.
    
    if((processingCurrentRequest
        || [message isEqualToString:CLEARENT_PLEASE_WAIT]
        || [message isEqualToString:CLEARENT_CARD_READ_OK_TO_REMOVE_CARD]
        || [message isEqualToString:CLEARENT_TRANSACTION_PROCESSING]
        || [message isEqualToString:CLEARENT_TRANSACTION_AUTHORIZING])) {
        transactionIsInProcess = YES;
    }

    //IDTech framework will never return timeout when its in the middle of a transaction. We have other errors to account for this.
    //This timeout is the result of the timer we have that wraps the entire transaction to account for a scenario where the
    //idtech framework cannot tell us to timeout. Ex- user inserts card but reader does not recognize and cannot report
    if(transactionIsInProcess &&
       ([message isEqualToString:CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR]
        || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE]
        || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE2])) {
        [ClearentLumberjack logInfo:@"deviceMessage:Dont callback with timeout message. Transaction is in process"];
        return;
    }
    
    if(([message isEqualToString:CLEARENT_UNABLE_TO_GO_ONLINE] || [message isEqualToString:CLEARENT_MSD_CONTACTLESS_UNSUPPORTED] || [message isEqualToString:CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR])) {
        [self cancelTransaction];
    }
    
    if(message != nil && ([message isEqualToString:@"Timeout"] || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE2] || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE2] || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE] || [message isEqualToString:CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR])) {
        if(userNotifiedOfTimeOut) {
            return;
        }
    }
    
    if([message containsString:@"BLE DEVICE FOUND"]) {
        [_clearentDeviceConnector handleBluetoothDeviceFound:message];
    } else {
        if ([self.publicDelegate respondsToSelector:@selector(deviceMessage:)]) {
            [self.publicDelegate deviceMessage:message];
        }
        [self sendFeedback:message];
    }
}

- (void) disableCardRemovalTimer {
    if(monitorCardRemovalTimer != nil) {
        [monitorCardRemovalTimer invalidate];
    }
}

- (void) startFinalFeedbackMonitor:(int) timeout {
    
     SEL monitorCardRemovalSelector = @selector(monitorCardRemoval);
    
     monitorCardRemovalTimer = [NSTimer scheduledTimerWithTimeInterval:timeout + 1 target:self selector:monitorCardRemovalSelector userInfo:nil repeats:false];
    
}

- (void) monitorCardRemoval {
    @try {
        ICCReaderStatus* response;
        RETURN_CODE icc_getICCReaderStatusRt = [_idTechSharedInstance icc_getICCReaderStatus:&response];
        if(RETURN_CODE_DO_SUCCESS == icc_getICCReaderStatusRt) {
            if(response->cardSeated) {
               [self deviceMessage:CLEARENT_CARD_INSERTED];
               [ClearentLumberjack logInfo:@"monitorCardRemoval card is seated"];
            }
        }
    } @catch (NSException *exception) {
        [ClearentLumberjack logInfo:@"monitorCardRemoval:Failed to retrieve the icc reader status"];
    } @finally {
        if(!userNotifiedOfTimeOut && [monitorCardRemovalTimer isValid]) {
            [self deviceMessage:CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR];
        }
    }
}


- (void) sendFeedback:(NSString*) message {

    if(message != nil && ([message isEqualToString:@"Timeout"]
        || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE2]
        || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE]
        || [message isEqualToString:CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR])) {
        
        if(userNotifiedOfTimeOut) {
            return;
        } else {
            userNotifiedOfTimeOut = YES;
        }
    }
    
    ClearentFeedback *clearentFeedback = [ClearentFeedback createFeedback:message];

    if(clearentFeedback.message != nil
       && ![clearentFeedback.message isEqualToString:@""]
       && ![clearentFeedback.message isEqualToString:@" "]) {
        
        [self disableCardRemovalTimerWhenFeedback:clearentFeedback];
        
        if(processingCurrentRequest
           && ([clearentFeedback.message isEqualToString:@"TERMINATED"]
           || ![clearentFeedback.message isEqualToString:@"TERMINATE"])) {
            [ClearentLumberjack logInfo:@"CLEARENT PROCESSING STARTED. SUPPRESS TERMINATED AND TERMINATE"];
            return;
        }
        
        if([clearentFeedback.message containsString:@"TRANSACTION FAILED"]) {
            [ClearentLumberjack logInfo: [NSString stringWithFormat:@"ENHANCED MSG from %@ to %@", clearentFeedback.message, @"Try again or use a different card"]];
            clearentFeedback.message = @"Try again or use a different card";
            [self feedback:clearentFeedback];
        } else if(nil != _clearentVP3300Configuration && _clearentVP3300Configuration.enableEnhancedFeedback) {
            NSString *enhancedString = [enhancedMessages objectForKey:clearentFeedback.message];
            if(nil != enhancedString) {
                if(![enhancedString isEqualToString:@"SUPPRESS"]) {
                    [ClearentLumberjack logInfo: [NSString stringWithFormat:@"ENHANCED MSG from %@ to %@", clearentFeedback.message, enhancedString]];
                    clearentFeedback.message = enhancedString;
                    [self feedback:clearentFeedback];
                }
            } else {
                [ClearentLumberjack logInfo: [NSString stringWithFormat:@"NO ENHANCED MSG %@", clearentFeedback.message]];
                [self feedback:clearentFeedback];
            }
        } else {
            [self feedback:clearentFeedback];
        }
            
    }
    
}

- (void) disableCardRemovalTimerWhenFeedback:(ClearentFeedback*)clearentFeedback {
    
    if(processingCurrentRequest || transactionIsInProcess) {
        [self disableCardRemovalTimer];
    } else if(clearentFeedback.message != nil
       && !([clearentFeedback.message isEqualToString:@""] || [clearentFeedback.message isEqualToString:@" "])
       && (clearentFeedback.feedBackMessageType == 4
           || [clearentFeedback.message isEqualToString:CLEARENT_CARD_READ_OK_TO_REMOVE_CARD]
           || [clearentFeedback.message isEqualToString:CLEARENT_TRANSLATING_CARD_TO_TOKEN]
           || [clearentFeedback.message isEqualToString:CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE])) {
        
        [self disableCardRemovalTimer];
        
    }
  
}

- (void) feedback:(ClearentFeedback*)clearentFeedback {
    if ([self.publicDelegate respondsToSelector:@selector(feedback:)]) {
        [self.publicDelegate feedback:clearentFeedback];
    }
}

                          
- (void) handleContactlessError:(NSString*)contactlessError emvData:(IDTEMVData*)emvData {
    
    if(contactlessError == nil || [contactlessError isEqualToString:@""] || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_NONE]) {
        return;
    }

    [self cancelTransaction];

    if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_COLLISION_ERROR]) {
        [self deviceMessage:CLEARENT_TAP_PRESENT_ONE_CARD_ONLY];
        return;
    }

    NSString *errorMessage;
    if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_BLOCKED]) {
        [self deviceMessage:CLEARENT_CARD_BLOCKED];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_EXPIRED]) {
        [self deviceMessage:CLEARENT_CARD_EXPIRED];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_UNSUPPORTED]) {
        [self deviceMessage:CLEARENT_CARD_UNSUPPORTED];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_DID_NOT_RESPOND]) {
        [self retryContactless];
        return;
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_GENERATED_AAC]) {
        [ClearentLumberjack logError:@"handleContactlessError: aac generated"];
        [self sendDeclineReceipt:emvData];
        return;
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_SSA_OR_DDA_FAILED]) {
        [ClearentLumberjack logError:@"handleContactlessError: ssa or dda failed"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_MISSING_CA_PUBLIC_KEY ]) {
        [ClearentLumberjack logError:@"handleContactlessError: contactless ca public key not found"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_FAILED_TO_RECOVER_ISSUER_PUBLIC_KEY]) {
        [ClearentLumberjack logError:@"handleContactlessError: failed to recover issuer public key"];
        errorMessage = @"DECLINED";
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_GO_TO_CONTACT_INTERFACE]) {
        [ClearentLumberjack logError:@"handleContactlessError: go to contact interface"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_GO_TO_OTHER_INTERFACE]) {
        [ClearentLumberjack logError:@"handleContactlessError: go to other interface"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_GO_TO_MAGSTRIPE_INTERFACE]) {
        [ClearentLumberjack logError:@"handleContactlessError: go to magstripe interface"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_AMOUNT_OVER_MAXIMUM_LIMIT]) {
        [self deviceMessage:CLEARENT_TAP_OVER_MAX_AMOUNT];
    } else {
        errorMessage = @"";
    }
    
    [ClearentLumberjack logInfo:errorMessage];
    [self startContactlessFallbackToContact: errorMessage];
}

-(void) startContactlessFallbackToContact: (NSString*) errorMessage {
    
    [NSThread sleepForTimeInterval:0.3f];
    
    if(![_idTechSharedInstance isConnected]) {
        [self deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        return;
    }

    NSString *fullErrorMessage;
    
    if(errorMessage != nil && ![errorMessage isEqualToString:@""]) {
        fullErrorMessage = [NSString stringWithFormat:@"%@%@%@", @"TAP FAILED. ", errorMessage, @". INSERT/SWIPE"];
    } else {
        fullErrorMessage = CLEARENT_TAP_FAILED_INSERT_SWIPE;
    }

    RETURN_CODE emvStartRt =  [_idTechSharedInstance emv_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];
    
    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
        [self deviceMessage:fullErrorMessage];
    } else {
        NSString *logErrorMessage =[NSString stringWithFormat:@"startContactlessFallbackToContact %@%@",[_idTechSharedInstance device_getResponseCodeString:emvStartRt], fullErrorMessage];
        [ClearentLumberjack logInfo:logErrorMessage];
        [self deviceMessage:CLEARENT_TAP_FAILED_INSERT_CARD_FIRST];
    }
}

-(void) retryContactless {
    [NSThread sleepForTimeInterval:0.3f];
    if(![_idTechSharedInstance isConnected]) {
        [self deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        return;
    }

    [ClearentLumberjack logInfo:@"retryContactless:device_startTransaction"];

    RETURN_CODE emvStartRt;
    emvStartRt =  [_idTechSharedInstance device_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];

    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
        [self deviceMessage:CLEARENT_CONTACTLESS_RETRY_MESSAGE];
    } else {
        [NSThread sleepForTimeInterval:0.2f];
        emvStartRt =  [_idTechSharedInstance device_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];
        if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
            [self deviceMessage:CLEARENT_CONTACTLESS_RETRY_MESSAGE];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"retryContactless %@",[_idTechSharedInstance device_getResponseCodeString:emvStartRt]];
            [ClearentLumberjack logInfo:logErrorMessage];
            [self deviceMessage:CLEARENT_GENERIC_CONTACTLESS_FAILED];
        }
    }
}

-(void) restartSwipeIn2In1Mode:(IDTMSRData*) cardData {
    
    [NSThread sleepForTimeInterval:0.3f];
    if(![_idTechSharedInstance isConnected]) {
        [self deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        return;
    }

    [self cancelTransaction];

    [ClearentLumberjack logInfo:@"restartSwipeIn2In1Mode:emv_startTransaction"];

    RETURN_CODE emvStartRt;
    emvStartRt =  [_idTechSharedInstance emv_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];

    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
        [self sendSwipeErrorMessage:cardData];
    } else {
        [ClearentLumberjack logInfo:@"restartSwipeIn2In1Mode:try emv_startTransaction one more time after initial failure"];
        [NSThread sleepForTimeInterval:0.2f];
        emvStartRt =  [_idTechSharedInstance emv_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];
        if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
            [self sendSwipeErrorMessage:cardData];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"restartSwipeIn2In1Mode %@",[_idTechSharedInstance device_getResponseCodeString:emvStartRt]];
            [ClearentLumberjack logInfo:logErrorMessage];
            [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
        }
    }
    
}

-(void) restartSwipeOnly:(IDTMSRData*) cardData {
    [NSThread sleepForTimeInterval:0.3f];
    if(![_idTechSharedInstance isConnected]) {
        [self deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        return;
    }

    [self cancelTransaction];

    [ClearentLumberjack logInfo:@"restartSwipeOnly:msrSwipe"];

    RETURN_CODE msr_startMSRSwipeRt = [_idTechSharedInstance msr_startMSRSwipe];

    if(RETURN_CODE_OK_NEXT_COMMAND == msr_startMSRSwipeRt || RETURN_CODE_DO_SUCCESS == msr_startMSRSwipeRt) {
        [self sendSwipeErrorMessage:cardData];
    } else {
        [ClearentLumberjack logInfo:@"restartSwipeOnly:try msr_startMSRSwipe one more time after initial failure"];
        [NSThread sleepForTimeInterval:0.2f];
        msr_startMSRSwipeRt = [_idTechSharedInstance msr_startMSRSwipe];
        if(RETURN_CODE_OK_NEXT_COMMAND == msr_startMSRSwipeRt || RETURN_CODE_DO_SUCCESS == msr_startMSRSwipeRt) {
            [self sendSwipeErrorMessage:cardData];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"restartSwipeOnly %@",[_idTechSharedInstance device_getResponseCodeString:msr_startMSRSwipeRt]];
            [ClearentLumberjack logInfo:logErrorMessage];
            [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
        }
    }
}

- (void) sendSwipeErrorMessage:(IDTMSRData*) cardData {
    if(!userToldToUseChipReader && cardData != nil && cardData.iccPresent) {
        [self deviceMessage:CLEARENT_CHIP_FOUND_ON_SWIPE];
        userToldToUseChipReader = true;
    } else if (cardData != nil && cardData.event == EVENT_MSR_DATA_ERROR) {
        [self deviceMessage:CLEARENT_USER_ACTION_SWIPE_FAIL_TRY_INSERT_OR_SWIPE];
    } else if(userToldToUseMagStripe) {
        [self deviceMessage:CLEARENT_USE_MAGSTRIPE];
    } else if((cardData != nil && cardData.iccPresent) || previousSwipeWasCardWithChip || userToldToUseChipReader) {
        [self deviceMessage:CLEARENT_CHIP_FOUND_ON_SWIPE];
    } else {
        [self deviceMessage:CLEARENT_TRY_MSR_AGAIN];
    }
}

- (void) swipeMSRData:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && (cardData.track2 != nil || cardData.encTrack2 != nil)) {
        if(cardData.iccPresent && !previousSwipeWasCardWithChip && _originalEntryMode != 81 && !userToldToUseMagStripe) {
            [self restartSwipeIn2In1Mode:cardData];
            previousSwipeWasCardWithChip = YES;
            return;
        }
        if(previousSwipeWasCardWithChip) {
            [self swipeMSRDataFallback:cardData];
        } else {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
            if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
                if(![self isSwipeHandledInEmvFlow]) {
                  [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
                } else {
                  [self restartSwipeIn2In1Mode:cardData];
                }
            } else {
                if(!sentCardReadSuccessMessage) {
                    [self deviceMessage:CLEARENT_CARD_READ_SUCCESS];
                    sentCardReadSuccessMessage = YES;
                }
                [self createTransactionToken:clearentTransactionTokenRequest];
            }
        }
    } else if (cardData != nil && cardData.event == EVENT_MSR_DATA_ERROR) {
        [self restartSwipeIn2In1Mode:cardData];
    } else if (cardData != nil && cardData.event == EVENT_MSR_TIMEOUT) {
        [self deviceMessage:CLEARENT_TIMEOUT_ERROR_RESPONSE];
    } else if(userToldToUseMagStripe) {
        [self restartSwipeOnly:cardData];
    } else if(cardData != nil && ![self isSwipeHandledInEmvFlow]) {
        [self restartSwipeIn2In1Mode:cardData];
    } else if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA) {
        [self restartSwipeIn2In1Mode:cardData];
    }
}


//This callback relies on the reader being configured to send LCD and/or Buzzer events to external source.
- (void) ctlsEvent:(Byte)event scheme:(Byte)scheme  data:(Byte)data {
    
    switch (event) {
            //LEDs
        case 0x01:
            break;
            //Buzzer messaging, but only if external buzzer is configured
            case 0x02:
               {
        
            switch (data)
            {
                case 0x10:
                    //  [self deviceMessage:@"Short Beep No Change "];
                    break;
                case 0x11:
                    //  [self deviceMessage:@"Short Beep No Change"];
                    break;
                case 0x12:
                    [self deviceMessage:CLEARENT_CARD_READ_ERROR];
                    break;
                case 0x13:
                    [self deviceMessage:CLEARENT_SEE_PHONE];
                    break;
                case 0x20:
                    // [self deviceMessage:@"200ms Beep"];
                    //workaround for Triple Beep not coming back. counter resets between transactions
                    countNumberOfShortBeeps++;
                    if(countNumberOfShortBeeps == 3) {
                        countNumberOfShortBeeps = 0;
                        [self deviceMessage:CLEARENT_SEE_PHONE];
                    }
                    break;
                case 0x21:
//                    if(countNumberOfShortBeeps == 0) {
//                        [self deviceMessage:CLEARENT_CARD_READ_SUCCESS];
//                         sentCardReadSuccessMessage = YES;
//                    }
                    break;
                case 0x22:
//                    if(countNumberOfShortBeeps == 0) {
//                        [self deviceMessage:CLEARENT_CARD_READ_SUCCESS];
//                        sentCardReadSuccessMessage = YES;
//                    }
                    break;
            }
                   break;
               }
            case 0x03:
        {
//            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"LCD Event = %i",(int)data]];
//            NSString* line1=nil;
//            NSString* line2=nil;
//            [IDTUtility retrieveCTLSMessage:scheme lang:0 messageID:data line1:&line1 line2:&line2];
//            [self deviceMessage:[NSString stringWithFormat:@"LCD REVIEW %@",line1]];
//            if(line1 != nil &&
//                ![line1 isEqualToString:@""]
//                && [line1 isEqualToString:@"Processing"]) {
//                contactlessIsProcessing  = YES;
//            }
                    
            break;
        }
            case 0x04:
            case 0x05:
            case 0x06:
            case 0x07:
            case 0x08:
            case 0x09:
            case 0x10:
            case 0x11:
                {
//                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"OTHERs LCD Event = %i",(int)data]];
//                    NSString* line1=nil;
//                    NSString* line2=nil;
//                    [IDTUtility retrieveCTLSMessage:scheme lang:0 messageID:data line1:&line1 line2:&line2];
//                    [self deviceMessage:[NSString stringWithFormat:@"OTHERS REVIEW %@",line1]];
//                    if(line1 != nil &&
//                        ![line1 isEqualToString:@""]
//                        && [line1 isEqualToString:@"Try Another Interface"]) {
//                        contactlessIsProcessing  = YES;
//                    }
                            
                    break;
                }
        default:
            break;
    }
}

//- (void) gen2Data:(NSData*)tlv {
//    NSLog(@"gen2Data");
//}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        clearentTransactionTokenRequest.encrypted = true;
        clearentTransactionTokenRequest.maskedTrack2Data = cardData.track2;
        clearentTransactionTokenRequest.track2Data = [IDTUtility dataToHexString:cardData.encTrack2].uppercaseString;
        clearentTransactionTokenRequest.ksn = [IDTUtility dataToHexString:cardData.KSN].uppercaseString;
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest.encrypted = false;
        clearentTransactionTokenRequest.track2Data = cardData.track2.uppercaseString;
    }
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    if(clearentTransactionTokenRequest.deviceSerialNumber == nil) {
        clearentTransactionTokenRequest.deviceSerialNumber = cardData.RSN;
    }
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.emv = false;
    return clearentTransactionTokenRequest;
}

- (void) swipeMSRDataFallback:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && (cardData.track2 != nil || cardData.encTrack2 != nil)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestFallbackSwipe:cardData];
        if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
             if(![self isSwipeHandledInEmvFlow]) {
                 [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
             } else if(userToldToUseMagStripe) {
                [self restartSwipeOnly:cardData];
             } else {
                [self restartSwipeIn2In1Mode:cardData];
             }
        } else {
            if(!sentCardReadSuccessMessage) {
                [self deviceMessage:CLEARENT_CARD_READ_SUCCESS];
                sentCardReadSuccessMessage = YES;
            }
            [self createTransactionToken:clearentTransactionTokenRequest];
        }
    } else if (cardData != nil && cardData.event == EVENT_MSR_TIMEOUT) {
        [self deviceMessage:CLEARENT_TIMEOUT_ERROR_RESPONSE];
    } else {
        [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
        return;
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestFallbackSwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
    NSMutableDictionary *outgoingTags = [NSMutableDictionary new];
    [self addRequiredTags: outgoingTags];
    NSData *tagsAsNSData = [IDTUtility DICTotTLV:outgoingTags];
    NSString *tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    int entryMode = _originalEntryMode;
    if(_originalEntryMode == 0 && (previousSwipeWasCardWithChip || userToldToUseMagStripe)) {
        entryMode = 80;
    }
    NSString *tlvInHexWith9F39 = [NSString stringWithFormat:@"%@%@%d", tlvInHex, @"9F3901",entryMode];
    clearentTransactionTokenRequest.emv = false;
    clearentTransactionTokenRequest.tlv = tlvInHexWith9F39.uppercaseString;

    return clearentTransactionTokenRequest;
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
  
    if(RETURN_CODE_CTLS_MSR_CANCELLED_BY_CARD_INSERT == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:CTLS/MSR cancelled due to card insertion"];
        return;
    } else if(RETURN_CODE_CANNOT_START_CONTACT_EMV == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:cannot start emv transaction at this time"];
        return;
    } else if(EMV_RESULT_CODE_V2_SWIPE_NON_ICC == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:swipe captured from NON ICC"];
    } else if(EMV_RESULT_CODE_V2_SWIPE_NON_ICC == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:swipe captured from NON ICC"];
    } else if(EMV_RESULT_CODE_FALLBACK_TO_CONTACT == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:emvdata captured from ICC"];
    } else if(EMV_RESULT_CODE_CTLS_TERMINATE_TRY_ANOTHER == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:ctls transaction terminated"];
        return;
    } else if(RETURN_CODE_OK_NEXT_COMMAND == error || RETURN_CODE_DO_SUCCESS == error || RETURN_CODE_DO_SUCCESS == error || RETURN_CODE_NEO_SUCCESS == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:error is a RETURN_CODE:success"];
    } else if(RETURN_CODE_ERR_DISCONNECT == error || RETURN_CODE_ERR_DISCONNECT_ == error) {
        [ClearentLumberjack logInfo:@"emvTransactionData:error is a RETURN_CODE:disconnected"];
         [self deviceMessage:CLEARENT_DISCONNECT_WHILE_TRANSACTION];
         return;
    } else {
        @try{
            NSString *deviceResponseCodeString = [_idTechSharedInstance device_getResponseCodeString:error];
            if(deviceResponseCodeString != nil && ![deviceResponseCodeString isEqualToString:@""] && ![deviceResponseCodeString containsString:@"no error file found"]) {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"EMV Transaction Data Response: = %@",deviceResponseCodeString]];
            } else {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"emvTransactionData unknown error: = %d",error]];
            }
        }
        @catch (NSException *e) {
            [ClearentLumberjack logInfo:@"Unknown EMV Transaction Data Response"];
        }
    }
    

    if([self isEmvErrorHandled:emvData error:error]) {
        return;
    }

    int entryMode = [self getEntryMode: emvData];

    if(entryMode == 0 && emvData.cardType != 1) {
        [ClearentLumberjack logError:@"No entryMode defined"];
        return;
    }

    if (emvData.cardType == 1 && entryMode == CONTACTLESS_MAGNETIC_SWIPE) {
        [ClearentLumberjack logInfo:@"🙅🙅MSD CONTACTLESS NOT SUPPORTED🙅🙅"];
        [self deviceMessage:CLEARENT_MSD_CONTACTLESS_UNSUPPORTED];
        return;
    }
    
    [self convertIDTechCardToClearentTransactionToken:emvData entryMode:entryMode];

    _originalEntryMode = entryMode;
}

- (int) getEntryMode: (IDTEMVData*) emvData {
    int entryMode = 0;
    if(emvData != nil && emvData.unencryptedTags != nil) {
        NSData *entryModeData = [emvData.unencryptedTags objectForKey:ENTRY_MODE_EMV_TAG];
        if(entryModeData != nil) {
            NSString *entryModeString = [IDTUtility dataToHexString:entryModeData];
            if(entryModeString != nil) {
                entryMode = entryModeString.intValue;
            }
        }
    }
    return entryMode;
}

- (BOOL) isEmvErrorHandled:  (IDTEMVData*)emvData error:(int)error {
    BOOL emvErrorHandled = NO;

    if (emvData != nil && emvData.cardType != 1 && emvData.resultCodeV2 != EMV_RESULT_CODE_V2_NO_RESPONSE) {
       [ClearentLumberjack logInfo:[NSString stringWithFormat:@"EMV_RESULT_CODE_V2_response = %2X",emvData.resultCodeV2]];
    }

    if (error == 8) {
        emvErrorHandled = YES;
        [self deviceMessage:CLEARENT_TIMEOUT_ERROR_RESPONSE];
    } else if(emvData == nil) {
        emvErrorHandled = YES;
    } else if (emvData.cardType == 1 && !self.contactless) {
        emvErrorHandled = YES;
        [self deviceMessage:CLEARENT_CONTACTLESS_UNSUPPORTED];
    } else if(emvData != nil && emvData.cardType == 1) {
        NSString* contactlessErrorCodeData = [self getContactlessErrorCode: emvData.unencryptedTags];
        if([self isContactlessError: contactlessErrorCodeData]) {
            [self handleContactlessError: contactlessErrorCodeData emvData:emvData];
            emvErrorHandled = YES;
        }
    } else if (emvData.cardType == 1 && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_CVM_CODE_IS_NOT_SUPPORTED) {
        emvErrorHandled = YES;
        [self deviceMessage:CLEARENT_CVM_UNSUPPORTED];
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_DECLINED_OFFLINE) {
        emvErrorHandled = YES;
        [self deviceMessage:CLEARENT_CARD_OFFLINE_DECLINED];
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_CARD_ERROR) {
        emvErrorHandled = YES;
        [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
    } else if(emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APP_NO_MATCHING) {
         _originalEntryMode = 81;
         [self deviceMessage:CLEARENT_CHIP_UNRECOGNIZED];
         SEL startFallbackSwipeSelector = @selector(startFallbackSwipe);
         [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:startFallbackSwipeSelector userInfo:nil repeats:false];
         emvErrorHandled = YES;
    } else if(emvData.resultCodeV2 == EMV_RESULT_CODE_V2_CARD_REJECTED) {
         [self deviceMessage:CLEARENT_BAD_CHIP];
        SEL startFallbackSwipeSelector = @selector(startFallbackSwipe);
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:startFallbackSwipeSelector userInfo:nil repeats:false];
        emvErrorHandled = YES;
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_TIME_OUT) {
         emvErrorHandled = YES;
         [self deviceMessage:CLEARENT_TIMEOUT_ERROR_RESPONSE];
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
         emvErrorHandled = YES;
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
         emvErrorHandled = YES;
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_DECLINED) {
         //Do not send to remote log.
         emvErrorHandled = YES;
     } else if (emvData.cardData != nil && (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_SWIPE_NON_ICC || emvData.resultCodeV2 == EMV_RESULT_CODE_MSR_SWIPE_CAPTURED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_USE_MAGSTRIPE)) {
           if(emvData.cardData.encTrack2 == nil && emvData.cardData.track2 == nil) {
               if(userToldToUseMagStripe) {
                   [self restartSwipeOnly:emvData.cardData];
               } else {
                   [self restartSwipeIn2In1Mode:emvData.cardData];
               }
               emvErrorHandled = YES;
           } else if(!userToldToUseMagStripe && emvData.cardData.iccPresent && !previousSwipeWasCardWithChip && _originalEntryMode != 81) {
               previousSwipeWasCardWithChip = YES;
               [self restartSwipeIn2In1Mode:emvData.cardData];
               emvErrorHandled = YES;
           }
      }
    
    return emvErrorHandled;
}

- (void) convertIDTechCardToClearentTransactionToken: (IDTEMVData*)emvData entryMode:(int) entryMode {
    @try {
        if (emvData.cardData != nil
            && (emvData.resultCodeV2 == EMV_RESULT_CODE_MSR_SWIPE_CAPTURED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_SWIPE_NON_ICC)) {
           if(_originalEntryMode == 81 || previousSwipeWasCardWithChip || userToldToUseChipReader) {
                [self swipeMSRDataFallback:emvData.cardData];
            } else if(entryMode == SWIPE) {
                if([self isSwipeHandledInEmvFlow]) {
                   [self swipeMSRData:emvData.cardData];
                } else {
                   [ClearentLumberjack logInfo:@"Skipping swipe call in emv data flow"];
                }
            } else if(isSupportedEmvEntryMode(entryMode)) {
                ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
                if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
                    //it is possible with the latest idtech framework swipe changes this was starting a new transaction while another was still in flight.
                    if(![self isSwipeHandledInEmvFlow]) {
                        [ClearentLumberjack logInfo:@"Skipping bad swipe in convertIDTechCardToClearentTransactionToken"];
                    } else {
                        [self restartSwipeIn2In1Mode:emvData.cardData];
                    }
                    return;
                }
                if(!sentCardReadSuccessMessage) {
                    [self deviceMessage:CLEARENT_CARD_READ_SUCCESS];
                    sentCardReadSuccessMessage = YES;
                }
                [self createTransactionToken:clearentTransactionTokenRequest];
            } else {
                [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
            }
        } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || emvData.cardType == 1 || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_USE_MAGSTRIPE)) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            if(emvData.cardType == 1 && clearentTransactionTokenRequest.track2Data == nil) {
                [self deviceMessage:CLEARENT_GENERIC_CONTACTLESS_FAILED];
            } else {
                if(!sentCardReadSuccessMessage) {
                    [self deviceMessage:CLEARENT_CARD_READ_OK_TO_REMOVE_CARD];
                }
                
                [self createTransactionToken:clearentTransactionTokenRequest];
            }
        } else {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"convertIDTechCardToClearentTransactionToken: pass through. this means our error handler probably missed something"]];
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat:@"[Error] - %@ %@", exception.name, exception.reason];
        NSLog( @"%@", errorMessage );
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"convertIDTechCardToClearentTransactionToken: Possible Programming Error %@", errorMessage]];
    }
}


- (BOOL) isSwipeHandledInEmvFlow {
    
    BOOL swipeHandledInEmvFlow = YES;
    
    NSString *sdkVersion = [IDT_Device SDK_version];
    //TODO Either this logic needs to handle incremental changes to the version or we need to review all workarounds each time
    //we upgrade the framework.
    if(sdkVersion != nil
       && ([sdkVersion isEqualToString:@"1.1.163.002"])) {
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Swipe is not handled in emv flow for sdk version - %@", sdkVersion]];
        swipeHandledInEmvFlow = NO;
    }
    return swipeHandledInEmvFlow;
}


- (NSString*) getContactlessErrorCode: (NSDictionary*) tags {
    if(tags == nil) {
        return nil;
    }
    NSData* ffee1fData = [tags objectForKey:CONTACTLESS_ERROR_CODE_TAG];
    if(ffee1fData == nil) {
        return nil;
    }
    NSString *ffee1fHex = [IDTUtility dataToHexString:ffee1fData];
    if(ffee1fHex != nil && ![ffee1fHex isEqualToString:@""]) {
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"See Error Code table page 28 of NEO Guide version 125 for first byte meaning. FFEE1F. %@",ffee1fHex]];
    }
    return [ffee1fHex substringWithRange: NSMakeRange (0, 2)];
}

/*
 FFEE1F - See error codes page 28 of neo guide version 125 for first byte explanation
 Byte 1: Error Code.
 (Error Code giving the reason for the failure.)
 Byte 2: SW1
       (Value of SW1 returned by the Card (SW1SW2 is 0000 if SW1 SW2 not available))
 Byte 3: SW2
       (Value of SW2 returned by the Card (SW1SW2 is 0000 if SW1 SW2 not available))
 Byte 4: RF State Code
       (RF State Code indicating exactly where the error occurred in the Reader-Card transaction flow.)
 */
- (BOOL) isContactlessError: (NSString*) ffee1fFirstByte {
    BOOL contactlessError = NO;

    if(ffee1fFirstByte != nil && ![ffee1fFirstByte isEqualToString:@""]) {
        if(![ffee1fFirstByte isEqualToString:CONTACTLESS_ERROR_CODE_NONE] && ![ffee1fFirstByte isEqualToString:CONTACTLESS_ERROR_CODE_PROCESSING_RESTRICTIONS_FAILED]) {
            contactlessError = YES;
        }
    }

    return contactlessError;
}

- (void) startFallbackSwipe {
    
    [self cancelTransaction];
    
    RETURN_CODE startMSRSwipeRt = [_idTechSharedInstance msr_startMSRSwipe];
    if (RETURN_CODE_DO_SUCCESS == startMSRSwipeRt || RETURN_CODE_OK_NEXT_COMMAND == startMSRSwipeRt) {
        [ClearentLumberjack logInfo:@"deviceMessage: start fallback swipe succeeded "];
    } else {
        [ClearentLumberjack logInfo:@"deviceMessage: start fallback swipe failed "];
        [self deviceMessage:CLEARENT_PULLED_CARD_OUT_EARLY];
    }
}

int getEntryMode (NSString* rawEntryMode) {
    if(rawEntryMode == nil || [rawEntryMode isEqualToString:@""]) {
        return 0;
    }
    NSString *entryModeWithoutTags = [rawEntryMode stringByReplacingOccurrencesOfString:@"[\\<\\>]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [rawEntryMode length])];
    return [entryModeWithoutTags intValue];
}

BOOL isSupportedEmvEntryMode (int entryMode) {
    if(entryMode == FALLBACK_SWIPE || entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV) {
        return true;
    }
    return false;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    clearentTransactionTokenRequest.encrypted = false;
    
    NSMutableDictionary *outgoingTags;
    
    if (emvData.cardType == 1) {//contactless
        [self addContactlessCardToClearentTransactionTokenRequest:clearentTransactionTokenRequest emvData:emvData];
        outgoingTags = [emvData.unencryptedTags mutableCopy];
    } else {
        NSDictionary *transactionResultDictionary = [self getRequiredEmvTags];
        if(transactionResultDictionary != nil) {
            outgoingTags = [transactionResultDictionary objectForKey:@"tags"];
            [self addContactCardToClearentTransactionTokenRequest: clearentTransactionTokenRequest transactionResultDictionary:transactionResultDictionary emvData:emvData];
        } else {
            outgoingTags = [emvData.unencryptedTags mutableCopy];
        }
    }
    
    NSData *tagsAsNSData;
    NSString *tlvInHex;
    
    if(emvData.cardData != nil) {
        [self addCardData:clearentTransactionTokenRequest iDTEMVData:emvData];
//    } else if(isEncryptedTransaction(emvData.encryptedTags)) {
//        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.encryptedTags];
//        if(clearentTransactionTokenRequest.track2Data == nil) {
//           NSString *encryptedTrack2 = [IDTUtility dataToHexString:[emvData.encryptedTags objectForKey:IDTECH_DFEF4D_CIPHERTEXT_TAG]];
//           if(encryptedTrack2 != nil && !([encryptedTrack2 isEqualToString:@""])) {
//                clearentTransactionTokenRequest.track2Data = encryptedTrack2.uppercaseString;
//           }
//        }
//        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.unencryptedTags];
//        [self addMaskedData: clearentTransactionTokenRequest maskedTags:emvData.maskedTags];
    } else {
        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.unencryptedTags];
        [self addMaskedData: clearentTransactionTokenRequest maskedTags:emvData.maskedTags];
    }
    
    NSData* ff8105Data = [emvData.unencryptedTags objectForKey:MASTERCARD_GROUP_FF8105_TAG];
    [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8105Data tags:outgoingTags];

    NSData* ff8106Data = [emvData.unencryptedTags objectForKey:MASTERCARD_GROUP_FF8106_TAG];
    [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8106Data tags:outgoingTags];

    [self recordConfiguredReaderFlag: [outgoingTags objectForKey:MERCHANT_NAME_AND_LOCATION_HIJACKED_AS_PRECONFIGURED_FLAG]];
    [self addRequiredTags: outgoingTags];
    [self addApplicationPreferredName:clearentTransactionTokenRequest tags:outgoingTags];

    [self removeInvalidTSYSTags: outgoingTags];
    
    if (emvData.cardType == 1) {
        [self removeInvalidContactlessTags:outgoingTags];
        [self fixContactlessEntryMode:outgoingTags];
    } else {
        [self fixContactEntryMode:outgoingTags];
    }

    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];

    if(clearentTransactionTokenRequest.deviceSerialNumber == nil) {

         if(emvData.cardData != nil && emvData.cardData.RSN != nil) {
             [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Reader Serial Number %@",emvData.cardData.RSN]];
             clearentTransactionTokenRequest.deviceSerialNumber = emvData.cardData.RSN;
         } else {
             NSData* data9F1E = [outgoingTags objectForKey:@"9F1E"];
             if(data9F1E != nil) {
                 clearentTransactionTokenRequest.deviceSerialNumber = [IDTUtility dataToString:data9F1E];
             }
         }
    }
    
    if(outgoingTags != nil) {
    
        tagsAsNSData = [IDTUtility DICTotTLV:outgoingTags];
        tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
        clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
        
    }

    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];

    return clearentTransactionTokenRequest;
}


- (NSDictionary*) getRequiredEmvTags {
    NSDictionary *transactionResultDictionary;
    NSData *tsysTags = [IDTUtility hexToData:@"508E82959A9B9C5F2A9F029F039F1A9F219F269F279F339F349F359F369F379F399F4E4F845F2D5F349F069F129F099F405F369F1E9F105657FF8106FF8105FFEE14FFEE06DFEF4DFFEE12"];
    RETURN_CODE emvRetrieveTransactionResultRt = [_idTechSharedInstance emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
    if(RETURN_CODE_DO_SUCCESS != emvRetrieveTransactionResultRt || transactionResultDictionary == nil) {
        [ClearentLumberjack logInfo:@"Failed to retrieve the Transaction Result Tags"];
    }
    return transactionResultDictionary;
}


- (void) addContactlessCardToClearentTransactionTokenRequest: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest emvData:(IDTEMVData*)emvData {

    [self addMaskedData: clearentTransactionTokenRequest maskedTags:emvData.maskedTags];

    if(isEncryptedTransaction(emvData.encryptedTags)) {

        [self addKSN:clearentTransactionTokenRequest iDTEMVData:emvData];
        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.unencryptedTags];//contactless get from unencrypted
        [self addApplicationPreferredName:clearentTransactionTokenRequest tags:emvData.unencryptedTags];

        if(clearentTransactionTokenRequest.track2Data == nil) {
           NSString *encryptedTrack2FromEncrypted = [IDTUtility dataToHexString:[emvData.encryptedTags objectForKey:IDTECH_DFEF4D_CIPHERTEXT_TAG]];
           if(encryptedTrack2FromEncrypted != nil && !([encryptedTrack2FromEncrypted isEqualToString:@""])) {
                clearentTransactionTokenRequest.track2Data = encryptedTrack2FromEncrypted.uppercaseString;
           } else {
               NSString *encryptedTrack2FromUnencrypted = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:IDTECH_DFEF4D_CIPHERTEXT_TAG]];
               if(encryptedTrack2FromUnencrypted != nil && !([encryptedTrack2FromUnencrypted isEqualToString:@""])) {
                   clearentTransactionTokenRequest.track2Data = encryptedTrack2FromUnencrypted.uppercaseString;
               }
           }
           [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.encryptedTags];
        }

    } else {
        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.unencryptedTags];
    }
}

- (void) addContactCardToClearentTransactionTokenRequest: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest transactionResultDictionary:(NSDictionary*) transactionResultDictionary emvData:(IDTEMVData*)emvData {
    NSDictionary* _tags = [transactionResultDictionary objectForKey:@"tags"];
    NSDictionary*_encTags = [transactionResultDictionary objectForKey:@"encrypted"];
    NSDictionary*_maskedTags = [transactionResultDictionary objectForKey:@"masked"];
    [self addMaskedData: clearentTransactionTokenRequest maskedTags:_maskedTags];
    if(isEncryptedTransaction(_encTags)) {
        [self addTrack2Data: clearentTransactionTokenRequest tags:_encTags];
        [self addKSN:clearentTransactionTokenRequest iDTEMVData:emvData];
        [self addCipherFromRequestedTags:clearentTransactionTokenRequest requestedTags:_tags];
    }
    if(_tags != nil) {
        [self addTrack2Data: clearentTransactionTokenRequest tags:_tags];
        [self addApplicationPreferredName:clearentTransactionTokenRequest tags:_tags];
    }
}

- (void) recordConfiguredReaderFlag: (NSData*) tagData  {
    
    if(tagData != nil) {
        
        NSString *merchantNameAndLocationHijackedAsConfiguredFlag = [IDTUtility dataToHexString:tagData];
        
        if(merchantNameAndLocationHijackedAsConfiguredFlag != nil && [merchantNameAndLocationHijackedAsConfiguredFlag isEqualToString:READER_CONFIGURED_FLAG_LETTER_P_IN_HEX]) {
            [ClearentLumberjack logInfo:@"🤩 🤩 🤩 🤩 🤩 IDTECH READER IS PRECONFIGURED 🤩 🤩 🤩 🤩 🤩"];
        } else {
            
            if(merchantNameAndLocationHijackedAsConfiguredFlag != nil) {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"PRECONFIG CHECK 9f4e value is: %@", merchantNameAndLocationHijackedAsConfiguredFlag]];
            } else {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"PRECONFIG CHECK No 9F4E tag found"]];
            }
            
        }
        
    }
    
}

- (NSMutableDictionary*) createDefaultOutgoingTags: (IDTEMVData*)emvData {
    NSMutableDictionary *outgoingTags;
    if(emvData == nil) {
        [ClearentLumberjack logError:@"outgoing tags nil in createDefaultOutgoingTags"];
        return outgoingTags;
    }
    if (emvData.cardType == 1) {//contactless
        outgoingTags = [emvData.unencryptedTags mutableCopy];
        if(outgoingTags == nil) {
            [ClearentLumberjack logError:@"outgoing tags nil in createDefaultOutgoingTags for contactless"];
        }
    } else {
        NSDictionary *transactionResultDictionary;
        NSData *tsysTags = [IDTUtility hexToData:@"508E82959A9B9C5F2A9F029F039F1A9F219F269F279F339F349F359F369F379F399F4E4F845F2D5F349F069F129F099F405F369F1E9F105657FF8106FF8105FFEE14FFEE06DFEF4DFFEE12"];
        RETURN_CODE emvRetrieveTransactionResultRt = [_idTechSharedInstance emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
        if(RETURN_CODE_DO_SUCCESS == emvRetrieveTransactionResultRt) {
            outgoingTags = [transactionResultDictionary objectForKey:@"tags"];
        } else {
            [ClearentLumberjack logError:@"Failed to retrieve tlv from Device. Default to unencryptedTags"];
            outgoingTags = [emvData.unencryptedTags mutableCopy];
        }
    }
    return outgoingTags;
}

BOOL isEncryptedTransaction (NSDictionary* encryptedTags) {
    if(encryptedTags == nil || [encryptedTags count] == 0) {
        return false;
    }
    return true;
}

- (void) addCardData: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest iDTEMVData:(IDTEMVData*)iDTEMVData {
    if(iDTEMVData.cardData.encTrack2 != nil) {
        clearentTransactionTokenRequest.encrypted = true;
        clearentTransactionTokenRequest.track2Data = [IDTUtility dataToHexString:iDTEMVData.cardData.encTrack2];
        clearentTransactionTokenRequest.maskedTrack2Data = iDTEMVData.cardData.track2;
        clearentTransactionTokenRequest.ksn = [IDTUtility dataToHexString:iDTEMVData.cardData.KSN].uppercaseString;
    } else if(iDTEMVData.cardData.track2 != nil) {
        clearentTransactionTokenRequest.encrypted = false;
        clearentTransactionTokenRequest.track2Data = iDTEMVData.cardData.track2;
    }
    if(iDTEMVData.cardData != nil && iDTEMVData.cardData.RSN != nil) {
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Reader Serial Number %@",iDTEMVData.cardData.RSN]];
        clearentTransactionTokenRequest.deviceSerialNumber = iDTEMVData.cardData.RSN;
    }
}

- (void) addKSN: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest iDTEMVData:(IDTEMVData*)iDTEMVData {
    if(clearentTransactionTokenRequest.ksn == nil && iDTEMVData != nil) {
        NSString *ksn;
        if(iDTEMVData.KSN != nil) {
            ksn = [IDTUtility dataToHexString:iDTEMVData.KSN].uppercaseString;
        }
        if(ksn == nil) {
            ksn = [IDTUtility dataToHexString:[iDTEMVData.unencryptedTags objectForKey:KSN_TAG]];
        }
        if(ksn != nil && !([ksn isEqualToString:@""])) {
            clearentTransactionTokenRequest.ksn = [ksn uppercaseString];
            clearentTransactionTokenRequest.encrypted = true;
        }
    }
}

- (void) addCipherFromRequestedTags: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest requestedTags:(NSDictionary*)tags {

    if(clearentTransactionTokenRequest.track2Data == nil && tags != nil && [tags count] > 0) {
        NSString *encryptedTrack2 = [IDTUtility dataToHexString:[tags objectForKey:IDTECH_DFEF4D_CIPHERTEXT_TAG]];
        if(encryptedTrack2 != nil && !([encryptedTrack2 isEqualToString:@""])) {
             clearentTransactionTokenRequest.track2Data = encryptedTrack2.uppercaseString;
        }
    }
}

- (void) addFromFF81XX: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest ff81XX:(NSData*) ff81XX tags:(NSMutableDictionary*) outgoingTags {
    if (ff81XX != nil && ff81XX.length > 1) {
        NSDictionary* tags = [IDTUtility processTLV:ff81XX];
        NSDictionary*_unencTags = [tags objectForKey:@"tags"];
        NSDictionary*_encTags = [tags objectForKey:@"encrypted"];
        NSDictionary*_maskedTags = [tags objectForKey:@"masked"];

        if(_unencTags != nil) {
            [outgoingTags addEntriesFromDictionary:_unencTags];
            [self addApplicationPreferredName:clearentTransactionTokenRequest tags:_unencTags];
        }
        [self addMaskedData: clearentTransactionTokenRequest maskedTags:_maskedTags];
        [self addTrack2Data: clearentTransactionTokenRequest tags:_encTags];
        if(_unencTags != nil) {
            [self addTrack2Data: clearentTransactionTokenRequest tags:_unencTags];
        }
    }
}

- (void) addTrack2Data: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest tags:(NSDictionary*) tags {
    
    if(clearentTransactionTokenRequest.track2Data == nil && tags != nil && [tags count] > 0) {
        
        NSData *track2Data = [tags objectForKey:TRACK2_DATA_EMV_TAG];
    
        if(track2Data == nil || [track2Data length] == 0) {
            track2Data = [tags objectForKey:TRACK1_DATA_EMV_TAG];
        }
        
        if(track2Data == nil || [track2Data length] == 0) {
            track2Data = [tags objectForKey:TRACK2_DATA_IDTECH_UNENCRYPTED_TAG];
        }
        
        if(track2Data == nil || [track2Data length] == 0) {
            track2Data = [tags objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG];
        }
        
        if(track2Data != nil) {
            if([track2Data isKindOfClass:[NSString class]]) {
                clearentTransactionTokenRequest.track2Data = [IDTUtility dataToString:track2Data];
            } else {
                clearentTransactionTokenRequest.track2Data = [IDTUtility dataToHexString:track2Data];
            }
        }

    }
}

- (void) addMaskedData: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest maskedTags:(NSDictionary*) maskedTags {
    if (maskedTags != nil && clearentTransactionTokenRequest.maskedTrack2Data == nil) {
        NSString *maskedTrack2DataFrom57 = [IDTUtility dataToHexString:[maskedTags objectForKey:TRACK2_DATA_EMV_TAG]];
        if(maskedTrack2DataFrom57 != nil && !([maskedTrack2DataFrom57 isEqualToString:@""])) {
            clearentTransactionTokenRequest.maskedTrack2Data = maskedTrack2DataFrom57.uppercaseString;
        } else {
            NSString *maskedTrack2DataFrom56 = [IDTUtility dataToHexString:[maskedTags objectForKey:TRACK1_DATA_EMV_TAG]];
            if(maskedTrack2DataFrom56 != nil && !([maskedTrack2DataFrom56 isEqualToString:@""])) {
                clearentTransactionTokenRequest.maskedTrack2Data = maskedTrack2DataFrom56.uppercaseString;
            }
        }
    }
}

- (void) addApplicationPreferredName: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest tags:(NSDictionary*) tags {
    if(clearentTransactionTokenRequest.applicationPreferredNameTag9F12 == nil) {
        NSString* tag9F12Value = [IDTUtility dataToString:[tags objectForKey:@"9F12"]];
        if(tag9F12Value != nil && !([tag9F12Value isEqualToString:@""])) {
            clearentTransactionTokenRequest.applicationPreferredNameTag9F12 = tag9F12Value;
        } else {
            NSString* tag50Value = [IDTUtility dataToString:[tags objectForKey:@"50"]];
            if(tag50Value != nil && !([tag50Value isEqualToString:@""])) {
                clearentTransactionTokenRequest.applicationPreferredNameTag9F12 = tag50Value;
            }
        }
    }
}

- (NSString*) getClockDateAsYYMMDDInHex {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    return dateString;
}

- (NSString*) getTimeAsHHMMSSInHex {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    [formatter setTimeStyle:NSDateFormatterFullStyle];
    [formatter setDateFormat:@"HHMMSS"];
    NSDate *currentDate = [NSDate date];
    NSString *timeString2 = [formatter stringFromDate:currentDate];
    return timeString2;
}

- (void) addRequiredTags: (NSMutableDictionary*) outgoingTags {
    if(outgoingTags != nil) {
        NSData *kernelInHex;
        if(self.kernelVersion != nil) {
            kernelInHex = [IDTUtility stringToData:self.kernelVersion];
        } else {
            NSString *kernelWithRevision = [NSString stringWithFormat:@"%@%@", KERNEL_BASE_VERSION, KERNEL_VERSION_INCREMENTAL];
            kernelInHex = [IDTUtility stringToData:kernelWithRevision];
        }
        if([self deviceSerialNumber] != nil) {
            [outgoingTags setObject:[IDTUtility stringToData:[self deviceSerialNumber]] forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
        } else {
            [outgoingTags setObject:[IDTUtility stringToData:@"9999999999"] forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
        }
        [outgoingTags setObject:kernelInHex forKey:KERNEL_VERSION_EMV_TAG];
    }
}

- (void) removeInvalidTSYSTags: (NSMutableDictionary*) outgoingTags {
    if(outgoingTags != nil) {
        [outgoingTags removeObjectForKey:@"DFEF4D"];
        [outgoingTags removeObjectForKey:@"DFEF4C"];
        [outgoingTags removeObjectForKey:@"FFEE06"];
        [outgoingTags removeObjectForKey:@"FFEE12"];
        [outgoingTags removeObjectForKey:@"FFEE13"];
        [outgoingTags removeObjectForKey:@"FFEE14"];
        [outgoingTags removeObjectForKey:@"FF8106"];
        [outgoingTags removeObjectForKey:@"FF8105"];
        [outgoingTags removeObjectForKey:TRACK2_DATA_EMV_TAG];
        [outgoingTags removeObjectForKey:TRACK1_DATA_EMV_TAG];
        [outgoingTags removeObjectForKey:@"DFEE26"];
        [outgoingTags removeObjectForKey:@"FFEE01"];
        [outgoingTags removeObjectForKey:@"DF8115"];
        [outgoingTags removeObjectForKey:@"9F12"];
        [outgoingTags removeObjectForKey:@"FFEE1F"];
        [outgoingTags removeObjectForKey:@"DF8001"];
        [outgoingTags removeObjectForKey:@"9F4E"];

        NSString *dataDF8129 = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"DF8129"]];
        if(dataDF8129 != nil) {
            [outgoingTags removeObjectForKey:@"DF8129"];
        }

        NSString *data9F6E = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F6E"]];
        if(data9F6E == nil || ([data9F6E isEqualToString:@""])) {
            [outgoingTags removeObjectForKey:@"9F6E"];
        }
        NSString *data4F = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"4F"]];
        if(data4F == nil || ([data4F isEqualToString:@""])) {
            [outgoingTags removeObjectForKey:@"4F"];
        }
    } else {
        [ClearentLumberjack logInfo:@"outgoingtags is nil. cannot remove invalid tsys tags"];
    }
}

- (void) removeInvalidContactlessTags: (NSMutableDictionary*) outgoingTags {
    if(outgoingTags != nil) {
        [ClearentLumberjack logInfo:@"remove invalid contactless tags"];
        [outgoingTags removeObjectForKey:@"9F66"];
        [outgoingTags removeObjectForKey:@"9F07"];
        [outgoingTags removeObjectForKey:@"5F24"];
        [outgoingTags removeObjectForKey:@"5F25"];
        [outgoingTags removeObjectForKey:@"9F71"];
        [outgoingTags removeObjectForKey:@"9F66"];
        [outgoingTags removeObjectForKey:@"9F11"];
        [outgoingTags removeObjectForKey:@"9F0D"];
        [outgoingTags removeObjectForKey:@"9F42"];
        [outgoingTags removeObjectForKey:@"9F08"];
        [outgoingTags removeObjectForKey:@"5F30"];
        [outgoingTags removeObjectForKey:@"9F0E"];
        [outgoingTags removeObjectForKey:@"DF76"];
        [outgoingTags removeObjectForKey:@"9F0F"];
        [outgoingTags removeObjectForKey:@"5F20"];
        [outgoingTags removeObjectForKey:@"9F5D"];
        [outgoingTags removeObjectForKey:@"9F6C"];//visa unknown in tsys
        [outgoingTags removeObjectForKey:@"9F6D"];//mastercard unknown in tsys

        NSString *data9F7C = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F7C"]];
        if(data9F7C == nil || ([data9F7C isEqualToString:@""]) || ([data9F7C isEqualToString:@"0000000000000000000000000000000000000000"])) {
            [outgoingTags removeObjectForKey:@"9F7C"];
        }
    } else {
        [ClearentLumberjack logInfo:@"outgoingtags is nil. cannot remove invalid contactless tags"];
    }
}

- (void) fixContactlessEntryMode: (NSMutableDictionary*) outgoingTags {
    if(outgoingTags != nil) {
        NSString *data9F39 = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F39"]];
        if(data9F39 == nil || ([data9F39 isEqualToString:@""]) || ([data9F39 isEqualToString:@"05"])) {
            [ClearentLumberjack logInfo:@"Fixing contactless entry mode"];
            [outgoingTags setObject:[IDTUtility stringToData:@"07"] forKey:@"9F39"];
        }
    }
}

- (void) fixContactEntryMode: (NSMutableDictionary*) outgoingTags {
    if(outgoingTags != nil) {
        NSString *data9F39 = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F39"]];
        if(data9F39 == nil || ([data9F39 isEqualToString:@""]) || ([data9F39 isEqualToString:@"07"])) {
            [ClearentLumberjack logInfo:@"Fixing contact entry mode"];
            [outgoingTags setObject:[IDTUtility stringToData:@"05"] forKey:@"9F39"];
        }
    }
}


- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    
    processingCurrentRequest = YES;
    
    [monitorCardRemovalTimer invalidate];
    
    //Complete the transaction as soon as possible so the idtech framework does not resend the current transaction.
    [_idTechSharedInstance emv_completeOnlineEMVTransaction:false hostResponseTags:nil];

    if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
        [ClearentLumberjack logError:@"createTransactionToken:NO TRACK2DATA. LAST CHECK BEFORE SENDING TO OUR JWT ENDPOINT"];
        [self deviceMessage:CLEARENT_FAILED_TO_READ_CARD_ERROR_RESPONSE];
        processingCurrentRequest = NO;
        return;
    }
    
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.baseUrl, @"rest/v2/mobilejwt"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];

    if (error) {
        [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        [ClearentLumberjack logError:@"createTransactionToken:error dont call clearent"];
        processingCurrentRequest = NO;
        return;
    }
    
    [self deviceMessage:CLEARENT_TRANSLATING_CARD_TO_TOKEN];
    [ClearentLumberjack logInfo:@"➡️ Call Clearent to produce transaction token"];

    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[ClearentUtils createExchangeChainId:[self deviceSerialNumber]] forHTTPHeaderField:@"exchangeChainId"];
    [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    //[request setTimeoutInterval:30];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self deviceMessage:CLEARENT_UNABLE_TO_GO_ONLINE];
              [ClearentLumberjack logInfo:error.description];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [self handleResponse:responseStr];
              } else {
                  [self handleError:responseStr];
              }
          }
          processingCurrentRequest = NO;
          data = nil;
          response = nil;
          error = nil;
      }] resume];
}

- (void) handleError:(NSString*)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [ClearentLumberjack logError:@"handleError:Bad response when trying to make jwt"];
        [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    } else {
        NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
        NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
        NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
        if(errorMessage != nil) {
             [self deviceMessage:[NSString stringWithFormat:@"%@. %@.", CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE, errorMessage]];
        } else {
           [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        }
        [self clearCurrentRequest];
    }
}

- (void) handleResponse:(NSString *)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
    NSString *responseCode = [jsonDictionary objectForKey:@"code"];
    if([responseCode isEqualToString:@"200"]) {
        [ClearentLumberjack logInfo:@"➡️ Successful transaction token communicated to client app"];
        [self deviceMessage:CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE];
        [self clearCurrentRequest];
        if ([self.publicDelegate respondsToSelector:@selector(successfulTransactionToken:)]) {
            [self.publicDelegate successfulTransactionToken:response];
        }
        ClearentTransactionToken *clearentTransactionToken = [[ClearentTransactionToken alloc] initWithJson:response];
        [self.publicDelegate successTransactionToken:clearentTransactionToken];
    } else {
        [ClearentLumberjack logError:@"handleResponse:Bad response when trying to make jwt"];
        [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
}

- (void) clearConfigurationCache {
     [ClearentCache clearConfigurationCache];
}

- (void) sendDeclineReceipt:(IDTEMVData*)emvData {
    [self deviceMessage:@"DECLINED"];

    if(self.clearentPayment == nil || self.clearentPayment.emailAddress == nil) {
        [ClearentLumberjack logError:@"Did not send the offline decline receipt because the email address was not provided"];
        return;
    }

    ClearentOfflineDeclineReceipt *clearentOfflineDeclineReceipt = [self map:[self createClearentTransactionTokenRequest:emvData]];
    if(self.clearentPayment != nil) {
        NSString* formattedAmount = [NSString stringWithFormat:@"%.02f", self.clearentPayment.amount];
        clearentOfflineDeclineReceipt.amount = formattedAmount;
    }
    [self clearCurrentRequest];

    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.baseUrl, @"rest/v2/mobilejwt/decline-receipt"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentOfflineDeclineReceipt.asDictionary options:0 error:&error];

    if (error) {
        [self deviceMessage:CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
        return;
    }

    [ClearentLumberjack logInfo:@"Call Clearent to send a decline receipt"];

    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[ClearentUtils createExchangeChainId:[self deviceSerialNumber]] forHTTPHeaderField:@"exchangeChainId"];
    [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    //[request setTimeoutInterval:20];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self deviceMessage:CLEARENT_FAILED_TO_SEND_DECLINE_RECEIPT];
              [ClearentLumberjack logInfo:error.description];
              [[self idTechSharedInstance] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [[self idTechSharedInstance] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleDeclineReceiptResponse:responseStr];
              } else {
                  [[self idTechSharedInstance] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleDeclineReceiptError:responseStr];
              }
          }
          data = nil;
          response = nil;
          error = nil;
      }] resume];
}

- (ClearentOfflineDeclineReceipt*) map:(ClearentTransactionTokenRequest*) clearentTransactionTokenRequest {
    ClearentOfflineDeclineReceipt *clearentOfflineDeclineReceipt = [[ClearentOfflineDeclineReceipt alloc] init];
    clearentOfflineDeclineReceipt.maskedTrack2Data = clearentTransactionTokenRequest.maskedTrack2Data;
    clearentOfflineDeclineReceipt.applicationPreferredNameTag9F12 = clearentTransactionTokenRequest.applicationPreferredNameTag9F12;
    clearentOfflineDeclineReceipt.deviceSerialNumber = clearentTransactionTokenRequest.deviceSerialNumber;
    clearentOfflineDeclineReceipt.firmwareVersion = clearentTransactionTokenRequest.firmwareVersion;
    clearentOfflineDeclineReceipt.tlv = clearentTransactionTokenRequest.tlv;
    clearentOfflineDeclineReceipt.kernelVersion = clearentTransactionTokenRequest.kernelVersion;
    clearentOfflineDeclineReceipt.emailAddress = self.clearentPayment.emailAddress;
    return clearentOfflineDeclineReceipt;
}

- (void) handleDeclineReceiptError:(NSString*)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [self deviceMessage:CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
    } else {
        NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
        NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
        NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
        if(errorMessage != nil) {
            [self deviceMessage:[NSString stringWithFormat:@"%@. %@.", CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE, errorMessage]];
        } else {
            [self deviceMessage:CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
        }
    }
}

- (void) handleDeclineReceiptResponse:(NSString *)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [self deviceMessage:CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
    }
    NSString *responseCode = [jsonDictionary objectForKey:@"code"];
    if([responseCode isEqualToString:@"200"]) {
        [ClearentLumberjack logInfo:@"➡️ Successful declined receipt communicated to client app"];
        [self deviceMessage:CLEARENT_SUCCESSFUL_DECLINE_RECEIPT_MESSAGE];
    } else {
        [self deviceMessage:CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
    }
}

- (void) clearCurrentRequest {
    
    [self setClearentPayment:nil];
    
    _originalEntryMode = 0;
    previousSwipeWasCardWithChip = NO;
    userToldToUseMagStripe = NO;
    userToldToUseChipReader = NO;
    contactlessIsProcessing = NO;
    sentCardReadSuccessMessage = NO;
    
    processingCurrentRequest = NO;
    countNumberOfShortBeeps = 0;
    userNotifiedOfTimeOut = NO;
    transactionIsInProcess = NO;
}

- (void) clearContactlessConfigurationCache {
    
    [ClearentCache clearContactlessConfigurationCache];
    
}

- (BOOL) isDeviceConfigured {
    
    if(self.configured) {
        return YES;
    }
    
    //they could set after initialization. Consider the reader configured if turned off.
    if(!self.autoConfiguration && !self.contactlessAutoConfiguration) {
        return YES;
    }
    
    return [ClearentCache isDeviceConfigured:self.autoConfiguration contactlessAutoConfiguration:self.contactlessAutoConfiguration deviceSerialNumber:self.deviceSerialNumber];
    
}

- (void) sendBluetoothDevices {
    
    if(_clearentDeviceConnector.bluetoothDevices != nil && [_clearentDeviceConnector.bluetoothDevices count] > 0) {
        for (ClearentBluetoothDevice* clearentBluetoothDevice in _clearentDeviceConnector.bluetoothDevices) {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Bluetooth Device Found %@", clearentBluetoothDevice.friendlyName]];
        }
        if ([self.publicDelegate respondsToSelector:@selector(bluetoothDevices:)]) {
            [self.publicDelegate bluetoothDevices:_clearentDeviceConnector.bluetoothDevices];
        }
    } else {
         if ([self.publicDelegate respondsToSelector:@selector(bluetoothDevices:)]) {
            [self.publicDelegate bluetoothDevices:[NSMutableArray arrayWithCapacity:0]];
         }
    }

}

- (void) cancelTransaction {
    [self disableCardRemovalTimer];
    RETURN_CODE cancelTransactionRt = [_idTechSharedInstance device_cancelTransaction];
    if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
        [ClearentLumberjack logInfo:@"ClearentDelegate:cancelTransaction:success"];
    } else {
        [ClearentLumberjack logInfo:@"ClearentDelegate:cancelTransaction:fail"];
    }
}

- (void) resetTransaction {
    [self disableCardRemovalTimer];
}

- (void) updatePublicKey:(NSString *)publicKey {
    if(publicKey != nil) {
        self.publicKey = publicKey;
        if(_clearentConfigurator != nil) {
            _clearentConfigurator.publicKey = publicKey;
        }
    }
}

@end
