//
//  PrivateDelegate.m
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "PrivateDelegate.h"
#import "IDTech/IDTUtility.h"

@implementation PrivateDelegate

- (void) init : (id <Clearent_Public_IDT_UniPayIII_Delegate>) publicDelegate {
    self.publicDelegate = publicDelegate;
    NSLog(@"PrivateDelegate initialized");
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
        //Set the terminal entry mode for ICC (emv dip)
        [tags setObject:@"05" forKey:@"DFEE17"];
        //set the device serial number
        [tags setObject:self.deviceSerialNumber forKey:@"DF78"];
        //set the kernel version
        [tags setObject:self.kernelVersion forKey:@"DF79"];
    } else{
        NSLog(@"Failed to preconfigure required EMV tags");
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

- (void) swipeMSRData:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && cardData.track2 != nil) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else {
        [self.publicDelegate errorTransactionToken:@"Card read error"];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    if(cardData == nil) {
        [self.publicDelegate errorTransactionToken:@"Card read error"];
    }
    if (cardData.unencryptedTags != nil) {
        if(cardData != nil && cardData.track2 != nil) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
            clearentTransactionTokenRequest.emv = false;
            clearentTransactionTokenRequest.encrypted = false;
            clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
            clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
            clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
            clearentTransactionTokenRequest.track2Data = cardData.track2;
            return clearentTransactionTokenRequest;
        } else {
            [self.publicDelegate errorTransactionToken:@"Card read error"];
        }
    } else if (cardData.encryptedTags != nil) {
        if(cardData != nil && cardData.encTrack2 != nil) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
            clearentTransactionTokenRequest.emv = false;
            clearentTransactionTokenRequest.encrypted = true;
            clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
            clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
            clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
            NSString *encryptedTrack2Data = [[NSString alloc] initWithData:cardData.encTrack2
                                                                 encoding:NSUTF8StringEncoding];
            clearentTransactionTokenRequest.track2Data = encryptedTrack2Data;
            return clearentTransactionTokenRequest;
        } else {
            [self.publicDelegate errorTransactionToken:@"Card read error"];
        }
    
    }
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    return clearentTransactionTokenRequest;
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    if (emvData == nil) {
        return;
    }
    //The emv-jwt call could success or fail. We call the IDTech complete method with a successful tag every time. We alert the client by messaging them via the errorTransactionToken delegate method.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
        return;
    }
    //We aren't starting an authorization so this result code should never be set. But return just in case.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        return;
    }
    if ( emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_CARD_ERROR) {
        [self.publicDelegate errorTransactionToken:@"Card read error"];
        return;
    }
    
    NSString *entryMode;
    if (emvData.unencryptedTags != nil) {
        entryMode = [[emvData.unencryptedTags objectForKey:@"9F39"] description];
    } else if (emvData.encryptedTags != nil) {
        entryMode = [[NSString alloc] initWithData:[emvData.encryptedTags objectForKey:@"9F39"] encoding:NSUTF8StringEncoding];
    }
    
    //TODO contactless is not returning the correct result code
    
    //fallback swipe or is it ? A regular swipe is coming here. So, for now we just call swipeMSRData, since sometimes IdTech just sends the message to that method.
    //TODO The problem is we need to identify the fallback swipe and send it to emv-jwt.
    if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
        NSLog(@"entryMode (90=regular swipe, 80=fallback swipe, 95=nontech fallback, 07=contactless, 91=contactless ): %@", entryMode);
        if(entryMode != nil && [entryMode isEqualToString:@"<90>"]) {
            [self swipeMSRData:emvData.cardData];
        } else if(entryMode != nil && ([entryMode isEqualToString:@"<80>"] || [entryMode isEqualToString:@"<85>"] || [entryMode isEqualToString:@"<07>"] || [entryMode isEqualToString:@"<91>"])) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            [self createTransactionToken:clearentTransactionTokenRequest];
        }
    }
    //When we get an Go Online result code let's create the transaction token (jwt)
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    if (emvData.unencryptedTags != nil) {
        if(emvData.cardData != nil && emvData.cardData.track2 != nil) {
            NSMutableDictionary *mutableTags = [emvData.unencryptedTags mutableCopy];
            [mutableTags setValue:emvData.cardData.track2 forKey:@"57"];
            return [self createClearentTransactionTokenRequest:mutableTags isEncrypted: false];
        } else {
            return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
        }
    } else if (emvData.encryptedTags != nil) {
        if(emvData.cardData != nil && emvData.cardData.encTrack2 != nil) {
            NSMutableDictionary *mutableTags = [emvData.unencryptedTags mutableCopy];
            NSString *encryptedTrack2Data = [[NSString alloc] initWithData:emvData.cardData.encTrack2
                                                                  encoding:NSUTF8StringEncoding];
            [mutableTags setValue:encryptedTrack2Data forKey:@"57"];
            return [self createClearentTransactionTokenRequest:mutableTags isEncrypted: true];
        } else {
           return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true];
        }
    }
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(NSDictionary*) tags isEncrypted:(BOOL) isEncrypted {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    NSData *tagsAsNSData = [IDTUtility DICTotTLV:tags];
    NSString *tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    clearentTransactionTokenRequest.tlv = tlvInHex;
    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.encrypted = isEncrypted;
    return clearentTransactionTokenRequest;
}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    NSString *targetUrl = [NSString stringWithFormat:@"%@", [self.publicDelegate getTransactionTokenUrl]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];
    if (error) {
        [self.publicDelegate errorTransactionToken:@"Failed to serialize the clearent transaction token request"];
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
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  NSDictionary *responseDictionary = [self responseAsDictionary:responseStr];
                  NSString *responseCode = [responseDictionary objectForKey:@"code"];
                  if([responseCode isEqualToString:@"200"]) {
                      [self.publicDelegate successfulTransactionToken:responseStr];
                  } else {
                      [self.publicDelegate errorTransactionToken:responseStr];
                  }
              } else {
                  [self.publicDelegate errorTransactionToken:responseStr];
              }
          }
          data = nil;
          response = nil;
          error = nil;
          //Always run the idtech complete method whether an error is returned or not.
          //We aren't doing an authorization or actually running the transaction so providing the 8A tag is just an acknowledgement the IDTech process should continue down a successful path.
          [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
      }] resume];
}

- (NSDictionary *)responseAsDictionary:(NSString *)stringJson {
    NSData *data = [stringJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                    error:&error];
    if (error) {
        NSLog(@"Error in json: %@", [error description]);
    }
    return jsonDictionary;
}

@end
