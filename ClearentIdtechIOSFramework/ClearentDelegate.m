//
//  ClearentDelegate.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.

#import "ClearentDelegate.h"
#import "ClearentConfigurator.h"
#import "IDTech/IDTUtility.h"
#import "ClearentUtils.h"
#import "Teleport.h"
#import "ClearentCache.h"

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
static NSString *const TRACK1_DATA_EMV_TAG = @"56";
static NSString *const TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG = @"9F6B";
static NSString *const TAC_DEFAULT = @"DF13";
static NSString *const TAC_DENIAL = @"DF14";
static NSString *const TAC_ONLINE = @"DF15";

static NSString *const DEVICE_SERIAL_NUMBER_EMV_TAG = @"DF78";
static NSString *const KERNEL_VERSION_EMV_TAG = @"DF79";
static NSString *const GENERIC_CARD_READ_ERROR_RESPONSE = @"Card read error";
static NSString *const USE_CHIP_READER = @"USE CHIP READER";
static NSString *const CONTACTLESS_UNSUPPORTED = @"Contactless not supported. Insert card with chip first, then start transaction.";
static NSString *const CARD_OFFLINE_DECLINED = @"Card declined";
static NSString *const FALLBACK_TO_SWIPE_REQUEST = @"FALLBACK_TO_SWIPE_REQUEST";
static NSString *const TIMEOUT_ERROR_RESPONSE = @"TIME OUT";
static NSString *const GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE = @"Create Transaction Token Failed";
static NSString *const FAILED_TO_READ_CARD_ERROR_RESPONSE = @"Failed to read card";

static NSString *const READER_CONFIGURED_MESSAGE = @"Reader configured and ready";

@implementation ClearentDelegate

  ClearentConfigurator *clearentConfigurator;

- (instancetype) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey  {
    self = [super init];
    if (self) {
        self.publicDelegate = publicDelegate;
        self.baseUrl = clearentBaseUrl;
        self.publicKey = publicKey;
        SEL configurationCallbackSelector = @selector(deviceMessage:);
        clearentConfigurator = [[ClearentConfigurator alloc] init:self.baseUrl publicKey:self.publicKey callbackObject:self withSelector:configurationCallbackSelector sharedController:[IDT_VP3300 sharedController]];
        self.autoConfiguration = true;
    }
    return self;
}

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines {
    NSMutableArray *updatedArray = [[NSMutableArray alloc]initWithCapacity:1];
    if (lines != nil) {
        for (NSString* message in lines) {
            if(message != nil && [message isEqualToString:@"TERMINATE"]) {
                [Teleport logError:@"IDTech framework terminated the request."];
                [self deviceMessage:@"TERMINATE"];
            } else if(message != nil && [message isEqualToString:@"DECLINED"]) {
                NSLog(@"This is not really a decline. Clearent is creating a transaction token for later use.");
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
    self.firmwareVersion= [self getFirmwareVersion];
    self.deviceSerialNumber = [self getDeviceSerialNumber];
    self.kernelVersion = [self getKernelVersion];
    [self.publicDelegate deviceConnected];
    if(self.autoConfiguration) {
        [self deviceMessage:@"Device connected. Waiting for configuration to complete..."];
        [clearentConfigurator configure:self.kernelVersion deviceSerialNumber:self.deviceSerialNumber];
    } else {
        [self deviceMessage:READER_CONFIGURED_MESSAGE];
    }
}

- (NSString *) getFirmwareVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        [Teleport logError:@"Device Firmware version not found"];
        return @"Device Firmware version not found";
    }
}

- (NSString *) getKernelVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        [Teleport logError:@"Device Kernel Version Unknown"];
        return @"Device Kernel Version Unknown";
    }
}

- (NSString *) getDeviceSerialNumber {
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
        [Teleport logError:@"Failed to get device serial number using config_getSerialNumber"];
        return @"9999999999";
    }
}

-(void)deviceDisconnected{
    [self.publicDelegate deviceDisconnected];
}

- (void) deviceMessage:(NSString*)message {
    if(message != nil) {
        [Teleport logInfo:[NSString stringWithFormat:@"%@:%@", @"deviceMessage", message]];
    }
    if(message != nil && [message isEqualToString:READER_CONFIGURED_MESSAGE]) {
        NSString *firstTenOfDeviceSerialNumber = nil;
        if (self.deviceSerialNumber != nil && [self.deviceSerialNumber length] >= 10) {
            firstTenOfDeviceSerialNumber = [self.deviceSerialNumber substringToIndex:10];
        } else {
            firstTenOfDeviceSerialNumber = self.deviceSerialNumber;
        }
        [ClearentCache updateConfigurationCache:firstTenOfDeviceSerialNumber readerConfiguredFlag:@"true"];
        [Teleport logInfo:@"Framework notified reader is ready"];
        [self.publicDelegate isReady];
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
    [self.publicDelegate deviceMessage:message];
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
        [self deviceMessage:GENERIC_CARD_READ_ERROR_RESPONSE];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        NSString *encryptedTrack2Data = [[NSString alloc] initWithData:cardData.encTrack2
                                                              encoding:NSUTF8StringEncoding];
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:true track2Data:encryptedTrack2Data.uppercaseString];
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:false track2Data:cardData.track2.uppercaseString];
    }

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
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestFallbackSwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        NSString *encryptedTrack2Data = [[NSString alloc] initWithData:cardData.encTrack2
                                                              encoding:NSUTF8StringEncoding];
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:true track2Data:encryptedTrack2Data.uppercaseString];
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:false track2Data:cardData.track2.uppercaseString];
    }
    
    NSMutableDictionary *outgoingTags = [NSMutableDictionary new];
    [self addRequiredTags: outgoingTags];
    
    NSData *tagsAsNSData = [IDTUtility DICTotTLV:outgoingTags];
    NSString *tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    clearentTransactionTokenRequest.emv = false;
    
    clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
    
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionToken:(BOOL)emv encrypted:(BOOL)encrypted track2Data:(NSString*) track2Data {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    clearentTransactionTokenRequest.emv = emv;
    clearentTransactionTokenRequest.encrypted = encrypted;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.track2Data = track2Data.uppercaseString;
    return clearentTransactionTokenRequest;
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    
    if (emvData == nil) {
        return;
    }
    
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_DECLINED_OFFLINE) {
        [self deviceMessage:CARD_OFFLINE_DECLINED];
        return;
    }
    
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_CARD_ERROR) {
        [self deviceMessage:GENERIC_CARD_READ_ERROR_RESPONSE];
        return;
    }
    
    if(emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APP_NO_MATCHING) {
        [self deviceMessage:@"FALLBACK TO SWIPE"];
        
        _originalEntryMode = 81;
        
        SEL startFallbackSwipeSelector = @selector(startFallbackSwipe);
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:startFallbackSwipeSelector userInfo:nil repeats:false];
        return;
    }
   
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_TIME_OUT) {
        [self deviceMessage:TIMEOUT_ERROR_RESPONSE];
        return;
    }

    //The mobile-jwt call should succeed or fail. We call the IDTech complete method every time.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
        return;
    }
    //We aren't starting an authorization so this result code should never be set. But return just in case.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        return;
    }

    if (emvData.cardType == 1) {
        [self deviceMessage:CONTACTLESS_UNSUPPORTED];
        return;
    }

    int entryMode = 0;
    if (emvData.unencryptedTags != nil) {
        NSData *entrymodedata = [emvData.unencryptedTags objectForKey:@"9F39"];
        if(entrymodedata != nil) {
            NSString *entrymodeString = [IDTUtility dataToHexString:entrymodedata];
            if(entrymodeString != nil) {
                entryMode = entrymodeString.intValue;
            }
        }
    }

    if(entryMode == 0) {
        [Teleport logError:@"No entryMode defined"];
        return;
    }
    
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
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE || emvData.cardType == 1)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    }
    _originalEntryMode = entryMode;
}

- (void) startFallbackSwipe {
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
    if(entryMode == FALLBACK_SWIPE || entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE) {
        return true;
    }
    return false;
}

- (ClearentTransactionTokenRequest*)  createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    if(emvData.cardData != nil) {
        if(emvData.cardData.encTrack2 != nil) {
            [emvData.encryptedTags setValue:emvData.cardData.encTrack2 forKey:TRACK2_DATA_EMV_TAG];
            return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true cardType:emvData.cardType];
        } else if(emvData.cardData.track2 != nil) {
            [emvData.unencryptedTags setValue:emvData.cardData.track2 forKey:TRACK2_DATA_EMV_TAG];
            return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false cardType:emvData.cardType];
        }
    } else if (emvData.unencryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false cardType:emvData.cardType];
    } else if (emvData.encryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true cardType:emvData.cardType];
    }
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(NSDictionary*) tags isEncrypted:(BOOL) isEncrypted cardType:(int) cardType {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    NSMutableDictionary *outgoingTags;
    NSData *tagsAsNSData;
    NSString *tlvInHex;
    if (cardType == 1) {
        outgoingTags = [tags mutableCopy];
    } else {
        NSDictionary *transactionResultDictionary;
        NSData *tsysTags = [IDTUtility hexToData:@"508E82959A9B9C5F2A9F029F039F1A9F219F269F279F339F349F359F369F379F394F845F2D5F349F069F129F099F405F369F1E9F105657FF8106FF8105FFEE14FFEE06"];
        RETURN_CODE emvRetrieveTransactionResultRt = [[IDT_VP3300 sharedController] emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
        if(RETURN_CODE_DO_SUCCESS == emvRetrieveTransactionResultRt) {
            outgoingTags = [transactionResultDictionary objectForKey:@"tags"];
        } else {
            [Teleport logError:@"Failed to retrieve tlv from Device"];
            tlvInHex = @"Failed to retrieve tlv from Device";
        }
    }
    //TODO Search for this data element(DFEF18) Track2 Data during MC contactless swipe
    NSString *track2Data57 = [IDTUtility dataToHexString:[tags objectForKey:TRACK2_DATA_EMV_TAG]];
    if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
        clearentTransactionTokenRequest.track2Data = track2Data57.uppercaseString;
        [outgoingTags setObject:track2Data57 forKey:TRACK2_DATA_EMV_TAG];
    } else {
        NSDictionary *ff8105 = [IDTUtility TLVtoDICT_HEX_ASCII:[tags objectForKey:@"FF8105"]];
        if(ff8105 != nil) {
            [Teleport logInfo:@"ff8105 found"];
            NSString *track2Data9F6B = [ff8105 objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG];
            if(track2Data9F6B != nil && !([track2Data9F6B isEqualToString:@""])) {
                [Teleport logInfo:@"Use the track 2 data from tag 9F6B"];
                clearentTransactionTokenRequest.track2Data = track2Data9F6B.uppercaseString;
            } else {
                [Teleport logError:@"Mobile SDK failed to read Track2Data"];
                clearentTransactionTokenRequest.track2Data = @"Mobile SDK failed to read Track2Data";
            }
        }
    }
    
    [self addRequiredTags: outgoingTags];
    clearentTransactionTokenRequest.applicationPreferredNameTag9F12 = [IDTUtility dataToString:[outgoingTags objectForKey:@"9F12"]];
    if(clearentTransactionTokenRequest.applicationPreferredNameTag9F12 == nil || [clearentTransactionTokenRequest.applicationPreferredNameTag9F12 isEqualToString:@""]) {
        clearentTransactionTokenRequest.applicationPreferredNameTag9F12 = [IDTUtility dataToString:[outgoingTags objectForKey:@"50"]];
    }
    [self removeInvalidTSYSTags: outgoingTags];
   
    tagsAsNSData = [IDTUtility DICTotTLV:outgoingTags];
    tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    
    clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.encrypted = isEncrypted;
    
    return clearentTransactionTokenRequest;
}

- (void) addRequiredTags: (NSMutableDictionary*) outgoingTags {
    NSData *kernelInHex = [IDTUtility stringToData:self.kernelVersion];
    [outgoingTags setObject:[IDTUtility stringToData:self.deviceSerialNumber] forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
    [outgoingTags setObject:kernelInHex forKey:KERNEL_VERSION_EMV_TAG];
}

//Remove any tags that would make the request fail in TSYS.
- (void) removeInvalidTSYSTags: (NSMutableDictionary*) outgoingTags {
    [outgoingTags removeObjectForKey:@"DFEF4D"];
    [outgoingTags removeObjectForKey:@"DFEF4C"];
    [outgoingTags removeObjectForKey:@"FFEE06"];
    [outgoingTags removeObjectForKey:@"FFEE13"];
    [outgoingTags removeObjectForKey:@"FFEE14"];
    [outgoingTags removeObjectForKey:@"FF8106"];
    [outgoingTags removeObjectForKey:@"FF8105"];
    [outgoingTags removeObjectForKey:TRACK2_DATA_EMV_TAG];
    [outgoingTags removeObjectForKey:TRACK1_DATA_EMV_TAG];
    [outgoingTags removeObjectForKey:@"DFEE26"];
    [outgoingTags removeObjectForKey:@"FFEE01"];
    [outgoingTags removeObjectForKey:@"DF8129"];
    [outgoingTags removeObjectForKey:@"9F12"];
    
    NSString *data9F6E = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"9F6E"]];
    if(data9F6E == nil || ([data9F6E isEqualToString:@""])) {
        [outgoingTags removeObjectForKey:@"9F6E"];
    }
    NSString *data4F = [IDTUtility dataToHexString:[outgoingTags objectForKey:@"4F"]];
    if(data4F == nil || ([data4F isEqualToString:@""])) {
        [outgoingTags removeObjectForKey:@"4F"];
    }
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
    
    [Teleport logInfo:@"Call Clearent to produce transaction token"];
    
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[ClearentUtils createExchangeChainId:self.deviceSerialNumber] forHTTPHeaderField:@"exchangeChainId"];
    [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self deviceMessage:error.description];
              [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  //[[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
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
        [self.publicDelegate successfulTransactionToken:response];
    } else {
        [self deviceMessage:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];    
    }
}

- (void) clearConfigurationCache {
     [ClearentCache clearConfigurationCache];
}

@end

