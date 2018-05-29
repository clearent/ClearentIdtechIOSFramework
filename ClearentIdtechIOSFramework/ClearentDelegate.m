//
//  ClearentDelegate.m
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentDelegate.h"
#import "IDTech/IDTUtility.h"

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
static NSString *const TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG = @"9F6B";
static NSString *const TAC_DEFAULT = @"DF13";
static NSString *const TAC_DENIAL = @"DF14";
static NSString *const TAC_ONLINE = @"DF15";

static NSString *const DEVICE_SERIAL_NUMBER_EMV_TAG = @"DF78";
static NSString *const KERNEL_VERSION_EMV_TAG = @"DF79";
static NSString *const GENERIC_CARD_READ_ERROR_RESPONSE = @"Card read error";
static NSString *const GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE = @"Create Transaction Token Failed";

@implementation ClearentDelegate

- (void) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey  {
    self.publicDelegate = publicDelegate;
    self.baseUrl = clearentBaseUrl;
    self.publicKey = publicKey;
}

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines {
    [self.publicDelegate lcdDisplay:mode  lines:lines];
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
    
}

- (NSString *) getFirmwareVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Firmware version not found";
    }
}

- (NSString *) getKernelVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Kernel Version Unknown";
    }
}

- (NSString *) getDeviceSerialNumber {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] config_getSerialNumber:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Serial number not found";
    }
}

-(void)deviceDisconnected{
    [self.publicDelegate deviceDisconnected];
}

- (void) deviceMessage:(NSString*)message {
    [self.publicDelegate deviceMessage:message];
}

- (void) swipeMSRData:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && (cardData.track2 != nil || cardData.encTrack2 != nil)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else {
        [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        NSString *encryptedTrack2Data = [[NSString alloc] initWithData:cardData.encTrack2
                                                              encoding:NSUTF8StringEncoding];
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:true track2Data:encryptedTrack2Data];
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:false track2Data:cardData.track2];
    }
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionToken:(BOOL)emv encrypted:(BOOL)encrypted track2Data:(NSString*) track2Data {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    clearentTransactionTokenRequest.emv = emv;
    clearentTransactionTokenRequest.encrypted = encrypted;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.track2Data = track2Data;
    return clearentTransactionTokenRequest;
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    if (emvData == nil) {
        return;
    }
    //The mobile-jwt call should succeed or fail. We call the IDTech complete method every time. We alert the client by messaging them via the errorTransactionToken delegate method.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
        return;
    }
    //We aren't starting an authorization so this result code should never be set. But return just in case.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        return;
    }
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_CARD_ERROR) {
        [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
        return;
    }
    
    int entryMode = 0;
    if (emvData.unencryptedTags != nil) {
        entryMode = getEntryMode([[emvData.unencryptedTags objectForKey:@"9F39"] description]);
    } else if (emvData.encryptedTags != nil) {
        entryMode = getEntryMode([[emvData.encryptedTags objectForKey:@"9F39"] description]);
    }
    //Not sure how this scenario could happen but until we get some feedback from IdTech for some of the odd delegate communication behavior I think we'll just be defensive.
    if(entryMode == 0) {
        return;
    }
    //When we get an Go Online result code let's create the transaction token (jwt)
    //TODO clean up the carddata not nil check..its done in two places
    if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
        if(entryMode == SWIPE) {
            [self swipeMSRData:emvData.cardData];
        } else if(isSupportedEmvEntryMode(entryMode)) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            [self createTransactionToken:clearentTransactionTokenRequest];
        } else {
            [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
        }
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE || emvData.cardType == 1)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        [self createTransactionToken:clearentTransactionTokenRequest];
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
            return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true];
        } else if(emvData.cardData.track2 != nil) {
            [emvData.unencryptedTags setValue:emvData.cardData.track2 forKey:TRACK2_DATA_EMV_TAG];
            return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
        }
    } else if (emvData.unencryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
    } else if (emvData.encryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true];
    }
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(NSDictionary*) tags isEncrypted:(BOOL) isEncrypted {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    
    NSMutableDictionary *mutableTags = [tags mutableCopy];
    [mutableTags setObject:self.deviceSerialNumber forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
    [mutableTags setObject:self.kernelVersion forKey:KERNEL_VERSION_EMV_TAG];
    
    //set Major tags
    //9F35 Terminal Type 21
    //9F33 Terminal Capabilities 6028C8
    //9F40 Additional Terminal Capabilities F000F0A001
    //DF26 Enable Revocation List Processing 01
    //DF11 Enable Transaction Logging 00
    //DF27 Enable Exception List Processing 00
    //DFEE1E Terminal Configuration D0DC20D0C41E1400
    
    [mutableTags setObject:@"6028C8" forKey:@"9F33"];
    [mutableTags setObject:@"F000F0A001" forKey:@"9F40"];
    [mutableTags setObject:@"01" forKey:@"DF26"];
    [mutableTags setObject:@"00" forKey:@"DF11"];
    [mutableTags setObject:@"00" forKey:@"DF27"];
    
    //Set Minor Tags
    //5F36 Transaction Currency Exponent 02
    //9F1A Terminal Country Code 840
    //9F1E Interface Device (IFD) Serial Number 5465726D696E616C
    //9F15 Merchant Category Code 5999
    //9F16 Merchant Identifier 888000001516
    //9F1C Terminal Identification 1515
    //9F4E Merchant Name and Location Test Merchant
    [mutableTags setObject:@"02" forKey:@"5F36"];
    [mutableTags setObject:@"0840" forKey:@"9F1A"];
    [mutableTags setObject:@"5465726D696E616C" forKey:@"9F1E"];
    [mutableTags setObject:@"5999" forKey:@"9F15"];
    
    //888000001516 as CEC0ECB5EC
    [mutableTags setObject:@"888000001516" forKey:@"9F16"];
    [mutableTags setObject:@"1515" forKey:@"9F1C"];
    //test merchant in hex 54657374204d65726368616e74
    [mutableTags setObject:@"54657374204d65726368616e74" forKey:@"9F4E"];
    
    
    //Remove Tags
    [mutableTags removeObjectForKey:@"DF78"];
    [mutableTags removeObjectForKey:@"DF79"];
    [mutableTags removeObjectForKey:@"DF27"];
    [mutableTags removeObjectForKey:@"DFEF4D"];
    [mutableTags removeObjectForKey:@"DFEF4C"];
    [mutableTags removeObjectForKey:@"DF11"];
    [mutableTags removeObjectForKey:@"DFEE26"];
    
    [mutableTags removeObjectForKey:@"DFEE25"];
    [mutableTags removeObjectForKey:@"FFEE01"];
    [mutableTags removeObjectForKey:@"DFEE23"];
    [mutableTags removeObjectForKey:@"DF26"];
    
    [mutableTags removeObjectForKey:@"9F16"];
    
    //Get tags based on TSYS impl guide. TODO Rely on on what is returned from emv_retrieveTransactionResult
    //NSData *tsysTags = [IDTUtility hexToData:@"82 9A 9C 5F2A 9F0D 9F0E 9F0F 9F21 9F35 9F36 9F06"];
    
    //CONTACT 9F40 9F06 9F09 9F15 9F33 9F1A 5F2A 5F36 9F1B 9F35 9F53 9F1E 9F16 9F1C 9F4E 82 009A 009C 9F0D 9F0E 9F0F 9F36
    //CONTACTLESS 9F6D 9F66
    //0082009A009C
    
    //remove these for now - 9F6E 9F53 9F16
    //Original big one
    NSData *tsysTags = [IDTUtility hexToData:@"82959A9B9C9F349F029F039F404F849F069F099F159F339F1A5F2A5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //up to 5F36
    
    //include 9F09 9F15 9F33 9F1A 5F2A
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //NSData *tsysTags = [IDTUtility hexToData:@"9F099F339F1A5F2A5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //82959A9B9C9F349F029F039F404F849F06
    
    // exclude 9F09 9F15 9F33 9F1A 5F2A
    
    //include 82959A9B9C9F349F02
    //NSData *tsysTags = [IDTUtility hexToData:@"82959A9B9C9F349F025F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //excluded 9F03 9F40 9F06 4F 84 9F09 9F15 9F33 9F1A 5F2A
    //NSData *tsysTags = [IDTUtility hexToData:@"9F0382959A9B9C9F349F025F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //try 9F15 9F1A 5F2A
    //NSData *tsysTags = [IDTUtility hexToData:@"82959A9B9C9F349F025F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //Good one
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //    NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"5F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F10"];
    //NSData *tsysTags = [IDTUtility hexToData:@""];
    
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //    NSData *tsysTagsGroupIII55Only = [IDTUtility hexToData:@"82959A9B9C5F2A9F029F039F0D9f0E9F0F9F1A9F219F269F279F339F349F359F369F379F399F404F845F2D5F349F069F10DF78DF79"];
    
    NSDictionary *transactionResultDictionary;
    RETURN_CODE transactionDateRt = [[IDT_VP3300 sharedController] emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
    NSData *tagsAsNSData;
    NSString *tlvInHex;
    NSMutableDictionary *mutableTags2;
    if(RETURN_CODE_DO_SUCCESS == transactionDateRt) {
        NSDictionary *transactionTags = [transactionResultDictionary objectForKey:@"tags"];
        NSDictionary *combined = [IDTUtility combineDictionaries:(NSDictionary*)transactionTags dest:mutableTags overwrite:false];
        
        mutableTags2 = [combined mutableCopy];
        [mutableTags2 removeObjectForKey:@"DF27"];
        [mutableTags2 removeObjectForKey:@"DFEF4D"];
        [mutableTags2 removeObjectForKey:@"DFEF4C"];
        [mutableTags2 removeObjectForKey:@"DF11"];
        [mutableTags2 removeObjectForKey:@"DFEE26"];
        [mutableTags2 removeObjectForKey:@"DF78"];
        [mutableTags2 removeObjectForKey:@"DF79"];
        [mutableTags2 removeObjectForKey:@"DFEE25"];
        [mutableTags2 removeObjectForKey:@"FFEE01"];
        [mutableTags2 removeObjectForKey:@"DFEE23"];
        [mutableTags2 removeObjectForKey:@"DF26"];
        
        [mutableTags2 removeObjectForKey:@"9F16"];
        
        //tagsAsNSData = [IDTUtility DICTotTLV:mutableTags2];
        
        tagsAsNSData = [IDTUtility DICTotTLV:mutableTags2];
        
        tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    } else {
        tagsAsNSData = [IDTUtility DICTotTLV:mutableTags];
        tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    }
    clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.encrypted = isEncrypted;
    
    NSString *track2Data57 = [IDTUtility dataToHexString:[mutableTags2 objectForKey:TRACK2_DATA_EMV_TAG]];
    if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
        clearentTransactionTokenRequest.track2Data = track2Data57;
    } else {
        NSDictionary *ff8105 = [IDTUtility TLVtoDICT_HEX_ASCII:[tags objectForKey:@"FF8105"]];
        NSString *track2Data9F6B = [ff8105 objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG];
        if(track2Data9F6B != nil && !([track2Data9F6B isEqualToString:@""])) {
            clearentTransactionTokenRequest.track2Data = track2Data9F6B;
        } else {
            clearentTransactionTokenRequest.track2Data = @"Mobile SDK failed to read Track2Data";
        }
    }
    return clearentTransactionTokenRequest;
}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.baseUrl, @"rest/v2/mobilejwt"];
    NSLog(@"targetUrl: %@", targetUrl);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];
    
    if (error) {
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        return;
    }
    
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self.publicDelegate errorTransactionToken:error.description];
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
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    } else {
        NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
        NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
        NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
        if(errorMessage != nil) {
            [self.publicDelegate errorTransactionToken:[NSString stringWithFormat:@"%@. %@.", GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE, errorMessage]];
        } else {
            [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
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
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
    NSString *responseCode = [jsonDictionary objectForKey:@"code"];
    if([responseCode isEqualToString:@"200"]) {
        [self.publicDelegate successfulTransactionToken:response];
    } else {
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
}

@end

