//
//  ClearentDelegate.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentDelegate.h"
#import "IDTech/IDTUtility.h"

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
static NSString *const TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG = @"9F6B";
static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";
static NSString *const EMV_DIP_ENTRY_MODE_TAG = @"05";
static NSString *const DEVICE_SERIAL_NUMBER_EMV_TAG = @"DF78";
static NSString *const KERNEL_VERSION_EMV_TAG = @"DF79";
static NSString *const GENERIC_CARD_READ_ERROR_RESPONSE = @"Card read error";
static NSString *const GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE = @"Create Transaction Token Failed";

@implementation ClearentDelegate

- (void) init : (id <Clearent_Public_IDT_UniPayIII_Delegate>) publicDelegate {
    self.publicDelegate = publicDelegate;
    NSLog(@"ClearentDelegate initialized");
}

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines {
    [self.publicDelegate lcdDisplay:(int)mode  lines:(NSArray*)lines];
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming {
     //NSLog(@"Clearent debugging only");
}

- (void) plugStatusChange:(BOOL)deviceInserted {
    [self.publicDelegate plugStatusChange:(BOOL)deviceInserted];
}

-(void)deviceConnected {
    [self configuration];
    [self.publicDelegate deviceConnected];
}

- (void) configuration {
    self.firmwareVersion= [self getFirmwareVersion];
    self.deviceSerialNumber = [self getDeviceSerialNumber];
    self.kernelVersion = [self getKernelVersion];
    NSMutableDictionary *tags;
    RETURN_CODE rt = [[IDT_UniPayIII sharedController] emv_retrieveTerminalData:&tags];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        [tags setObject:EMV_DIP_ENTRY_MODE_TAG forKey:IDTECH_EMV_ENTRY_MODE_EMV_TAG];
    } else{
        [self deviceMessage:@"Failed to preconfigure required EMV tags"];
    }
    [[IDT_UniPayIII sharedController] emv_setTerminalData:tags];
}

- (NSString *) getFirmwareVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_UniPayIII sharedController] device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Firmware version not found";
    }
}

- (NSString *) getKernelVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_UniPayIII sharedController] emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Kernel Version Unknown";
    }
}

- (NSString *) getDeviceSerialNumber {
    NSString *result;
    RETURN_CODE rt = [[IDT_UniPayIII sharedController] config_getSerialNumber:&result];
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
    [self.publicDelegate deviceMessage:(NSString*)message];
}

//TODO should we return an error here ? sometimes idtech sends the message here and says its an error but then sends the message to emvTransactionData and says there IS card data?!
- (void) swipeMSRData:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && (cardData.track2 != nil || cardData.encTrack2 != nil)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else {
        [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
    }
}

//TODO not handling encrypted track 2 data correctly.
- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        NSString *encryptedTrack2Data = [[NSString alloc] initWithData:cardData.encTrack2
                                                              encoding:NSUTF8StringEncoding];
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:true track2Data:encryptedTrack2Data];
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:false track2Data:scrubInvalidCharactersForSwipeTrack2Data(cardData.track2)];
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
    //The emv-jwt call should succeed or fail. We call the IDTech complete method every time. We alert the client by messaging them via the errorTransactionToken delegate method.
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
    
    //Because of how the IdTech framework is sending messages to the swipe method and this method I would think we would want to never process in this method if there is no response.
//
//    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_NO_RESPONSE) {
//        return;
//    }
//
    
    int entryMode = 0;
    if (emvData.unencryptedTags != nil) {
        entryMode = getEntryMode([[emvData.unencryptedTags objectForKey:@"9F39"] description]);
    } else if (emvData.encryptedTags != nil) {
         entryMode = getEntryMode([[emvData.encryptedTags objectForKey:@"9F39"] description]);
    }
    //Not sure how this scenario could happen but until we get some feedback from IdTech for some of the odd delgate communcation behavior I think we'll just be defensive.
    if(entryMode == 0) {
        return;
    }
    //When we get an Go Online result code let's create the transaction token (jwt)
    //TODO contactless is not returning the correct result code so we arent sending it to the server. ignoring this issue for now for contactless and nonfallback
    if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
        if(entryMode == SWIPE) {
            [self swipeMSRData:emvData.cardData];
        } else if(isSupportedEmvEntryMode(entryMode)) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            [self createTransactionToken:clearentTransactionTokenRequest];
        } else {
            [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
        }
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE)) {
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
            NSString *scrubbedTrack2Data = scrubInvalidCharactersForEmvTrack2Data(emvData.cardData.track2);
            [emvData.unencryptedTags setValue:scrubbedTrack2Data forKey:TRACK2_DATA_EMV_TAG];
            return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
        }
    } else if (emvData.unencryptedTags != nil) {
        NSString *track2Data57 = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:TRACK2_DATA_EMV_TAG]];
        NSString *track2Data9F6B = [IDTUtility dataToHexString:[emvData.unencryptedTags objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG]];
        NSString *scrubbedTrack2Data;
        if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
            scrubbedTrack2Data = scrubInvalidCharactersForEmvTrack2Data(track2Data57);
        } else if(track2Data9F6B != nil && !([track2Data9F6B isEqualToString:@""])) {
            scrubbedTrack2Data = scrubInvalidCharactersForEmvTrack2Data(track2Data9F6B);
        }
        [emvData.unencryptedTags setValue:scrubbedTrack2Data forKey:TRACK2_DATA_EMV_TAG];
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
    //TODO fake amount is this required ?
    [mutableTags setObject:@"4.55" forKey:@"9F03"];
    NSData *tagsAsNSData = [IDTUtility DICTotTLV:mutableTags];
    NSString *tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.encrypted = isEncrypted;
    return clearentTransactionTokenRequest;
}

//Probably leaks
NSString* scrubInvalidCharactersForEmvTrack2Data (NSString* originalTrack2Data) {
    NSString *scrubbedTrack2Data;
    NSString *workTrack2Data = [originalTrack2Data copy];
    NSString *track2DataWithout00000F = [workTrack2Data stringByReplacingOccurrencesOfString:@"00000f" withString:@"F"];
    NSString *track2DataWithout00000FAndSixAtEnd = [track2DataWithout00000F stringByReplacingOccurrencesOfString:@"00000?6" withString:@"?"];
    NSString *prefixToRemove = @"f";
    NSString *work2Track2Data = [track2DataWithout00000FAndSixAtEnd copy];
    if ([work2Track2Data hasPrefix:prefixToRemove]) {
        NSString *track2DataWithoutPrefixf = [work2Track2Data substringFromIndex:[prefixToRemove length]];
        NSString *track2DataWithfChangedtoD = [track2DataWithoutPrefixf stringByReplacingOccurrencesOfString:@"f" withString:@"D"];
        scrubbedTrack2Data = track2DataWithfChangedtoD;
    } else {
        scrubbedTrack2Data = [track2DataWithout00000FAndSixAtEnd copy];
    }
    return scrubbedTrack2Data;
}

NSString* scrubInvalidCharactersForSwipeTrack2Data (NSString* originalTrack2Data) {
    NSString *scrubbedTrack2Data;
    NSString *workTrack2Data = [originalTrack2Data copy];
    NSString *track2DataWithoutEqualAtEnd = [workTrack2Data stringByReplacingOccurrencesOfString:@"?=" withString:@"?"];
    scrubbedTrack2Data = [track2DataWithoutEqualAtEnd copy];
    return scrubbedTrack2Data;
}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    NSString *targetUrl = [NSString stringWithFormat:@"%@", [self.publicDelegate getTransactionTokenUrl]];
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
    [request setValue:[self.publicDelegate getPublicKey] forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self.publicDelegate errorTransactionToken:error.description];
              [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
                  [self handleResponse:responseStr];
              } else {
                  [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
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
