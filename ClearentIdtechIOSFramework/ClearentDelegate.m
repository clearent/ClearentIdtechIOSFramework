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

int getEntryMode (NSString* rawEntryMode);
BOOL isSupportedEmvEntryMode (int entryMode);

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
static NSString *const TRACK1_DATA_EMV_TAG = @"56";
static NSString *const ENTRY_MODE_EMV_TAG = @"9F39";
static NSString *const TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG = @"9F6B";
static NSString *const TAC_DEFAULT = @"DF13";
static NSString *const TAC_DENIAL = @"DF14";
static NSString *const TAC_ONLINE = @"DF15";
static NSString *const DEVICE_SERIAL_NUMBER_EMV_TAG = @"DF78";
static NSString *const KERNEL_VERSION_EMV_TAG = @"DF79";
static NSString *const GENERIC_CARD_READ_ERROR_RESPONSE = @"Card read error";
static NSString *const USE_CHIP_READER = @"USE CHIP READER";
static NSString *const CVM_UNSUPPORTED = @"CVM Unsupported. Insert card with chip first, then start transaction. Or try swipe.";
static NSString *const CONTACTLESS_UNSUPPORTED = @"Contactless not supported. Insert card with chip first, then start transaction.";
static NSString *const MSD_CONTACTLESS_UNSUPPORTED = @"This type (MSD) of contactless is not supported. Insert card with chip first, then start transaction.";
static NSString *const CARD_OFFLINE_DECLINED = @"Card declined";
static NSString *const FALLBACK_TO_SWIPE_REQUEST = @"FALLBACK_TO_SWIPE_REQUEST";
static NSString *const TIMEOUT_ERROR_RESPONSE = @"TIME OUT";
static NSString *const TIMEOUT_ERROR_RESPONSE2 = @"TIMEOUT";
static NSString *const GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE = @"Create Transaction Token Failed";
static NSString *const GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE = @"Sending Declined Receipt Failed";
static NSString *const SUCCESSFUL_TOKENIZATION_MESSAGE = @"CARD READ OK, REMOVE CARD";
static NSString *const TRANSLATING_CARD_TO_TOKEN = @"READING CARD";
static NSString *const SUCCESSFUL_DECLINE_RECEIPT_MESSAGE = @"DECLINED RECEIPT SENT, REMOVE CARD";
static NSString *const FAILED_TO_READ_CARD_ERROR_RESPONSE = @"Failed to read card";
static NSString *const INVALID_FIRMWARE_VERSION = @"Device Firmware version not found";
static NSString *const INVALID_KERNEL_VERSION = @"Device Kernel Version Unknown";
static NSString *const DEVICE_SERIAL_NUMBER_PLACEHOLDER = @"9999999999";
static NSString *const KERNEL_BASE_VERSION = @"EMV Common L2 V1.10";
static NSString *const KERNEL_VERSION_INCREMENTAL = @".037";
static NSString *const READER_CONFIGURED_MESSAGE = @"Reader configured and ready";

static NSString *const DEVICE_NOT_CONNECTED = @"Device is not connected";

static NSString *const UNABLE_TO_GO_ONLINE = @"UNABLE TO GO ONLINE";
static NSString *const GENERIC_CONTACTLESS_FAILED = @"TAP FAILED";
static NSString *const CONTACTLESS_FALLBACK_MESSAGE = @"TAP FAILED. INSERT/SWIPE";
static NSString *const CONTACTLESS_RETRY_MESSAGE = @"RETRY TAP";

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

@implementation ClearentDelegate

  ClearentConfigurator *_clearentConfigurator;
  id<ClearentVP3300Configuration> _clearentVP3300Configuration;

- (instancetype) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey  {
    self = [super init];
    if (self) {
        self.publicDelegate = publicDelegate;

        self.baseUrl = clearentBaseUrl;
        self.publicKey = publicKey;
        SEL configurationCallbackSelector = @selector(deviceMessage:);
        _clearentConfigurator = [[ClearentConfigurator alloc] init:self.baseUrl publicKey:self.publicKey callbackObject:self withSelector:configurationCallbackSelector sharedController:[IDT_VP3300 sharedController]];
        self.autoConfiguration = true;
        self.contactlessAutoConfiguration = false;
        self.clearentPayment = nil;
        self.configured = NO;
        self.contactless = NO;
        self.bluetoothDeviceID = nil;
        self.bluetoothSearchInProgress = FALSE;
    }
    return self;
}

- (instancetype) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration {
    self = [super init];
    if (self) {
        [self setClearentVP3300Configuration:clearentVP3300Configuration];
        self.baseUrl = clearentVP3300Configuration.clearentBaseUrl;
        self.publicKey = clearentVP3300Configuration.publicKey;
        self.publicDelegate = publicDelegate;
        self.autoConfiguration = clearentVP3300Configuration.contactAutoConfiguration;
        self.contactlessAutoConfiguration = clearentVP3300Configuration.contactlessAutoConfiguration;
        self.clearentPayment = nil;
        self.configured = NO;
        self.contactless = clearentVP3300Configuration.contactless;
        SEL configurationCallbackSelector = @selector(deviceMessage:);
        _clearentConfigurator = [[ClearentConfigurator alloc] init:self.baseUrl publicKey:self.publicKey callbackObject:self withSelector:configurationCallbackSelector sharedController:[IDT_VP3300 sharedController]];
    }
    return self;
}

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines {
    NSMutableArray *updatedArray = [[NSMutableArray alloc]initWithCapacity:1];
    if (lines != nil) {
        for (NSString* message in lines) {
            if(message != nil && [message isEqualToString:@"TERMINATED"]) {
                [self clearCurrentRequest];
                [Teleport logError:@"IDTech framework terminated the request."];
                [self deviceMessage:@"TERMINATED"];
            }  else if(message != nil && [message isEqualToString:@"TERMINATE"]) {
                [self clearCurrentRequest];
                [Teleport logError:@"IDTech framework terminated the request."];
                [self deviceMessage:@"TERMINATE"];
            } else if(message != nil && [message isEqualToString:@"DECLINED"]) {
                NSLog(@"This is not really a decline. Clearent is creating a transaction token for later use.");
                [self clearCurrentRequest];
            } else if(message != nil && [message isEqualToString:@"APPROVED"]) {
                NSLog(@"This is not really an approval. Clearent is creating a transaction token for later use.");
            } else {
                if(message != nil) {
                    [Teleport logInfo:message];
                }
               [updatedArray addObject:message];
            }
        }
        [self.publicDelegate lcdDisplay:(int)mode  lines:(NSArray*)updatedArray];
    }
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming {
    [self.publicDelegate dataInOutMonitor:data incoming:isIncoming];
}

- (void) plugStatusChange:(BOOL)deviceInserted {
    [self.publicDelegate plugStatusChange:deviceInserted];
}

- (void) bypassData:(NSData*)data {
    [self.publicDelegate bypassData:data];
}

-(void)deviceConnected {
    [self clearCurrentRequest];
    self.firmwareVersion= [self getFirmwareVersion];
    self.deviceSerialNumber = [self getDeviceSerialNumber];
    self.kernelVersion = [self getKernelVersion];
    [self.publicDelegate deviceConnected];

    [self deviceMessage:@"Device connected. Waiting for configuration to complete..."];
    [_clearentConfigurator configure:self.kernelVersion deviceSerialNumber:self.deviceSerialNumber autoConfiguration:self.autoConfiguration contactlessAutoConfiguration:self.contactlessAutoConfiguration];
}

- (NSString *) getFirmwareVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        [Teleport logError:INVALID_FIRMWARE_VERSION];
        return INVALID_FIRMWARE_VERSION;
    }
}

- (void) resetInvalidDeviceData {
    [self resetDeviceSerialNumber];
    [self resetFirmwareVersion];
    [self resetKernelVersion];
}

- (void) resetFirmwareVersion {
    if(self.firmwareVersion == nil || [self.firmwareVersion isEqualToString:INVALID_FIRMWARE_VERSION]) {
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

- (void) resetKernelVersion {
    if(self.kernelVersion == nil || [self.kernelVersion isEqualToString:INVALID_KERNEL_VERSION]) {
         [Teleport logInfo:@"Try to fix invalid kernel version"];
        self.kernelVersion = [self getKernelVersion];
    }
}

- (NSString *) getKernelVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        NSString *kernelVersion;
        if(result != nil && [kernelVersion isEqualToString:KERNEL_BASE_VERSION]) {
            if([result containsString:KERNEL_VERSION_INCREMENTAL]) {
                kernelVersion = result;
            } else {
                result = [NSString stringWithFormat:@"%@%@", result,KERNEL_VERSION_INCREMENTAL];
            }
        }
        return result;
    } else{
        [Teleport logError:INVALID_KERNEL_VERSION];
        return INVALID_KERNEL_VERSION;
    }
}

- (NSString *) getDeviceSerialNumber {
    NSString *deviceSerialNumber = [self getDeviceSerialNumberFromReader ];
    if (deviceSerialNumber == nil) {
        //Sometimes the initial communication with the reader is unstable so we can't get the device serial number the first time...try one more time.
        [NSThread sleepForTimeInterval:0.5f];
        [Teleport logInfo:@"Initial attempt to get device serial number failed. Try again"];
        deviceSerialNumber = [self getDeviceSerialNumberFromReader ];
        if (deviceSerialNumber != nil) {
            [Teleport logInfo:@"Second attempt to get device serial number was successful"];
        } else {
            [Teleport logInfo:@"Second attempt to get device serial number failed"];
        }
    }
    if(deviceSerialNumber != nil) {
        return deviceSerialNumber;
    }
    [Teleport logError:@"Failed to get device serial number using config_getSerialNumber. Using all nines placeholder"];
    return DEVICE_SERIAL_NUMBER_PLACEHOLDER;
}

- (NSString *) getDeviceSerialNumberFromReader {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] config_getSerialNumber:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        NSString *firstTenOfDeviceSerialNumber = nil;
        if (result != nil && [result length] >= 10) {
            firstTenOfDeviceSerialNumber = [result substringToIndex:10];
        } else {
            firstTenOfDeviceSerialNumber = result;
        }
        return firstTenOfDeviceSerialNumber;
    } else{
        return nil;
    }
}

-(void)deviceDisconnected{
    [self clearCurrentRequest];
    [Teleport logInfo:[NSString stringWithFormat:@"Device disconnected"]];
    [self.publicDelegate deviceDisconnected];
}

- (void) deviceMessage:(NSString*)message {
    if(message != nil) {
        [Teleport logInfo:[NSString stringWithFormat:@"%@:%@", @"deviceMessage", message]];
    }

    if(message != nil && [message isEqualToString:READER_CONFIGURED_MESSAGE]) {
        [Teleport logInfo:@"Framework notified reader is ready"];
        [self.publicDelegate isReady];
        self.configured = YES;
        [self resetBluetoothSearch];
        return;
    }

    if(message != nil && [message isEqualToString:@"POWERING UNIPAY"]) {
        [self.publicDelegate deviceMessage:@"Powering up reader..."];
        return;
    }
    if(message != nil && [message isEqualToString:@"RETURN_CODE_LOW_VOLUME"]) {
        [self.publicDelegate deviceMessage:@"Device failed to connect.Turn the headphones volume all the way up and reconnect."];
        return;
    }

    if(message != nil && ([message isEqualToString:TIMEOUT_ERROR_RESPONSE2] || [message isEqualToString:TIMEOUT_ERROR_RESPONSE] ||[message isEqualToString:UNABLE_TO_GO_ONLINE] || [message isEqualToString:MSD_CONTACTLESS_UNSUPPORTED])) {
        RETURN_CODE cancelTransactionRt = [[IDT_VP3300 sharedController] device_cancelTransaction];
        if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
            [Teleport logInfo:@"deviceMessage: Cancelled transaction for timeout, msd, or connectivity issues"];
        }
    }

    if(message != nil && [message containsString:@"BLE DEVICE FOUND"] && _defaultBluetoothFriendlyName != nil && [message containsString:_defaultBluetoothFriendlyName]) {
//            NSArray *components = [message componentsSeparatedByString:@"("];
//            NSArray *uuidComponents = [components.lastObject componentsSeparatedByString:@")"];
//            NSString *uuid = uuidComponents.firstObject;
        [self.publicDelegate deviceMessage:[NSString stringWithFormat:@"Bluetooth reader found %@",_defaultBluetoothFriendlyName]];
        [Teleport logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found %@",_defaultBluetoothFriendlyName]];
        // [self startBluetoothSearchWithUUID:uuid];
    } else {
        [self.publicDelegate deviceMessage:message];
    }
}

- (void) handleContactlessError:(NSString*)contactlessError emvData:(IDTEMVData*)emvData {
    if(contactlessError == nil || [contactlessError isEqualToString:@""] || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_NONE]) {
        return;
    }

    RETURN_CODE cancelTransactionRt = [[IDT_VP3300 sharedController] device_cancelTransaction];
    if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
        NSLog(@"Cancel Transaction Succeeded");
    } else {
         NSLog(@"Cancel Transaction failed. Do we need this ?");
    }

    if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_COLLISION_ERROR]) {
        [self.publicDelegate deviceMessage:@"PRESENT ONE CARD ONLY"];
        return;
    }

    NSString *errorMessage;
    if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_BLOCKED]) {
        [self.publicDelegate deviceMessage:@"CARD BLOCKED"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_EXPIRED]) {
        [self.publicDelegate deviceMessage:@"CARD EXPIRED"];
    } else if(contactlessError == nil || [contactlessError isEqualToString:CONTACTLESS_ERROR_CODE_CARD_UNSUPPORTED]) {
        [self.publicDelegate deviceMessage:@"CARD UNSUPPORTED"];
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
        [self.publicDelegate deviceMessage:@"AMOUNT IS OVER MAXIMUM LIMIT ALLOWED FOR TAP."];
    } else {
        errorMessage = @"";
    }
    [Teleport logInfo:errorMessage];
    [self startContactlessFallbackToContact: errorMessage];
}

-(void) startContactlessFallbackToContact: (NSString*) errorMessage {
    [NSThread sleepForTimeInterval:0.3f];
    if(![[IDT_VP3300 sharedController] isConnected]) {
        [self.publicDelegate deviceMessage:DEVICE_NOT_CONNECTED];
        return;
    }

    NSString *fullErrorMessage;
    if(errorMessage != nil && ![errorMessage isEqualToString:@""]) {
        fullErrorMessage = [NSString stringWithFormat:@"%@%@%@", @"TAP FAILED. ", errorMessage, @". INSERT/SWIPE"];
    } else {
        fullErrorMessage = @"TAP FAILED. INSERT/SWIPE";
    }

    RETURN_CODE emvStartRt;
    emvStartRt =  [[IDT_VP3300 sharedController] emv_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:self.clearentPayment.timeout tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];
    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
        [self.publicDelegate deviceMessage:fullErrorMessage];
    } else {
        NSString *logErrorMessage =[NSString stringWithFormat:@"startContactlessFallbackToContact %@%@",[[IDT_VP3300 sharedController] device_getResponseCodeString:emvStartRt], fullErrorMessage];
        [Teleport logInfo:logErrorMessage];
        [self.publicDelegate deviceMessage:@"TAP FAILED. INSERT CHIP CARD FIRST BEFORE TRYING AGAIN. IF PHONE TRY AGAIN OR ASK FOR CARD."];
    }
}

-(void) retryContactless {
    [NSThread sleepForTimeInterval:0.3f];
    if(![[IDT_VP3300 sharedController] isConnected]) {
        [self.publicDelegate deviceMessage:DEVICE_NOT_CONNECTED];
        return;
    }

    [Teleport logInfo:@"retryContactless:device_startTransaction"];

    RETURN_CODE emvStartRt;
    emvStartRt =  [[IDT_VP3300 sharedController] device_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:20 tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];

    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
        [self.publicDelegate deviceMessage:CONTACTLESS_RETRY_MESSAGE];
    } else {
        [NSThread sleepForTimeInterval:0.2f];
        emvStartRt =  [[IDT_VP3300 sharedController] device_startTransaction:self.clearentPayment.amount amtOther:self.clearentPayment.amtOther type:self.clearentPayment.type timeout:20 tags:self.clearentPayment.tags forceOnline:self.clearentPayment.forceOnline fallback:self.clearentPayment.fallback];
        if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt || RETURN_CODE_DO_SUCCESS == emvStartRt) {
            [self.publicDelegate deviceMessage:CONTACTLESS_RETRY_MESSAGE];
        } else {
            NSString *logErrorMessage =[NSString stringWithFormat:@"retryContactless %@",[[IDT_VP3300 sharedController] device_getResponseCodeString:emvStartRt]];
            [Teleport logInfo:logErrorMessage];
            [self.publicDelegate deviceMessage:GENERIC_CONTACTLESS_FAILED];
        }
    }
}

- (void)startBluetoothSearchWithUUID:(NSString *)uuid {
    if (self.bluetoothSearchInProgress && [uuid isEqualToString:self.bluetoothDeviceID]) {
        // Search already in progress for the specified UUID
        return;
    }

    self.bluetoothSearchInProgress = TRUE;
    self.bluetoothDeviceID = uuid;

    NSUUID *val = nil;
    if (uuid.length > 0) {
        val = [[NSUUID alloc] initWithUUIDString:uuid];
    }

    bool device_enableBLEDeviceSearchReturnCode = [[IDT_VP3300 sharedController] device_enableBLEDeviceSearch:val];
    if(!device_enableBLEDeviceSearchReturnCode) {
        [self.publicDelegate deviceMessage:@"Bluetooth Scan failed to start"];
        [Teleport logInfo:@"Bluetooth Scan failed to start"];
    }
}

- (void) resetBluetoothSearch {
    self.bluetoothDeviceID = nil;
    self.bluetoothSearchInProgress = FALSE;
}

- (void) swipeMSRData:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && (cardData.track2 != nil || cardData.encTrack2 != nil)) {
        if(cardData.iccPresent) {
            [self deviceMessage:USE_CHIP_READER];
            return;
        }
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else if (cardData != nil && cardData.event == EVENT_MSR_TIMEOUT) {
        [self deviceMessage:TIMEOUT_ERROR_RESPONSE];
    } else {
//TODO idtech is working on something that might allow us to use this command
//        NSData *result;
//        RETURN_CODE device_sendIDGCommandRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x01 subCommand:0x05 data:[IDTUtility hexToData:@"1905"] response:&result];
//        if (RETURN_CODE_DO_SUCCESS == device_sendIDGCommandRt) {
//           [self deviceMessage:@"got something"];
//         } else{
//           [self deviceMessage:@"fail"];
//        }
       [self deviceMessage:GENERIC_CARD_READ_ERROR_RESPONSE];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        clearentTransactionTokenRequest.encrypted = true;
        clearentTransactionTokenRequest.maskedTrack2Data = cardData.track2;
        clearentTransactionTokenRequest.track2Data = [IDTUtility dataToHexString:cardData.encTrack2].uppercaseString;
        clearentTransactionTokenRequest.ksn = [IDTUtility dataToHexString:cardData.KSN].uppercaseString;
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest.encrypted = false;
        clearentTransactionTokenRequest.maskedTrack2Data = cardData.track2;
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
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else if (cardData != nil && cardData.event == EVENT_MSR_TIMEOUT) {
        [self deviceMessage:TIMEOUT_ERROR_RESPONSE];
    } else {
        [self deviceMessage:GENERIC_CARD_READ_ERROR_RESPONSE];
        return;
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestFallbackSwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
    NSMutableDictionary *outgoingTags = [NSMutableDictionary new];
    [self addRequiredTags: outgoingTags];
    NSData *tagsAsNSData = [IDTUtility DICTotTLV:outgoingTags];
    NSString *tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    NSString *tlvInHexWith9F39 = [NSString stringWithFormat:@"%@%@", tlvInHex, @"9F390195"];
    clearentTransactionTokenRequest.emv = false;
    clearentTransactionTokenRequest.tlv = tlvInHexWith9F39.uppercaseString;

    return clearentTransactionTokenRequest;
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{

    [Teleport logInfo:[NSString stringWithFormat:@"EMV Transaction Data Response: = %@",[[IDT_VP3300 sharedController] device_getResponseCodeString:error]]];

    if([self isEmvErrorHandled:emvData error:error]) {
        return;
    }

    int entryMode = [self getEntryMode: emvData];

    if(entryMode == 0 && emvData.cardType != 1) {
        [Teleport logError:@"No entryMode defined"];
        return;
    }

    if (emvData.cardType == 1 && entryMode == CONTACTLESS_MAGNETIC_SWIPE) {
        [self deviceMessage:MSD_CONTACTLESS_UNSUPPORTED];
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
        [self deviceMessage:TIMEOUT_ERROR_RESPONSE];
    } else if(emvData == nil) {
        emvErrorHandled = YES;
    } else if (emvData.cardType == 1 && !self.contactless) {
        emvErrorHandled = YES;
        [self deviceMessage:CONTACTLESS_UNSUPPORTED];
    } else if(emvData != nil && emvData.cardType == 1) {
        NSString* contactlessErrorCodeData = [self getContactlessErrorCode: emvData.unencryptedTags];
        if([self isContactlessError: contactlessErrorCodeData]) {
            [self handleContactlessError: contactlessErrorCodeData emvData:emvData];
            emvErrorHandled = YES;
        }
    } else if (emvData.cardType == 1 && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_CVM_CODE_IS_NOT_SUPPORTED) {
        emvErrorHandled = YES;
        [self deviceMessage:CVM_UNSUPPORTED];
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_DECLINED_OFFLINE) {
        emvErrorHandled = YES;
        [self deviceMessage:CARD_OFFLINE_DECLINED];
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_CARD_ERROR) {
        emvErrorHandled = YES;
        [self deviceMessage:GENERIC_CARD_READ_ERROR_RESPONSE];
    } else if(emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APP_NO_MATCHING) {
         _originalEntryMode = 81;
         SEL startFallbackSwipeSelector = @selector(startFallbackSwipe);
         [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:startFallbackSwipeSelector userInfo:nil repeats:false];
         emvErrorHandled = YES;
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_TIME_OUT) {
         emvErrorHandled = YES;
         [self deviceMessage:TIMEOUT_ERROR_RESPONSE];
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
         emvErrorHandled = YES;
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
         emvErrorHandled = YES;
     } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_DECLINED) {
         [Teleport logInfo:@"ignoring IDTECH authorization decline"];
         emvErrorHandled = YES;
     }

    return emvErrorHandled;

}

- (void) convertIDTechCardToClearentTransactionToken: (IDTEMVData*)emvData entryMode:(int) entryMode {
    @try {
        if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
            if(_originalEntryMode == 81) {
                [self swipeMSRDataFallback:emvData.cardData];
            } else if(entryMode == SWIPE) {
                [self swipeMSRData:emvData.cardData];
            } else if(isSupportedEmvEntryMode(entryMode)) {
                ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
                [self createTransactionToken:clearentTransactionTokenRequest];
            } else {
                [self deviceMessage:GENERIC_CARD_READ_ERROR_RESPONSE];
            }
        } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || emvData.cardType == 1)) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            if(emvData.cardType == 1 && clearentTransactionTokenRequest.track2Data == nil) {
                [self deviceMessage:GENERIC_CONTACTLESS_FAILED];
            } else {
                [self createTransactionToken:clearentTransactionTokenRequest];
            }
        } else {
            NSLog(@"ignoring message in emvTransactionData");
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
    [self deviceMessage:@"FALLBACK TO SWIPE"];
    RETURN_CODE startMSRSwipeRt = [[IDT_VP3300 sharedController] msr_startMSRSwipe];
    if (RETURN_CODE_DO_SUCCESS == startMSRSwipeRt) {
       [self deviceMessage:@"FALLBACK TO SWIPE start success"];
     } else{
       [self deviceMessage:@"FALLBACK TO SWIPE start failed"];
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
    NSString *track2Data57;

    if(emvData.cardData != nil) {
        if(emvData.cardData.encTrack2 != nil) {
            clearentTransactionTokenRequest.encrypted = true;
            track2Data57 = [IDTUtility dataToHexString:emvData.cardData.encTrack2];
            clearentTransactionTokenRequest.maskedTrack2Data = emvData.cardData.track2;
            clearentTransactionTokenRequest.ksn = [IDTUtility dataToHexString:emvData.cardData.KSN].uppercaseString;
        } else if(emvData.cardData.track2 != nil) {
            clearentTransactionTokenRequest.encrypted = false;
            track2Data57 = emvData.cardData.track2;
        }
    } else if(isEncryptedTransaction(emvData.encryptedTags)) {
        clearentTransactionTokenRequest.encrypted = true;
        track2Data57 = [IDTUtility dataToHexString:[emvData.encryptedTags objectForKey:TRACK2_DATA_EMV_TAG]];
        clearentTransactionTokenRequest.maskedTrack2Data = [IDTUtility dataToHexString:[emvData.maskedTags objectForKey:TRACK2_DATA_EMV_TAG]].uppercaseString;
        NSString *ksn = [IDTUtility dataToHexString:emvData.KSN].uppercaseString;
        if(ksn != nil && !([ksn isEqualToString:@""])) {
            clearentTransactionTokenRequest.ksn = [ksn uppercaseString];
            clearentTransactionTokenRequest.encrypted = true;
        } else {
            ksn = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:@"FFEE12"]];
            if(ksn != nil && !([ksn isEqualToString:@""])) {
                clearentTransactionTokenRequest.ksn = [ksn uppercaseString];
                clearentTransactionTokenRequest.encrypted = true;
            }
        }
    } else {
        clearentTransactionTokenRequest.encrypted = false;
        track2Data57 = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:TRACK2_DATA_EMV_TAG]];
    }

    if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
        clearentTransactionTokenRequest.track2Data = track2Data57.uppercaseString;
    } else if (emvData.cardType == 1) {//contactless
        if(isEncryptedTransaction(emvData.encryptedTags)) {
            NSDictionary *ff8105 = [IDTUtility TLVtoDICT_HEX_ASCII:[emvData.encryptedTags objectForKey:@"FF8105"]];
            if(ff8105 != nil) {
                [Teleport logInfo:@"ff8105 found in encryptedTags"];
                NSString *track2Data9F6B = [ff8105 objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG];
                if(track2Data9F6B != nil && !([track2Data9F6B isEqualToString:@""])) {
                    clearentTransactionTokenRequest.track2Data = track2Data9F6B.uppercaseString;
                }
            }
        } else {
            NSString *encryptedTrack2 = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:@"DFEF4D"]];
            NSString *ksn = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:@"FFEE12"]];
            if(ksn != nil && !([ksn isEqualToString:@""])) {
                clearentTransactionTokenRequest.ksn = [ksn uppercaseString];
                clearentTransactionTokenRequest.encrypted = true;
            }
            if(encryptedTrack2 != nil && !([encryptedTrack2 isEqualToString:@""])) {
                clearentTransactionTokenRequest.track2Data = encryptedTrack2.uppercaseString;
            }
        }

        NSData* ff8105Data = [emvData.unencryptedTags objectForKey:@"FF8105"];
        [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8105Data tags:outgoingTags];

        NSData* ff8106Data = [emvData.unencryptedTags objectForKey:@"FF8106"];
        [self addFromFF81XX: clearentTransactionTokenRequest ff81XX:ff8106Data tags:outgoingTags];
    }

    [self addRequiredTags: outgoingTags];
    [self addApplicationPreferredName:clearentTransactionTokenRequest tags:outgoingTags];

    [self removeInvalidTSYSTags: outgoingTags];

    if (emvData.cardType == 1) {
        [self removeInvalidContactlessTags:outgoingTags];
        [self updateTransactionTimeTags:outgoingTags];

        //commented this out during EMV Phase 1 contactless certification. Why did we do it in the first place ?
//        NSString *data9F53 = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F53"]];
//        if(data9F53 != nil) {
//            [outgoingTags removeObjectForKey:@"9F53"];
//            [outgoingTags setObject:@"2010000000009000" forKey:@"9F53"];
//        }
    }

    NSString *deviceSerialNumber = [self deviceSerialNumber];
    if(deviceSerialNumber != nil && [deviceSerialNumber length] > 8) {
        [outgoingTags removeObjectForKey:@"9F1E"];
        NSString *lastEightOfDeviceSerialNumber = [deviceSerialNumber substringFromIndex:[deviceSerialNumber length] - 8];
        [outgoingTags setObject:[IDTUtility stringToData:lastEightOfDeviceSerialNumber] forKey:@"9F1E"];
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

- (NSMutableDictionary*) createDefaultOutgoingTags: (IDTEMVData*)emvData {
    NSMutableDictionary *outgoingTags;
    if(emvData == nil) {
        return outgoingTags;
    }
    if (emvData.cardType == 1) {//contactless
        outgoingTags = [emvData.unencryptedTags mutableCopy];
    } else {
        NSDictionary *transactionResultDictionary;
        NSData *tsysTags = [IDTUtility hexToData:@"508E82959A9B9C5F2A9F029F039F1A9F219F269F279F339F349F359F369F379F394F845F2D5F349F069F129F099F405F369F1E9F105657FF8106FF8105FFEE14FFEE06"];
        RETURN_CODE emvRetrieveTransactionResultRt = [[IDT_VP3300 sharedController] emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
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
        [self addEncryptedData: clearentTransactionTokenRequest encryptedTags:_encTags];
    }
}

- (void) addEncryptedData: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest encryptedTags:(NSDictionary*) encryptedTags {
    if(encryptedTags != nil && clearentTransactionTokenRequest.track2Data == nil) {
        NSString *track2Data57 = [encryptedTags objectForKey:@"57"];
        if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
            clearentTransactionTokenRequest.track2Data = track2Data57.uppercaseString;
        } else {
            NSString *track2Data56 = [encryptedTags objectForKey:@"56"];
            if(track2Data56 != nil && !([track2Data56 isEqualToString:@""])) {
                clearentTransactionTokenRequest.track2Data = track2Data56.uppercaseString;
            }
        }
    }
}

- (void) addMaskedData: (ClearentTransactionTokenRequest*) clearentTransactionTokenRequest maskedTags:(NSDictionary*) maskedTags {
    if (maskedTags != nil && clearentTransactionTokenRequest.maskedTrack2Data == nil) {
        NSString *maskedTrack2DataFrom57 = [IDTUtility dataToHexString:[maskedTags objectForKey:@"57"]];
        //Which one should we be using all the time ? dataToHexString solves a mastercard issue but amex and discover worked with dataToString
        //NSString *maskedTrack2DataFrom57 = [IDTUtility dataToString:[maskedTags objectForKey:@"57"]];
        if(maskedTrack2DataFrom57 != nil && !([maskedTrack2DataFrom57 isEqualToString:@""])) {
            clearentTransactionTokenRequest.maskedTrack2Data = maskedTrack2DataFrom57.uppercaseString;
        } else {
            NSString *maskedTrack2DataFrom56 = [IDTUtility dataToHexString:[maskedTags objectForKey:@"56"]];
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
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HHMMSS";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    return timeString;
}

- (void) addRequiredTags: (NSMutableDictionary*) outgoingTags {
    NSData *kernelInHex;
    if(self.kernelVersion == nil || [self.kernelVersion isEqualToString:INVALID_KERNEL_VERSION]) {
         kernelInHex = [IDTUtility stringToData:self.kernelVersion];
    } else {
        NSString *kernelWithRevision = [NSString stringWithFormat:@"%@%@", KERNEL_BASE_VERSION, KERNEL_VERSION_INCREMENTAL];
        kernelInHex = [IDTUtility stringToData:kernelWithRevision];
    }
    [outgoingTags setObject:[IDTUtility stringToData:[self deviceSerialNumber]] forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
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
//    [outgoingTags removeObjectForKey:@"DFED20"];
//    [outgoingTags removeObjectForKey:@"DFED21"];
//    [outgoingTags removeObjectForKey:@"DFED22"];
    [outgoingTags removeObjectForKey:@"FFEE01"];
    [outgoingTags removeObjectForKey:@"DF8115"];
    [outgoingTags removeObjectForKey:@"9F12"];
    [outgoingTags removeObjectForKey:@"FFEE1F"];

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
    if(clearentTransactionTokenRequest == nil || clearentTransactionTokenRequest.track2Data == nil || [clearentTransactionTokenRequest.track2Data isEqualToString:@""]) {
        [self deviceMessage:FAILED_TO_READ_CARD_ERROR_RESPONSE];
        return;
    }
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.baseUrl, @"rest/v2/mobilejwt"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];

    if (error) {
        [self deviceMessage:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        return;
    }
    [self deviceMessage:TRANSLATING_CARD_TO_TOKEN];
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
              [self deviceMessage:UNABLE_TO_GO_ONLINE];
              [Teleport logInfo:error.description];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleResponse:responseStr];
              } else {
                  [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
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
        [self deviceMessage:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    } else {
        NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
        NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
        NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
        if(errorMessage != nil) {
             [self deviceMessage:[NSString stringWithFormat:@"%@. %@.", GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE, errorMessage]];
        } else {
           [self deviceMessage:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        }
    }
}

- (void) handleResponse:(NSString *)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [self deviceMessage:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
    NSString *responseCode = [jsonDictionary objectForKey:@"code"];
    if([responseCode isEqualToString:@"200"]) {
        [Teleport logInfo:@"Successful transaction token communicated to client app"];
        [self deviceMessage:SUCCESSFUL_TOKENIZATION_MESSAGE];
        [self.publicDelegate successfulTransactionToken:response];
    } else {
        [self deviceMessage:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
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
        [self deviceMessage:GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
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
              [self deviceMessage:@"UNABLE TO GO ONLINE, FAILED TO SEND DECLINED RECEIPT"];
              [Teleport logInfo:error.description];
              [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleDeclineReceiptResponse:responseStr];
              } else {
                  [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
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
        [self deviceMessage:GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
    } else {
        NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
        NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
        NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
        if(errorMessage != nil) {
            [self deviceMessage:[NSString stringWithFormat:@"%@. %@.", GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE, errorMessage]];
        } else {
            [self deviceMessage:GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
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
        [self deviceMessage:GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
    }
    NSString *responseCode = [jsonDictionary objectForKey:@"code"];
    if([responseCode isEqualToString:@"200"]) {
        [Teleport logInfo:@"Successful declined receipt communicated to client app"];
        [self deviceMessage:SUCCESSFUL_DECLINE_RECEIPT_MESSAGE];
    } else {
        [self deviceMessage:GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE];
    }
}

- (void) clearCurrentRequest{
    [self setClearentPayment:nil];
}

- (void) clearContactlessConfigurationCache {
    [ClearentCache clearContactlessConfigurationCache];
}

- (BOOL) isDeviceConfigured {
    if(self.configured) {
        return YES;
    }
    return [ClearentCache isDeviceConfigured:self.autoConfiguration contactlessAutoConfiguration:self.contactlessAutoConfiguration deviceSerialNumber:self.deviceSerialNumber];
}

@end
