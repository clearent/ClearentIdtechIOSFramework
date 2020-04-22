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
#import "Teleport.h"
#import "ClearentCache.h"
#import "ClearentOfflineDeclineReceipt.h"
#import "ClearentPayment.h"
#import <AVFoundation/AVFoundation.h>

int getEntryMode (NSString* rawEntryMode);
BOOL isSupportedEmvEntryMode (int entryMode);

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
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
    }
    return self;
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
    
    switch (mode) {
        case 0x10:
            [Teleport logInfo:@"prompt 10"];
            break;
        case 0x03:
            [Teleport logInfo:@"prompt 3"];
            break;
        case 0x01:
            [Teleport logInfo:@"prompt 1"];
            break;
        case 0x02:
            [Teleport logInfo:@"prompt 2"];
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
                    [Teleport logError:@"contactless is not enabled. Switch PLEASE SWIPE to old message"];
                    [updatedArray addObject:@"INSERT/SWIPE"];
                    [self sendFeedback:CLEARENT_USER_ACTION_2_IN_1_MESSAGE];
                } else  if(!self.contactless && [message isEqualToString:@"TAP, OR INSERT"]) {
                    [Teleport logError:@"contactless is not enabled. Switch TAP OR INSERT to old message"];
                    [updatedArray addObject:@"CARD"];
                } else if([message isEqualToString:@"TERMINATED"]) {
                    [Teleport logError:@"IDTech framework terminated the request."];
                    [self deviceMessage:CLEARENT_TRANSACTION_TERMINATED];
                }  else if([message isEqualToString:@"TERMINATE"]) {
                    [Teleport logError:@"IDTech framework terminated the request."];
                    [self deviceMessage:CLEARENT_TRANSACTION_TERMINATE];
                }  else if([message isEqualToString:@"USE MAGSTRIPE"]) {
                    userToldToUseMagStripe = YES;
                    [Teleport logError:@"IDTech framework USE MAGSTRIPE."];
                    [self deviceMessage:CLEARENT_USE_MAGSTRIPE];
                } else if([message isEqualToString:@"CARD"] && (userToldToUseMagStripe || userToldToUseChipReader)) {
                     [Teleport logError:@"do not show CARD message to help with messaging of restarts of the transaction"];
                } else if([message isEqualToString:@"INSERT/SWIPE"] && (userToldToUseMagStripe || userToldToUseChipReader)) {
                    [Teleport logError:@"do not show INSERT/SWIPE message to help with messaging of restarts of the transaction"];
                } else if([message isEqualToString:@"USE CHIP READER"]) {
                    userToldToUseChipReader = YES;
                    if(!userToldToUseMagStripe) {
                        [self deviceMessage:CLEARENT_CHIP_FOUND_ON_SWIPE];
                        [Teleport logInfo:@"Clearent is handling the use chip reader message."];
                    } else {
                        [Teleport logError:@"User told to use magstripe even though use chip reader message came back."];
                    }
                } else if([message isEqualToString:@"DECLINED"]) {
                    NSLog(@"This is not really a decline. Clearent is creating a transaction token for later use.");
                } else if([message isEqualToString:@"APPROVED"]) {
                    NSLog(@"This is not really an approval. Clearent is creating a transaction token for later use.");
                } else {
                   [Teleport logInfo:message];
                   [self sendFeedback:message];
                   [updatedArray addObject:message];
                }
            }
        }
        
        if(updatedArray.count > 0) {
            [self.publicDelegate lcdDisplay:(int)mode  lines:(NSArray*)updatedArray];
        }
    }
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming {
    [self.publicDelegate dataInOutMonitor:data incoming:isIncoming];
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
    
    [self.publicDelegate plugStatusChange:deviceInserted];
}

- (void) bypassData:(NSData*)data {
    [self.publicDelegate bypassData:data];
}

-(void) deviceConnected {
    
    if(self.clearentConnection != nil) {
        
        if(self.clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            [self deviceMessage:CLEARENT_BLUETOOTH_CONNECTED];
            [_clearentDeviceConnector recordBluetoothDeviceAsConnected];
            [self sendBluetoothDevices];
            [_clearentDeviceConnector resetBluetoothAfterConnected];
        }
        
        [Teleport logInfo:[NSString stringWithFormat:@"%@%@", @"connected ", [self.clearentConnection createLogMessage]]];
        
    }
    
    if([_idTechSharedInstance device_isAudioReaderConnected]) {
        [self deviceMessage:CLEARENT_AUDIO_JACK_CONNECTED];
    }
    
    [self setReaderProfile];
    
    //TODO IDTech ticket 20356
    //[_clearentDeviceConnector adjustBluetoothAdvertisingInterval];
    
    [self.publicDelegate deviceConnected];
    
    if(!self.autoConfiguration && !self.contactlessAutoConfiguration) {
        [self setupReaderOnConnect];
        [self deviceMessage:CLEARENT_READER_CONFIGURED_MESSAGE];
    } else {
        [self applyClearentConfiguration];
    }
}

- (void) setReaderProfile {
    self.firmwareVersion= [self getFirmwareVersion];
    self.deviceSerialNumber = [self getDeviceSerialNumber];
    self.kernelVersion = [self getKernelVersion];
}

- (void) setupReaderOnConnect {
    [_clearentConfigurator initClock];
}

-(void) applyClearentConfiguration {
    [self deviceMessage:CLEARENT_DEVICE_CONNECTED_WAITING_FOR_CONFIG];
    [_clearentConfigurator configure:self.kernelVersion deviceSerialNumber:self.deviceSerialNumber autoConfiguration:self.autoConfiguration contactlessAutoConfiguration:self.contactlessAutoConfiguration];
}

- (NSString *) getFirmwareVersion {
    bool found = false;
    NSString *firmwareVersion;
    for(int i = 0; i < 5; i++ ) {
        [NSThread sleepForTimeInterval:0.2f];
        NSString *result;
        RETURN_CODE rt = [_idTechSharedInstance device_getFirmwareVersion:&result];
        if (RETURN_CODE_DO_SUCCESS == rt) {
            firmwareVersion = result;
            found = true;
            break;
        } else {
            [Teleport logError:CLEARENT_INVALID_FIRMWARE_VERSION];
        }
    }
    if(!found) {
        firmwareVersion = CLEARENT_INVALID_FIRMWARE_VERSION;
    }
    return firmwareVersion;
}

- (void) resetInvalidDeviceData {
    [self resetDeviceSerialNumber];
    [self resetFirmwareVersion];
}

- (void) resetFirmwareVersion {
    if(self.firmwareVersion == nil || [self.firmwareVersion isEqualToString:CLEARENT_INVALID_FIRMWARE_VERSION]) {
       [Teleport logInfo:@"Try to fix invalid firmware version"];
       self.firmwareVersion= [self getFirmwareVersion];
    }
}

- (void) resetDeviceSerialNumber {
    if(self.deviceSerialNumber == nil || [self.deviceSerialNumber isEqualToString:DEVICE_SERIAL_NUMBER_PLACEHOLDER]) {
         [Teleport logInfo:@"Try to fix invalid device serial number"];
         self.deviceSerialNumber = [self getDeviceSerialNumber];
    }
}

- (NSString *) getKernelVersion {
    NSString *result;
    RETURN_CODE rt = [_idTechSharedInstance emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        NSString *kernelVersion;
        if(result != nil && [result isEqualToString:KERNEL_BASE_VERSION]) {
            if([result containsString:KERNEL_VERSION_INCREMENTAL]) {
                kernelVersion = result;
            } else {
                result = [NSString stringWithFormat:@"%@%@", result,KERNEL_VERSION_INCREMENTAL];
            }
        }
        return result;
    } else{
        [Teleport logError:@"Failed to get kernel version. Use default"];
        return [NSString stringWithFormat:@"%@%@", KERNEL_BASE_VERSION, KERNEL_VERSION_INCREMENTAL];
    }
}

- (NSString*) getDeviceSerialNumber {
    
    NSString *deviceSerialNumber = [self getDeviceSerialNumberFromReader ];
    
    if(deviceSerialNumber != nil) {
        [ClearentCache cacheCurrentDeviceSerialNumber:deviceSerialNumber];
        return deviceSerialNumber;
    }
    
    [Teleport logError:@"Failed to get device serial number using config_getSerialNumber. Using all nines placeholder"];
    
    return DEVICE_SERIAL_NUMBER_PLACEHOLDER;
}

- (NSString *) getDeviceSerialNumberFromReader {
    
    bool found = false;
    NSString *firstTenOfDeviceSerialNumber;
    
    for(int i = 0; i < 5; i++ ) {
        [NSThread sleepForTimeInterval:0.5f];
        NSString *result;
        RETURN_CODE config_getSerialNumberRt = [_idTechSharedInstance config_getSerialNumber:&result];
        if (RETURN_CODE_DO_SUCCESS == config_getSerialNumberRt) {
            if (result != nil && [result length] >= 10) {
                firstTenOfDeviceSerialNumber = [result substringToIndex:10];
            } else {
                firstTenOfDeviceSerialNumber = result;
            }
            break;
        } else {
            [Teleport logError:@"getDeviceSerialNumberFromReader:fail"];
        }
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
        
        if (self.clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            [self sendBluetoothDevices];
        }
        
        [Teleport logInfo:[NSString stringWithFormat:@"%@%@", @"connected ", [self.clearentConnection createLogMessage]]];
        
    }
        
    [Teleport logInfo:[NSString stringWithFormat:@"Device disconnected"]];
    
    [self.publicDelegate deviceDisconnected];
    
}

- (void) deviceMessage:(NSString*)message {
    
    if(message != nil) {
        [Teleport logInfo:[NSString stringWithFormat:@"%@:%@", @"deviceMessage", message]];
    }

    if(message != nil && [message isEqualToString:CLEARENT_READER_CONFIGURED_MESSAGE]) {
        [Teleport logInfo:@"💚💚READER READY💚💚"];
        [Teleport logInfo:@"Framework notified reader is ready"];
        self.configured = YES;
        
        if(self.runStoredPaymentAfterConnecting) {
            self.runStoredPaymentAfterConnecting = FALSE;
            [self.callbackObject performSelector:self.runTransactionSelector];
        } else {
            [self.publicDelegate isReady];
        }
        return;
    }

    if(message != nil && [message isEqualToString:@"RETURN_CODE_SDK_BUSY_MSR"]) {
        return;
    }
    
    if(message != nil && [message isEqualToString:@"POWERING UNIPAY"]) {
        [self.publicDelegate deviceMessage:CLEARENT_POWERING_UP];
        return;
    }
    
    if(message != nil && [message isEqualToString:@"RETURN_CODE_LOW_VOLUME"]) {
        [self.publicDelegate deviceMessage:CLEARENT_AUDIO_JACK_LOW_VOLUME];
        return;
    }

    if(message != nil && ([message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE2] || [message isEqualToString:CLEARENT_TIMEOUT_ERROR_RESPONSE] ||[message isEqualToString:CLEARENT_UNABLE_TO_GO_ONLINE] || [message isEqualToString:CLEARENT_MSD_CONTACTLESS_UNSUPPORTED])) {
        RETURN_CODE cancelTransactionRt = [_idTechSharedInstance device_cancelTransaction];
        if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
            [Teleport logInfo:@"deviceMessage: Cancelled transaction for timeout, msd, or connectivity issues"];
        }
    }

    if(message != nil && [message containsString:@"BLE DEVICE FOUND"]) {
        [_clearentDeviceConnector handleBluetoothDeviceFound:message];
    } else {
        [self.publicDelegate deviceMessage:message];
        [self sendFeedback:message];
    }
}

- (void) sendFeedback:(NSString*) message {
        
    ClearentFeedback *clearentFeedback = [ClearentFeedback createFeedback:message];

    if(clearentFeedback.message != nil && ![clearentFeedback.message isEqualToString:@""]) {
       
        [self feedback:clearentFeedback];
        
    }
    
}

- (void) feedback:(ClearentFeedback*)clearentFeedback {
        [self.publicDelegate feedback:clearentFeedback];
}
                          
- (void) handleContactlessError:(NSString*)contactlessError emvData:(IDTEMVData*)emvData {
    
    if(contactlessError == nil || [contactlessError isEqualToString:@""] || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_NONE]) {
        return;
    }

    RETURN_CODE cancelTransactionRt = [_idTechSharedInstance device_cancelTransaction];
    
    if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
        NSLog(@"Cancel Transaction Succeeded");
    } else {
         NSLog(@"Cancel Transaction failed. Do we need this ?");
    }

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
        [Teleport logError:@"handleContactlessError: aac generated"];
        [self sendDeclineReceipt:emvData];
        return;
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_SSA_OR_DDA_FAILED]) {
        [Teleport logError:@"handleContactlessError: ssa or dda failed"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_MISSING_CA_PUBLIC_KEY]) {
        [Teleport logError:@"handleContactlessError: contactless ca public key not found"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_FAILED_TO_RECOVER_ISSUER_PUBLIC_KEY]) {
        [Teleport logError:@"handleContactlessError: failed to recover issuer public key"];
        errorMessage = @"DECLINED";
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_GO_TO_CONTACT_INTERFACE]) {
        [Teleport logError:@"handleContactlessError: go to contact interface"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_GO_TO_OTHER_INTERFACE]) {
        [Teleport logError:@"handleContactlessError: go to other interface"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_GO_TO_MAGSTRIPE_INTERFACE]) {
        [Teleport logError:@"handleContactlessError: go to magstripe interface"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_AMOUNT_OVER_MAXIMUM_LIMIT]) {
        [self deviceMessage:CLEARENT_TAP_OVER_MAX_AMOUNT];
    } else {
        errorMessage = @"";
    }
    
    [Teleport logInfo:errorMessage];
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
        [Teleport logInfo:logErrorMessage];
        [self deviceMessage:CLEARENT_TAP_FAILED_INSERT_CARD_FIRST];
    }
}

-(void) retryContactless {
    [NSThread sleepForTimeInterval:0.3f];
    if(![_idTechSharedInstance isConnected]) {
        [self deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        return;
    }

    [Teleport logInfo:@"retryContactless:device_startTransaction"];

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
            [Teleport logInfo:logErrorMessage];
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

    RETURN_CODE cancelTransactionRt = [_idTechSharedInstance device_cancelTransaction];
    if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
        [Teleport logInfo:@"restartSwipeIn2In1Mode: Cancelled transaction before restarting in 2 in 1 mode"];
    }

    [Teleport logInfo:@"restartSwipeIn2In1Mode:emv_startTransaction"];

    RETURN_CODE emvStartRt;
    emvStartRt =  [_idTechSharedInstance emv_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];

    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
        [self sendSwipeErrorMessage:cardData];
    } else {
        [Teleport logInfo:@"restartSwipeIn2In1Mode:try emv_startTransaction one more time after initial failure"];
        [NSThread sleepForTimeInterval:0.2f];
        emvStartRt =  [_idTechSharedInstance emv_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];
        if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
            [self sendSwipeErrorMessage:cardData];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"restartSwipeIn2In1Mode %@",[_idTechSharedInstance device_getResponseCodeString:emvStartRt]];
            [Teleport logInfo:logErrorMessage];
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

    RETURN_CODE cancelTransactionRt = [_idTechSharedInstance device_cancelTransaction];
    if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
        [Teleport logInfo:@"restartSwipeOnly: Cancelled transaction before restarting in 2 in 1 mode"];
    }

    [Teleport logInfo:@"restartSwipeOnly:msrSwipe"];

    RETURN_CODE msr_startMSRSwipeRt = [_idTechSharedInstance msr_startMSRSwipe];

    if(RETURN_CODE_OK_NEXT_COMMAND == msr_startMSRSwipeRt || RETURN_CODE_DO_SUCCESS == msr_startMSRSwipeRt) {
        [self sendSwipeErrorMessage:cardData];
    } else {
        [Teleport logInfo:@"restartSwipeOnly:try msr_startMSRSwipe one more time after initial failure"];
        [NSThread sleepForTimeInterval:0.2f];
        msr_startMSRSwipeRt = [_idTechSharedInstance msr_startMSRSwipe];
        if(RETURN_CODE_OK_NEXT_COMMAND == msr_startMSRSwipeRt || RETURN_CODE_DO_SUCCESS == msr_startMSRSwipeRt) {
            [self sendSwipeErrorMessage:cardData];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"restartSwipeOnly %@",[_idTechSharedInstance device_getResponseCodeString:msr_startMSRSwipeRt]];
            [Teleport logInfo:logErrorMessage];
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
                [self restartSwipeIn2In1Mode:cardData];
            } else {
                [self createTransactionToken:clearentTransactionTokenRequest];
            }
        }
    } else if (cardData != nil && cardData.event == EVENT_MSR_DATA_ERROR) {
        [self restartSwipeIn2In1Mode:cardData];
    } else if (cardData != nil && cardData.event == EVENT_MSR_TIMEOUT) {
        [self deviceMessage:CLEARENT_TIMEOUT_ERROR_RESPONSE];
    } else if(userToldToUseMagStripe) {
        [self restartSwipeOnly:cardData];
    } else {
        [self restartSwipeIn2In1Mode:cardData];
    }
}

//- (void) gen2Data:(NSData*)tlv{
//   //Is this needed?
//}
//
//
//-(void) dismissAllAlertViews {
//   //Is this needed?
//}
//
//-(void) showAlertView:(NSString*)msg {
////Is this needed?
//}

/// <#Description#>
/// @param event <#event description#>
/// @param scheme <#scheme description#>
/// @param data <#data description#>
//- (void) ctlsEvent:(Byte)event scheme:(Byte)scheme  data:(Byte)data {
//    NSLog([NSString stringWithFormat:@"Event Scheme = %i",(int)scheme]);
//    [Teleport logInfo:[NSString stringWithFormat:@"Event Scheme = %i",(int)scheme]];
//    NSLog([NSString stringWithFormat:[NSString stringWithFormat:@"EVERY Event = %i",(int)data]]);
//    switch (event) {
//        case 0x01:
//        {
//        [Teleport logInfo:[NSString stringWithFormat:@"EVENT 01!!!! LED Event = %i",(int)data]];
//                  switch (data)
//                            {
//                                case 0x00:
//                                    [self deviceMessage:@"LED0 OFF"];
//                                    break;
//                                case 0x10:
//                                    [self deviceMessage:@"LED1 OFF"];
//                                    break;
//                                case 0x20:
//                                    [self deviceMessage:@"LED2 OFF"];
//                                    break;
//                                case 0x30:
//                                    [self deviceMessage:@"LED3 OFF"];
//                                    break;
//                                case 0xF0:
//                                    [self deviceMessage:@"ALL OFF"];
//                                    break;
//                                case 0x01:
//                                    [self deviceMessage:@"LED0 ON"];
//                                    break;
//                                case 0x11:
//                                    [self deviceMessage:@"LED1 ON"];
//                                    break;
//                                case 0x21:
//                                    [self deviceMessage:@"LED2 ON"];
//                                    break;
//                                case 0x31:
//                                    [self deviceMessage:@"LED3 ON"];
//                                    break;
//                                case 0xF1:
//                                    [self deviceMessage:@"ALL ON"];
//                                    break;
//                            }
//                            break;
//                 }
//            case 0x02:
//               {
//            [Teleport logInfo:[NSString stringWithFormat:@"Buzzer Event = %i",(int)data]];
//            switch (data)
//                                {
//                                    case 0x10:
//                                        [self deviceMessage:@"Short Beep No Change "];
//                                        break;
//                                    case 0x11:
//                                        [self deviceMessage:@"Short Beep No Change"];
//                                        break;
//                                    case 0x12:
//                                        [self deviceMessage:@"Double Short Beep"];
//                                        break;
//                                    case 0x13:
//                                        [self deviceMessage:@"Triple Short Beep"];
//                                        break;
//                                    case 0x20:
//                                        [self deviceMessage:@"200ms Beep"];
//                                        break;
//                                    case 0x21:
//                                        [self deviceMessage:@"400ms Beep"];
//                                        break;
//                                    case 0x22:
//                                        [self deviceMessage:@"600ms Beep"];
//                                        break;
//                                }
//                                break;
//               }
//            case 0x03:
//        {
//             NSLog([NSString stringWithFormat:@"LCD Event = %i",(int)data]);
//            [Teleport logInfo:[NSString stringWithFormat:@"LCD Event = %i",(int)data]];
//            NSString* line1=nil;
//            NSString* line2=nil;
//            [IDTUtility retrieveCTLSMessage:scheme lang:0 messageID:data line1:&line1 line2:&line2];
//            [self deviceMessage:line1];
//            if(line1 != nil &&
//                ![line1 isEqualToString:@""]
//                && [line1 isEqualToString:@"Processing"]) {
//                contactlessIsProcessing  = YES;
//            }
//                    
//            break;
//        }
//            case 0x04:
//            case 0x05:
//            case 0x06:
//            case 0x07:
//            case 0x08:
//            case 0x09:
//            case 0x10:
//            case 0x11:
//                {
//                     NSLog([NSString stringWithFormat:@"OTHERS LCD Event = %i",(int)data]);
//                    [Teleport logInfo:[NSString stringWithFormat:@"LCD Event = %i",(int)data]];
//                    NSString* line1=nil;
//                    NSString* line2=nil;
//                    [IDTUtility retrieveCTLSMessage:scheme lang:0 messageID:data line1:&line1 line2:&line2];
//                    [self deviceMessage:line1];
//                    if(line1 != nil &&
//                        ![line1 isEqualToString:@""]
//                        && [line1 isEqualToString:@"Try Another Interface"]) {
//                        contactlessIsProcessing  = YES;
//                    }
//                            
//                    break;
//                }
//        default:
//            break;
//    }
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
            if(userToldToUseMagStripe) {
                [self restartSwipeOnly:cardData];
            } else {
                [self restartSwipeIn2In1Mode:cardData];
            }
        } else {
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
  
    [Teleport logInfo:[NSString stringWithFormat:@"EMV Transaction Data Response: = %@",[_idTechSharedInstance device_getResponseCodeString:error]]];

    if([self isEmvErrorHandled:emvData error:error]) {
        return;
    }

    int entryMode = [self getEntryMode: emvData];

    if(entryMode == 0 && emvData.cardType != 1) {
        [Teleport logError:@"No entryMode defined"];
        return;
    }

    if (emvData.cardType == 1 && entryMode == CONTACTLESS_MAGNETIC_SWIPE) {
        [Teleport logInfo:@"🙅🙅MSD CONTACTLESS NOT SUPPORTED🙅🙅"];
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
       [Teleport logInfo:[NSString stringWithFormat:@"EMV_RESULT_CODE_V2_response = %2X",emvData.resultCodeV2]];
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
         [Teleport logInfo:@"ignoring IDTECH authorization decline"];
         emvErrorHandled = YES;
     } else if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
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
        if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
            if(_originalEntryMode == 81 || previousSwipeWasCardWithChip || userToldToUseChipReader) {
                [self swipeMSRDataFallback:emvData.cardData];
            } else if(entryMode == SWIPE) {
                [self swipeMSRData:emvData.cardData];
            } else if(isSupportedEmvEntryMode(entryMode)) {
                ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
                if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
                       [self restartSwipeIn2In1Mode:emvData.cardData];
                       return;
                }
                [self createTransactionToken:clearentTransactionTokenRequest];
            } else {
                [self deviceMessage:CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE];
            }
        } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || emvData.cardType == 1)) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            if(emvData.cardType == 1 && clearentTransactionTokenRequest.track2Data == nil) {
                [self deviceMessage:CLEARENT_GENERIC_CONTACTLESS_FAILED];
            } else {
                [self createTransactionToken:clearentTransactionTokenRequest];
            }
        } else {
            [Teleport logInfo:[NSString stringWithFormat:@"convertIDTechCardToClearentTransactionToken: pass through. this means our error handler probably missed something"]];
        }
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat:@"[Error] - %@ %@", exception.name, exception.reason];
        NSLog( @"%@", errorMessage );
        [Teleport logInfo:[NSString stringWithFormat:@"convertIDTechCardToClearentTransactionToken: Possible Programming Error %@", errorMessage]];
    }
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
        [Teleport logInfo:[NSString stringWithFormat:@"See Error Code table page 28 of NEO Guide version 125 for first byte meaning. FFEE1F. %@",ffee1fHex]];
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
    RETURN_CODE cancelTransactionRt = [_idTechSharedInstance device_cancelTransaction];
    if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
        [Teleport logInfo:@"deviceMessage: Cancelled transaction before starting fallback swipe"];
    }
    RETURN_CODE startMSRSwipeRt = [_idTechSharedInstance msr_startMSRSwipe];
    if (RETURN_CODE_DO_SUCCESS == startMSRSwipeRt || RETURN_CODE_OK_NEXT_COMMAND == startMSRSwipeRt) {
        [Teleport logInfo:@"deviceMessage: start fallback swipe succeeded "];
    } else {
        [Teleport logInfo:@"deviceMessage: start fallback swipe failed "];
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
    NSMutableDictionary *outgoingTags = [self createDefaultOutgoingTags:emvData];
    NSData *tagsAsNSData;
    NSString *tlvInHex;
    clearentTransactionTokenRequest.encrypted = false;
    
    if(emvData.cardData != nil) {
        [self addCardData:clearentTransactionTokenRequest iDTEMVData:emvData];
    } else if(isEncryptedTransaction(emvData.encryptedTags)) {
        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.encryptedTags];
        if(clearentTransactionTokenRequest.track2Data == nil) {
           NSString *encryptedTrack2 = [IDTUtility dataToHexString:[emvData.encryptedTags objectForKey:IDTECH_DFEF4D_CIPHERTEXT_TAG]];
           if(encryptedTrack2 != nil && !([encryptedTrack2 isEqualToString:@""])) {
                clearentTransactionTokenRequest.track2Data = encryptedTrack2.uppercaseString;
           }
        }
        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.unencryptedTags];
        [self addMaskedData: clearentTransactionTokenRequest maskedTags:emvData.maskedTags];
    } else {
        [self addTrack2Data: clearentTransactionTokenRequest tags:emvData.unencryptedTags];
        [self addMaskedData: clearentTransactionTokenRequest maskedTags:emvData.maskedTags];
    }

    [self addKSN:clearentTransactionTokenRequest iDTEMVData:emvData];
    
    if (emvData.cardType == 1) {//contactless
        if(isEncryptedTransaction(emvData.encryptedTags)) {
            NSData* ff8105Data = [emvData.encryptedTags objectForKey:MASTERCARD_GROUP_FF8105_TAG];
            [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8105Data tags:outgoingTags];

            NSData* ff8106Data = [emvData.encryptedTags objectForKey:MASTERCARD_GROUP_FF8106_TAG];
            [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8106Data tags:outgoingTags];
        }
    }
    
    NSData* ff8105Data = [emvData.unencryptedTags objectForKey:MASTERCARD_GROUP_FF8105_TAG];
    [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8105Data tags:outgoingTags];

    NSData* ff8106Data = [emvData.unencryptedTags objectForKey:MASTERCARD_GROUP_FF8106_TAG];
    [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8106Data tags:outgoingTags];

    [self recordConfiguredReaderFlag: [outgoingTags objectForKey:MERCHANT_NAME_AND_LOCATION_HIJACKED_AS_PRECONFIGURED_FLAG]];
    [self addRequiredTags: outgoingTags];
    [self addApplicationPreferredName:clearentTransactionTokenRequest tags:outgoingTags];

    [self removeInvalidTSYSTags: outgoingTags];
    [self updateTransactionTimeTags:outgoingTags];
    
    if (emvData.cardType == 1) {
        [self removeInvalidContactlessTags:outgoingTags];
        //commented this out during EMV Phase 1 contactless certification. Why did we do it in the first place ?
//        NSString *data9F53 = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F53"]];
//        if(data9F53 != nil) {
//            [outgoingTags removeObjectForKey:@"9F53"];
//            [outgoingTags setObject:@"2010000000009000" forKey:@"9F53"];
//        }
    }

    if(clearentTransactionTokenRequest.deviceSerialNumber == nil) {
        NSString *deviceSerialNumber = [self deviceSerialNumber];
        if(deviceSerialNumber != nil && [deviceSerialNumber length] > 8) {
            [outgoingTags removeObjectForKey:@"9F1E"];
            NSString *lastEightOfDeviceSerialNumber = [deviceSerialNumber substringFromIndex:[deviceSerialNumber length] - 8];
            [outgoingTags setObject:[IDTUtility stringToData:lastEightOfDeviceSerialNumber] forKey:@"9F1E"];
        }
    }
    
    if(outgoingTags != nil) {
    
        tagsAsNSData = [IDTUtility DICTotTLV:outgoingTags];
        tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
        clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
        
    }

    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];

    return clearentTransactionTokenRequest;
}

- (void) recordConfiguredReaderFlag: (NSData*) tagData  {
    
    if(tagData != nil) {
        
        NSString *merchantNameAndLocationHijackedAsConfiguredFlag = [IDTUtility dataToHexString:tagData];
        
        if(merchantNameAndLocationHijackedAsConfiguredFlag != nil && [merchantNameAndLocationHijackedAsConfiguredFlag isEqualToString:READER_CONFIGURED_FLAG_LETTER_P_IN_HEX]) {
            [Teleport logInfo:@"🤩 🤩 🤩 🤩 🤩 IDTECH READER IS PRECONFIGURED 🤩 🤩 🤩 🤩 🤩"];
        } else {
            
            if(merchantNameAndLocationHijackedAsConfiguredFlag != nil) {
                [Teleport logInfo:[NSString stringWithFormat:@"PRECONFIG CHECK 9f4e value is: %@", merchantNameAndLocationHijackedAsConfiguredFlag]];
            } else {
                [Teleport logInfo:[NSString stringWithFormat:@"PRECONFIG CHECK No 9F4E tag found"]];
            }
            
        }
        
    }
    
}

- (NSMutableDictionary*) createDefaultOutgoingTags: (IDTEMVData*)emvData {
    NSMutableDictionary *outgoingTags;
    if(emvData == nil) {
        return outgoingTags;
    }
    if (emvData.cardType == 1) {//contactless
        outgoingTags = [emvData.unencryptedTags mutableCopy];
    } else {
        NSDictionary *transactionResultDictionary;
        NSData *tsysTags = [IDTUtility hexToData:@"508E82959A9B9C5F2A9F029F039F1A9F219F269F279F339F349F359F369F379F399F4E4F845F2D5F349F069F129F099F405F369F1E9F105657FF8106FF8105FFEE14FFEE06"];
        RETURN_CODE emvRetrieveTransactionResultRt = [_idTechSharedInstance emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
        if(RETURN_CODE_DO_SUCCESS == emvRetrieveTransactionResultRt) {
            outgoingTags = [transactionResultDictionary objectForKey:@"tags"];
        } else {
            [Teleport logError:@"Failed to retrieve tlv from Device. Default to unencryptedTags"];
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
        [Teleport logInfo:[NSString stringWithFormat:@"Reader Serial Number %@",iDTEMVData.cardData.RSN]];
        clearentTransactionTokenRequest.deviceSerialNumber = iDTEMVData.cardData.RSN;
    }
}

- (void) addKSN: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest iDTEMVData:(IDTEMVData*)iDTEMVData {
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
    
        if(track2Data == nil) {
            track2Data = [tags objectForKey:TRACK1_DATA_EMV_TAG];
        }
        
        if(track2Data == nil) {
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

- (void) removeInvalidTSYSTags: (NSMutableDictionary*) outgoingTags {
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
}

- (void) removeInvalidContactlessTags: (NSMutableDictionary*) outgoingTags {
    [Teleport logInfo:@"remove invalid contactless tags"];
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
}

- (void) updateTransactionTimeTags: (NSMutableDictionary*) outgoingTags {
    [outgoingTags removeObjectForKey:@"9A"];
    [outgoingTags removeObjectForKey:@"9F21"];
    [outgoingTags setObject:[self getClockDateAsYYMMDDInHex] forKey:@"9A"];
    [outgoingTags removeObjectForKey:@"9F21"];
    [outgoingTags setObject:[self getTimeAsHHMMSSInHex] forKey:@"9F21"];

}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    
    //Complete the transaction as soon as possible so the idtech framework does not resend the current transaction.
    RETURN_CODE emv_completeOnlineEMVTransactionRt = [_idTechSharedInstance emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
    if(RETURN_CODE_OK_NEXT_COMMAND == emv_completeOnlineEMVTransactionRt || RETURN_CODE_DO_SUCCESS == emv_completeOnlineEMVTransactionRt) {
        [Teleport logInfo:@"Request IDTech to Complete Transaction Successful IDTECH_TRANSACTION_COMPLETED"];
    } else {
        [Teleport logInfo:@"Request IDTech to Complete Transaction Failed IDTECH_TRANSACTION_COMPLETED"];
    }

    if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
        [self deviceMessage:CLEARENT_FAILED_TO_READ_CARD_ERROR_RESPONSE];
        return;
    }
    
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.baseUrl, @"rest/v2/mobilejwt"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];

    if (error) {
        [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        return;
    }
    
    [self deviceMessage:CLEARENT_TRANSLATING_CARD_TO_TOKEN];
    [Teleport logInfo:@"Call Clearent to produce transaction token"];

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
              [Teleport logInfo:error.description];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [self handleResponse:responseStr];
              } else {
                  [self handleError:responseStr];
              }
          }
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
        [Teleport logInfo:@"😀😀💳💳CARD IS NOW TOKEN💳💳😀😀"];
        [Teleport logInfo:@"Successful transaction token communicated to client app"];
        [self deviceMessage:CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE];
        [self clearCurrentRequest];
        [self.publicDelegate successfulTransactionToken:response];
        ClearentTransactionToken *clearentTransactionToken = [[ClearentTransactionToken alloc] initWithJson:response];
        [self.publicDelegate successTransactionToken:clearentTransactionToken];
    } else {
        [self deviceMessage:CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
}

- (void) clearConfigurationCache {
     [ClearentCache clearConfigurationCache];
}

- (void) sendDeclineReceipt:(IDTEMVData*)emvData {
    [self deviceMessage:@"DECLINED"];

    if(self.clearentPayment == nil || self.clearentPayment.emailAddress == nil) {
        [Teleport logError:@"Did not send the offline decline receipt because the email address was not provided"];
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

    [Teleport logInfo:@"Call Clearent to send a decline receipt"];

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
              [Teleport logInfo:error.description];
              [_idTechSharedInstance emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [_idTechSharedInstance emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleDeclineReceiptResponse:responseStr];
              } else {
                  [_idTechSharedInstance emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
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
        [Teleport logInfo:@"Successful declined receipt communicated to client app"];
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
            [Teleport logInfo:[NSString stringWithFormat:@"Bluetooth Device Found %@", clearentBluetoothDevice.friendlyName]];
        }
        [self.publicDelegate bluetoothDevices:_clearentDeviceConnector.bluetoothDevices];
    } else {
        [self.publicDelegate bluetoothDevices:[NSMutableArray arrayWithCapacity:0]];
    }

}

@end
