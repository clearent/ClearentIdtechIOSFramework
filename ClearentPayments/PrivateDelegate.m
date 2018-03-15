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
    NSLog(@"Call Public delegate lcdDisplay");
    [self.publicDelegate lcdDisplay:(int)mode  lines:(NSArray*)lines];
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming{
     NSLog(@"We do not allow the integrator to use this method. But should we use it ?");
}

- (void) plugStatusChange:(BOOL)deviceInserted{
    NSLog(@"Call Public delegate plugStatusChange");
    [self.publicDelegate plugStatusChange:(BOOL)deviceInserted];
}

-(void)deviceConnected{
    NSLog(@"Call Public delegate deviceConnected");
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
    NSLog(@"Call Public delegate deviceDisconnected");
    [self.publicDelegate deviceDisconnected];
}

- (void) deviceMessage:(NSString*)message {
    NSLog(@"Call Public delegate deviceMessage");
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
    NSLog(@"emvTransactionData called in private delegate" );
    if (emvData.resultCodeV2 != EMV_RESULT_CODE_V2_NO_RESPONSE) NSLog(@"mvData.resultCodeV2 %@!",[NSString stringWithFormat:@"EMV_RESULT_CODE_V2_response = %2X",emvData.resultCodeV2]);
    if (emvData == nil) {
        return;
    }
    NSLog(@"emvData.resultCodeV2 %@!",[NSString stringWithFormat:@"EMV Transaction Data Response: = %@",[[IDT_UniPayIII sharedController] device_getResponseCodeString:error]]);
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        NSLog(@"START SUCCESS: AUTHENTICATION REQUIRED");
    }
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
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (emvData.unencryptedTags != nil) {
        NSData *unencryptedData = [IDTUtility DICTotTLV:emvData.unencryptedTags];
        NSString *tlvInHex = [IDTUtility dataToHexString:unencryptedData];
        clearentTransactionTokenRequest.tlv = tlvInHex;
        clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
        clearentTransactionTokenRequest.deviceSerialNumber = [self serialNumber];
        clearentTransactionTokenRequest.encrypted = FALSE;
    } else if (emvData.encryptedTags != nil) {
        NSData *encryptedData = [IDTUtility DICTotTLV:emvData.encryptedTags];
        NSString *tlvInHex = [IDTUtility dataToHexString:encryptedData];
        clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
        clearentTransactionTokenRequest.deviceSerialNumber = [self serialNumber];
        clearentTransactionTokenRequest.tlv = tlvInHex;
        clearentTransactionTokenRequest.encrypted = TRUE;
    } else {
        NSLog(@"No emv tags. Could this happen?");
    }
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
          if(200 == [httpResponse statusCode]) {
              NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              NSDictionary *responseDictionary = [self responseAsDictionary:responseStr];
              NSString *responseCode = [responseDictionary objectForKey:@"code"];
              if([responseCode isEqualToString:@"200"]) {
                  [self.publicDelegate successOnline:responseStr];
              } else {
                  [self.publicDelegate errorOnline:responseStr];
              }
          } else {
              NSString *errorMessage = @"Failed to create a Clearent Transaction Token";
              [self.publicDelegate errorOnline:errorMessage];
          }
          //Always run the idtech complete method whether an error is returned or not.
          //TODO on success we are suppose to provice host response tags, at a minimum the 8A tag. Not sure how to get this (we aren't doing an authorization or actually running the transaction.
          RETURN_CODE rtComplete = [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
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
