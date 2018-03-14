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
    [self.publicDelegate deviceConnected];
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
- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    NSLog(@"emvTransactionData called in private delegate" );
//TODO do we call our error delegate with any of these scenarios ? This method seems to get called multiple times even when waiting for an online response.
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
    //TODO do we need to pull data from any of these objects ? does maskedTags have anything the unencrypted and encrypted objects.
    if (emvData.unencryptedTags != nil) NSLog(@"Unencrypted tags %@!", [NSString stringWithFormat:@"Unencrypted Tags: %@", emvData.unencryptedTags.description]);
    if (emvData.encryptedTags != nil) NSLog(@"Encrypted tags %@!",[NSString stringWithFormat:@"Encrypted Tags: %@", emvData.encryptedTags.description]);
    if (emvData.maskedTags != nil) NSLog(@"Masked tags %@!",[NSString stringWithFormat:@"Masked Tags: %@", emvData.maskedTags.description]);
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
        NSData *data = [IDTUtility DICTotTLV:emvData.unencryptedTags];
        NSString *theData = [IDTUtility dataToHexString:data];
        clearentTransactionTokenRequest.tlv = theData;
        clearentTransactionTokenRequest.encrypted = FALSE;
    } else if (emvData.encryptedTags != nil) {
        NSData *data = [IDTUtility DICTotTLV:emvData.encryptedTags];
         NSString *theData = [IDTUtility dataToHexString:data];
        clearentTransactionTokenRequest.tlv = theData;
        clearentTransactionTokenRequest.encrypted = TRUE;
    } else {
        NSLog(@"No emv tags. Could this happen?");
    }
    return clearentTransactionTokenRequest;
}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest { 
    NSLog(@"%@Send data to clearent...",clearentTransactionTokenRequest.asJson);
    NSString *targetUrl = [NSString stringWithFormat:@"%@/rest/v2/emvjwt", [self.publicDelegate getTransactionTokenUrl]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];
    if (error) {
        NSLog(@"Failed to serialize the clearent transaction token request as json: %@", [error description]);
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
          NSLog(@"Clearent Transaction Response status code: %ld", (long)[httpResponse statusCode]);
          if(200 == [httpResponse statusCode]) {
          //if(data != nil) {
              NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              NSLog(@"Clearent Transaction Token response %@", responseStr);
              NSDictionary *responseDictionary = [self responseAsDictionary:responseStr];
              NSString *responseCode = [responseDictionary objectForKey:@"code"];
              NSLog(@"Clearent Transaction Token code %@", responseCode);
              if([responseCode isEqualToString:@"200"]) {
                  [self.publicDelegate successOnline:responseStr];
              } else {
                  [self.publicDelegate errorOnline:responseStr];
              }
          } else if(error != nil) {
              [self.publicDelegate errorOnline:@"Failed to create a Clearent Transaction Token"];
          }
          //Always run the idtech complete method whether an error is returned or not.
          //TODO I'm not sure what the host response tags represent.
          RETURN_CODE rtComplete = [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
          NSLog(@"%@",@"After emv_completeOnlineEMVTransaction was called");
          NSLog(@"%d@",rtComplete);
      }] resume];
}

- (NSDictionary *)responseAsDictionary:(NSString *)stringJson
{
    NSData *data = [stringJson dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    
    if (error)
    {
        NSLog(@"Error in json: %@", [error description]);
    }
    
    return jsonDictionary;
}

@end
