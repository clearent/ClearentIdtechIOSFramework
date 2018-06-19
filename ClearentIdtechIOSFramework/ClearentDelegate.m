//
//  ClearentDelegate.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentDelegate.h"
#import "IDTech/IDTUtility.h"
#import "ReaderConfigurator.h"

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

//TODO talk about this. Initially I did not have this exposed in the public delegate. This information is needed when talking to IDTech support. The problem is when an unencrypted reader is used sensitive data is exposed. Encrypted data is fine ?
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
    if(!self.configured) {
        [self configure];
    }
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

-(void) configure {
    self.configured = NO;
    if(self.deviceSerialNumber  == nil) {
        [self deviceMessage:@"CONNECT DEVICE TO CONFIGURE"];
        return;
    }
    if(self.baseUrl == nil) {
        [self deviceMessage:@"Clearent Base Url is required for reader configuration. Ex - https://gateway-sb.clearent.net"];
        return;
    }
    NSString *trimmedDeviceSerialNumber = [self.deviceSerialNumber substringToIndex:10];
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@/%@", self.baseUrl, @"rest/v2/mobile/devices",  trimmedDeviceSerialNumber];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    NSLog(@"config targetUrl: %@", targetUrl);
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self deviceMessage:@"CONFIGURATION FAILED"];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  NSData *data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
                  NSError *error;
                  NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                 options:0
                                                                                   error:&error];
                  NSLog(@"config: %@", jsonDictionary);
                  if (error) {
                      [self deviceMessage:@"CONFIGURATION FAILED"];
                  } else {
                      NSString *readerConfigurationMessage = [ReaderConfigurator configure:jsonDictionary];
                      NSLog(@"Reader Configuration Message: %@", readerConfigurationMessage);
                      [self deviceMessage:readerConfigurationMessage];
                      self.configured = YES;
                  }
              } else {
                  [self deviceMessage:@"CONFIGURATION FAILED"];
              }
          }
          data = nil;
          response = nil;
          error = nil;
      }] resume];
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
        NSLog(@"swipeMSRData createTransactionToken");
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else {
        NSLog(@"swipeMSRData generic error");
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

    NSLog(@"EMV Transaction Data Response: = %@",[[IDT_VP3300 sharedController] device_getResponseCodeString:error]);

    if (error == 60938) {
        NSLog(@"Failed to read card. This was happening when trying to get visa contactless to work. Send msg back to delegate?");
        return;
    }
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

    if (emvData.cardType == 1) {
        NSLog(@"CONTACTLESS");
    }

    int entryMode = 0;
    if (emvData.unencryptedTags != nil) {
        entryMode = getEntryMode([[emvData.unencryptedTags objectForKey:@"9F39"] description]);
    } else if (emvData.encryptedTags != nil) {
        entryMode = getEntryMode([[emvData.encryptedTags objectForKey:@"9F39"] description]);
    }

    if(entryMode == 0) {
        NSLog(@"No entryMode defined");
        return;
    } else {
        NSLog(@"entryMode: %d", entryMode);
    }
    //When we get an Go Online result code let's create the transaction token (jwt)
    //TODO clean up the carddata not nil check..its done in two places
    if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
        if(entryMode == SWIPE) {
            NSLog(@"swipeMSRData");
            [self swipeMSRData:emvData.cardData];
        } else if(isSupportedEmvEntryMode(entryMode)) {
            NSLog(@"isSupportedEmvEntryMode true");
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            NSLog(@"createTransactionToken 1");
            [self createTransactionToken:clearentTransactionTokenRequest];
        } else {
             NSLog(@"generic error 1");
            [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
        }
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE || emvData.cardType == 1)) {
        NSLog(@"createTransactionToken 2");
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
        NSData *tsysTags = [IDTUtility hexToData:@"8291959A9B9C5F2A9F029F039F1A9F219F269F279F339F349F359F369F379F394F845F2D5F349F069F09DF78DF799F155F369F1B9F1E9F1C9F6E9F109F5B5657FF8106FF8105FFEE14FFEE06"];
        RETURN_CODE emvRetrieveTransactionResultRt = [[IDT_VP3300 sharedController] emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
        if(RETURN_CODE_DO_SUCCESS == emvRetrieveTransactionResultRt) {
            NSLog(@"retrieved emv tags");
            outgoingTags = [transactionResultDictionary objectForKey:@"tags"];
        } else {
            tlvInHex = @"Failed to retrieve tlv from reader";
            //TODO handle error?
        }
    }
    //TODO Search for this data element(DFEF18) Track2 Data during MC contactless swipe
    NSString *track2Data57 = [IDTUtility dataToHexString:[tags objectForKey:TRACK2_DATA_EMV_TAG]];
    if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
        clearentTransactionTokenRequest.track2Data = track2Data57;
    } else {
        NSDictionary *ff8105 = [IDTUtility TLVtoDICT_HEX_ASCII:[tags objectForKey:@"FF8105"]];
        if(ff8105 != nil) {
            NSString *track2Data9F6B = [ff8105 objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG];
            if(track2Data9F6B != nil && !([track2Data9F6B isEqualToString:@""])) {
                NSLog(@"Use the track 2 data from tag 9F6B");
                clearentTransactionTokenRequest.track2Data = track2Data9F6B;
            } else {
                NSLog(@"Mobile SDK failed to read Track2Data");
                clearentTransactionTokenRequest.track2Data = @"Mobile SDK failed to read Track2Data";
            }
        }
    }
    
    //Add required tags. TODO try moving these into the ReaderConfiguration setMajorTags method. if they 'disappear' when coming into this method move them back here.
    [self addRequiredTags: outgoingTags];
    
    //Remove any tags that would make the request fail in TSYS.
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
    [outgoingTags setObject:self.deviceSerialNumber forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
    [outgoingTags setObject:self.kernelVersion forKey:KERNEL_VERSION_EMV_TAG];
    
    //majors
    [outgoingTags setObject:@"6028C8" forKey:@"9F33"];
    [outgoingTags setObject:@"F000F0A001" forKey:@"9F40"];
    // [retrievedResultTags setObject:@"01" forKey:@"DF26"];
    
    //Set Minor Tags
    
    //Should set these as NSData and not NSString ?? [tags setObject:[IDTUtility hexToData:@"D0DC20D0C41E1400"] forKey:@"DFEE1E"];
    [outgoingTags setObject:@"02" forKey:@"5F36"];
    [outgoingTags setObject:@"0840" forKey:@"9F1A"];
    [outgoingTags setObject:@"5465726D696E616C" forKey:@"9F1E"];
    [outgoingTags setObject:@"5999" forKey:@"9F15"];
    [outgoingTags setObject:@"888000001516" forKey:@"9F16"];
    //added 6-11, removed from individual aid configuration
    [outgoingTags setObject:@"9F3704" forKey:@"DF25"];
    [outgoingTags setObject:@"00000000" forKey:@"9F1B"];
    //[retrievedResultTags setObject:@"54657374204d65726368616e74" forKey:@"9F4E"];
    //add these back in if needed
    //currently sends 3837363534333231 but we have 151 (needs to be 8 bytes)
    //[retrievedResultTags setObject:@"1515" forKey:@"9F1C"];
    
}

- (void) removeInvalidTSYSTags: (NSMutableDictionary*) outgoingTags {
    [outgoingTags removeObjectForKey:@"DFEF4D"];
    [outgoingTags removeObjectForKey:@"DFEF4C"];
    [outgoingTags removeObjectForKey:@"FFEE06"];
    [outgoingTags removeObjectForKey:@"FFEE13"];
    [outgoingTags removeObjectForKey:@"FFEE14"];
    [outgoingTags removeObjectForKey:@"FF8106"];
    [outgoingTags removeObjectForKey:@"FF8105"];
    [outgoingTags removeObjectForKey:TRACK2_DATA_EMV_TAG];
    [outgoingTags removeObjectForKey:@"DFEE26"];
    [outgoingTags removeObjectForKey:@"FFEE01"];
    [outgoingTags removeObjectForKey:@"DF8129"];
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

