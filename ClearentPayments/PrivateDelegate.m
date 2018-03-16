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
    self.firmwareVersion= [self getFirmwareVersion];
    self.serialNumber = [self getSerialNumber];
    [self.publicDelegate deviceConnected];
}

- (NSString *) getFirmwareVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_UniPayIII sharedController] device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"Firmware version not found";
    }
}

- (NSString *) getSerialNumber {
    NSString *result;
    RETURN_CODE rt = [[IDT_UniPayIII sharedController] config_getSerialNumber:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"Serial number not found";
    }
}

-(void)deviceDisconnected{
    [self.publicDelegate deviceDisconnected];
}

- (void) deviceMessage:(NSString*)message {
    [self.publicDelegate deviceMessage:(NSString*)message];
}

- (void) swipeMSRData:(IDTMSRData*)cardData{
    NSLog(@"swipeMSRData called in private delegate" );
    NSLog(@"--MSR event Received, Type: %d, data: %@", cardData.event, cardData.encTrack1);
    NSLog(@"This needs to be implemented");
}

//TODO Some of this is sample code from the tutorial just so we see the data in the log. Clean up when we don't care about it anymore.
//TODO do we call our error delegate with any of these scenarios ? This method seems to get called multiple times even when waiting for an online response.
- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    if (emvData.resultCodeV2 != EMV_RESULT_CODE_V2_NO_RESPONSE) NSLog(@"mvData.resultCodeV2 %@!",[NSString stringWithFormat:@"EMV_RESULT_CODE_V2_response = %2X",emvData.resultCodeV2]);
    if (emvData == nil) {
        return;
    }
    NSLog(@"emvData.resultCodeV2 %@!",[NSString stringWithFormat:@"EMV Transaction Data Response: = %@",[[IDT_UniPayIII sharedController] device_getResponseCodeString:error]]);
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        NSLog(@"START SUCCESS: AUTHENTICATION REQUIRED");
    }
    //TODO After we initially go online this method gets called with a APPROVED message. Do we need to do anything here ??
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
        NSLog(@"APPROVED");
    }
    //TODO what's this do ? fallback swipe ?
    if (emvData.cardData != nil) [self swipeMSRData:emvData.cardData];
    
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    if (emvData.unencryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
    } else if (emvData.encryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true];
    }
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(NSDictionary*) tags isEncrypted:(BOOL) isEncrypted {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    NSData *tagsAsNSData = [IDTUtility DICTotTLV:tags];
    NSString *tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    clearentTransactionTokenRequest.tlv = tlvInHex;
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self serialNumber];
    clearentTransactionTokenRequest.encrypted = isEncrypted;
    return clearentTransactionTokenRequest;
}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    NSString *targetUrl = [NSString stringWithFormat:@"%@", [self.publicDelegate getTransactionTokenUrl]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];
    if (error) {
        [self.publicDelegate errorOnline:@"Failed to serialize the clearent transaction token request"];
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
              [self.publicDelegate errorOnline:error.description];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  NSDictionary *responseDictionary = [self responseAsDictionary:responseStr];
                  NSString *responseCode = [responseDictionary objectForKey:@"code"];
                  if([responseCode isEqualToString:@"200"]) {
                      [self.publicDelegate successOnline:responseStr];
                  } else {
                      [self.publicDelegate errorOnline:responseStr];
                  }
              } else {
                  [self.publicDelegate errorOnline:responseStr];
              }
          }
          
          //Always run the idtech complete method whether an error is returned or not.
          //We aren't doing an authorization or actually running the transaction so providing the 8A tag is just an acknowledgement the IDTech process should continue down a successful path.
          RETURN_CODE rtComplete = [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
          //TODO do we want to alert someone of this completion code ?
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
