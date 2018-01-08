//
//  PrivateDelegate.m
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "PrivateDelegate.h"
#import "IDTech/IDTUtility.h"

//TODO is this really private ? can I just use it from the sdk demo ? look into class extensions ?

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
     NSLog(@"Call Public delegate dataInOutMonitor");
    [self.publicDelegate dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming];
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
    
//    switch (cardData.event) {
//        case EVENT_MSR_CARD_DATA:
//        {
//            switch (cardData.captureEncodeType) {
//                case CAPTURE_ENCODE_TYPE_ISOABA:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"ISO/ABA"]];
//                    break;
//                case CAPTURE_ENCODE_TYPE_AAMVA:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"AA/MVA"]];
//                    break;
//
//                case CAPTURE_ENCODE_TYPE_Other:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"Other"]];
//                    break;
//
//                case CAPTURE_ENCODE_TYPE_Raw:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"Raw"]];
//                    break;
//
//                case CAPTURE_ENCODE_TYPE_JIS_I:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"CAPTURE_ENCODE_TYPE_JIS_I"]];
//                    break;
//
//                case CAPTURE_ENCODE_TYPE_JIS_II:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"CAPTURE_ENCODE_TYPE_JIS_II"]];
//                    break;
//
//                default:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"UNKNOWN"]];
//
//                    break;
//            }
//            switch (cardData.captureEncryptType) {
//                case CAPTURE_ENCRYPT_TYPE_AES:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"AES"]];
//                    break;
//                case CAPTURE_ENCRYPT_TYPE_TDES:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"TDES"]];
//                    break;
//                case CAPTURE_ENCRYPT_TYPE_NO_ENCRYPTION:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"NONE"]];
//                    break;
//
//
//                default:
//                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"UNKNOWN"]];
//
//                    break;
//            }
//
//            [self appendMessageToResults:[NSString stringWithFormat:@"Full card data: %@", cardData.cardData]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Track 1: %@", cardData.track1]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Track 2: %@", cardData.track2]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Track 3: %@", cardData.track3]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Length Track 1: %i", cardData.track1Length]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Length Track 2: %i", cardData.track2Length]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Length Track 3: %i", cardData.track3Length]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Encoded Track 1: %@", cardData.encTrack1.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Encoded Track 2: %@", cardData.encTrack2.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Encoded Track 3: %@", cardData.encTrack3.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Hash Track 1: %@", cardData.hashTrack1.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Hash Track 2: %@", cardData.hashTrack2.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"Hash Track 3: %@", cardData.hashTrack3.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"KSN: %@", cardData.KSN.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"\nSessionID: %@",  cardData.sessionID.description]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"\nReader Serial Number: %@",  cardData.RSN]];
//            [self appendMessageToResults:[NSString stringWithFormat:@"\nRead Status: %2X",  cardData.readStatus]];
//            if (cardData.unencryptedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Unencrytped Tags: %@", cardData.unencryptedTags.description]];
//            if (cardData.encryptedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Encrypted Tags: %@", cardData.encryptedTags.description]];
//            if (cardData.maskedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Masked Tags: %@", cardData.maskedTags.description]];
//
//            NSLog(@"Track 1: %@", cardData.track1);
//            NSLog(@"Track 2: %@", cardData.track2);
//            NSLog(@"Track 3: %@", cardData.track3);
//            NSLog(@"Encoded Track 1: %@", cardData.encTrack1.description);
//            NSLog(@"Encoded Track 2: %@", cardData.encTrack2.description);
//            NSLog(@"Encoded Track 3: %@", cardData.encTrack3.description);
//            NSLog(@"Hash Track 1: %@", cardData.hashTrack1.description);
//            NSLog(@"Hash Track 2: %@", cardData.hashTrack2.description);
//            NSLog(@"Hash Track 3: %@", cardData.hashTrack3.description);
//            NSLog(@"SessionID: %@", cardData.sessionID.description);
//            NSLog(@"nReader Serial Number: %@", cardData.RSN);
//            NSLog(@"Read Status: %2X", cardData.readStatus);
//            NSLog(@"KSN: %@", cardData.KSN.description);
//
//
//
//            return;
//        }
//            break;
//
//        case EVENT_MSR_CANCEL_KEY:
//        {
//            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR Cancel Key received: %@", cardData.encTrack1]];
//            return;
//        }
//            break;
//
//        case EVENT_MSR_BACKSPACE_KEY:
//        {
//            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR Backspace Key received: %@", cardData.encTrack1]];
//            return;
//        }
//            break;
//
//        case EVENT_MSR_ENTER_KEY:
//        {
//            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR Enter Key received: %@", cardData.encTrack1]];
//            return;
//        }
//            break;
//
//        case EVENT_MSR_UNKNOWN:
//        {
//            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR unknown event, data: %@", cardData.encTrack1]];
//            return;
//        }
//            break;
//        case EVENT_MSR_TIMEOUT:
//        {
//            [self appendMessageToResults:@"(Event) MSR TIMEOUT"];
//            return;
//        }
//        default:
//            break;
//    }
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    NSLog(@"emvTransactionData called in private delegate" );

    if (emvData.resultCodeV2 != EMV_RESULT_CODE_V2_NO_RESPONSE) NSLog(@"mvData.resultCodeV2 %@!",[NSString stringWithFormat:@"EMV_RESULT_CODE_V2_response = %2X",emvData.resultCodeV2]);
    if (emvData == nil) {
        NSLog(@"no emv data yet");
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
    
    //TODO figure out when we need to perform emv_completeOnlineEMVTransaction.
    
    //TODO Should we just send all emv tags to our service ?
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        ClearentTransactionToken *clearentTransactionToken = [self createTransactionToken:clearentTransactionTokenRequest];
        //TODO handle errors but always run the idtech complete method
        RETURN_CODE rtComplete = [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
        //TODO what do we do if the complete method returns an error ?
        [self.publicDelegate successfulClearentTransactionToken:clearentTransactionToken];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (emvData.unencryptedTags != nil) {
        NSData* tlv = [IDTUtility DICTotTLV:emvData.unencryptedTags];
        NSString* tlvString = [IDTUtility dataToString:tlv];
        clearentTransactionTokenRequest.tlv = tlvString;
    } else if (emvData.encryptedTags != nil) {
        NSData* tlv = [IDTUtility DICTotTLV:emvData.encryptedTags];
        NSString* tlvString = [IDTUtility dataToString:tlv];
        clearentTransactionTokenRequest.tlv = tlvString;
    } else {
        NSLog(@"No emv tags");
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
