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
    
    if (emvData.unencryptedTags != nil) NSLog(@"Unencrypted tags %@!", [NSString stringWithFormat:@"Unencrypted Tags: %@", emvData.unencryptedTags.description]);
    if (emvData.encryptedTags != nil) NSLog(@"Encrypted tags %@!",[NSString stringWithFormat:@"Encrypted Tags: %@", emvData.encryptedTags.description]);
    if (emvData.maskedTags != nil) NSLog(@"Masked tags %@!",[NSString stringWithFormat:@"Masked Tags: %@", emvData.maskedTags.description]);
    //TODO what's this do ? fallback swipe ?
    if (emvData.cardData != nil) [self swipeMSRData:emvData.cardData];
    
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        ClearentTransactionToken *clearentTransactionToken = [self createTransactionToken:clearentTransactionTokenRequest];
        //TODO handle errors but always run the idtech complete method. Should this be performed outside of this block ?
        RETURN_CODE rtComplete = [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
        NSLog(@"%@",@"After emv_completeOnlineEMVTransaction was called");
        NSLog(@"%d@",rtComplete);

        [self.publicDelegate successClearentTransactionToken:clearentTransactionToken];
        //TODO handle error, return response/error object.
        //[self.publicDelegate errorClearentTransactionToken];
    }
}

//TODO Used TD Tech utility to create the tlv stream, not sure if it's in the format we can consume.
- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (emvData.unencryptedTags != nil) {
        NSData* tlv = [IDTUtility DICTotTLV:emvData.unencryptedTags];
        NSString* tlvString = [IDTUtility dataToString:tlv];
        clearentTransactionTokenRequest.tlv = tlvString;
        clearentTransactionTokenRequest.isEncrypted = FALSE;
    } else if (emvData.encryptedTags != nil) {
        NSData* tlv = [IDTUtility DICTotTLV:emvData.encryptedTags];
        NSString* tlvString = [IDTUtility dataToString:tlv];
        clearentTransactionTokenRequest.tlv = tlvString;
        clearentTransactionTokenRequest.isEncrypted = TRUE;
    } else {
        NSLog(@"No emv tags. Could this happen?");
    }
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionToken*) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    NSLog(@"%@",clearentTransactionTokenRequest.asJson);
    ClearentTransactionToken *clearentTransactionToken = [[ClearentTransactionToken alloc] init];
    clearentTransactionToken.jwt = @"This is a really useful JWT";
    return clearentTransactionToken;
}

@end
