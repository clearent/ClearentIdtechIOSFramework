#import "Clearent_UniPayIII_Delegate.h"

@implementation Clearent_UniPayIII_Delegate<Clearent_UniPayIII>

- (void) createJwt:(NSString *) tlvData {
    printf("Test tlv data begin ...");
    printf("%s\n", [tlvData UTF8String]);
    printf("Test tlv data end ...");
}

- (Boolean) doPayment:(NSString *) something {
    printf("Call clearent ...");
    return true;
}

-(void) appendMessageToResults:(NSString*) message{
    [self performSelectorOnMainThread:@selector(_appendMessageToResults:) withObject:message waitUntilDone:false];

}

-(void) _appendMessageToResults:(id)object{
    printf("Test begin ...");
    printf("%s\n", [(NSString*)object UTF8String]);
    printf("Test end ...");
    self.result = [NSString stringWithFormat:@"%@\n%@\n", self.result,(NSString*)object];
}

-(void) appendMessageToData:(NSString*) message{
    [self performSelectorOnMainThread:@selector(_appendMessageToData:) withObject:message waitUntilDone:false];
    
}
-(void) _appendMessageToData:(id)object{
    self.result = [NSString stringWithFormat:@"%@\n%@\n", self.result, (NSString*)object];
}

#pragma mark - UniPay Delegate methods
static int _lcdDisplayMode = 0;
- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines{
    NSMutableString* str = [NSMutableString new];
    _lcdDisplayMode = mode;
    if (lines != nil) {
        for (NSString* s in lines) {
            [str appendString:s];
            [str appendString:@"\n"];
        }
    }
    
    switch (mode) {
        case 0x10:
            //clear screen
            self.result = @"";
            break;
        case 0x03:
            self.result = str;
            break;
        case 0x01:
        case 0x02:
        case 0x08:{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Please Select" message:str delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        }
            
            break;
        default:
            break;
    }
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming{
    [self appendMessageToData:[NSString stringWithFormat:@"%@: %@",isIncoming?@"IN":@"OUT",data.description]];
}

// These are optional. TODO wut 2 do ? Pass through Delegate to delegate ?
//- (void) plugStatusChange:(BOOL)deviceInserted{
//    if (deviceInserted) {
//        [self appendMessageToResults: @"device Attached."];
//
//        if ([[AVAudioSession sharedInstance] outputVolume] < 1.0) {
//            [prompt_doConnection_Low_Volume show];
//        } else{
//            [prompt_doConnection show];
//        }
//
//    }
//    else{
//        [self appendMessageToResults: @"device removed."];
//        [self dismissAllAlertViews];
//    }
//}

//-(void)deviceConnected{
//    NSLog(@"Connected --");
//    connectedLabel.text = @"Connected";
//    [self appendMessageToResults:@"(UniPay III Connected)"];
//    [self appendMessageToResults:[NSString stringWithFormat:@"Framework Version: %@",[IDT_Device SDK_version]]];
//}
//
//-(void)deviceDisconnected{
//    NSLog(@"DisConnt --");
//    connectedLabel.text = @"Disconnect";
//    [self appendMessageToResults:@"([UniPay sharedController] Disconnect)"];
//
//}


- (void) swipeMSRData:(IDTMSRData*)cardData{
    NSLog(@"--MSR event Received, Type: %d, data: %@", cardData.event, cardData.encTrack1);
    switch (cardData.event) {
        case EVENT_MSR_CARD_DATA:
        {
            switch (cardData.captureEncodeType) {
                case CAPTURE_ENCODE_TYPE_ISOABA:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"ISO/ABA"]];
                    break;
                case CAPTURE_ENCODE_TYPE_AAMVA:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"AA/MVA"]];
                    break;
                    
                case CAPTURE_ENCODE_TYPE_Other:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"Other"]];
                    break;
                    
                case CAPTURE_ENCODE_TYPE_Raw:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"Raw"]];
                    break;
                    
                case CAPTURE_ENCODE_TYPE_JIS_I:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"CAPTURE_ENCODE_TYPE_JIS_I"]];
                    break;
                    
                case CAPTURE_ENCODE_TYPE_JIS_II:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"CAPTURE_ENCODE_TYPE_JIS_II"]];
                    break;
                    
                default:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encode Type: %@", @"UNKNOWN"]];
                    
                    break;
            }
            switch (cardData.captureEncryptType) {
                case CAPTURE_ENCRYPT_TYPE_AES:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"AES"]];
                    break;
                case CAPTURE_ENCRYPT_TYPE_TDES:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"TDES"]];
                    break;
                case CAPTURE_ENCRYPT_TYPE_NO_ENCRYPTION:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"NONE"]];
                    break;
                    
                    
                default:
                    [self appendMessageToResults:[NSString stringWithFormat:@"Encrypt Type: %@", @"UNKNOWN"]];
                    
                    break;
            }
            
            [self appendMessageToResults:[NSString stringWithFormat:@"Full card data: %@", cardData.cardData]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Track 1: %@", cardData.track1]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Track 2: %@", cardData.track2]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Track 3: %@", cardData.track3]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Length Track 1: %i", cardData.track1Length]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Length Track 2: %i", cardData.track2Length]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Length Track 3: %i", cardData.track3Length]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Encoded Track 1: %@", cardData.encTrack1.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Encoded Track 2: %@", cardData.encTrack2.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Encoded Track 3: %@", cardData.encTrack3.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Hash Track 1: %@", cardData.hashTrack1.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Hash Track 2: %@", cardData.hashTrack2.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"Hash Track 3: %@", cardData.hashTrack3.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"KSN: %@", cardData.KSN.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"\nSessionID: %@",  cardData.sessionID.description]];
            [self appendMessageToResults:[NSString stringWithFormat:@"\nReader Serial Number: %@",  cardData.RSN]];
            [self appendMessageToResults:[NSString stringWithFormat:@"\nRead Status: %2X",  cardData.readStatus]];
            if (cardData.unencryptedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Unencrytped Tags: %@", cardData.unencryptedTags.description]];
            if (cardData.encryptedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Encrypted Tags: %@", cardData.encryptedTags.description]];
            if (cardData.maskedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Masked Tags: %@", cardData.maskedTags.description]];
            
            NSLog(@"Track 1: %@", cardData.track1);
            NSLog(@"Track 2: %@", cardData.track2);
            NSLog(@"Track 3: %@", cardData.track3);
            NSLog(@"Encoded Track 1: %@", cardData.encTrack1.description);
            NSLog(@"Encoded Track 2: %@", cardData.encTrack2.description);
            NSLog(@"Encoded Track 3: %@", cardData.encTrack3.description);
            NSLog(@"Hash Track 1: %@", cardData.hashTrack1.description);
            NSLog(@"Hash Track 2: %@", cardData.hashTrack2.description);
            NSLog(@"Hash Track 3: %@", cardData.hashTrack3.description);
            NSLog(@"SessionID: %@", cardData.sessionID.description);
            NSLog(@"nReader Serial Number: %@", cardData.RSN);
            NSLog(@"Read Status: %2X", cardData.readStatus);
            NSLog(@"KSN: %@", cardData.KSN.description);
            
            return;
        }
            break;
            
        case EVENT_MSR_CANCEL_KEY:
        {
            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR Cancel Key received: %@", cardData.encTrack1]];
            return;
        }
            break;
            
        case EVENT_MSR_BACKSPACE_KEY:
        {
            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR Backspace Key received: %@", cardData.encTrack1]];
            return;
        }
            break;
            
        case EVENT_MSR_ENTER_KEY:
        {
            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR Enter Key received: %@", cardData.encTrack1]];
            return;
        }
            break;
            
        case EVENT_MSR_UNKNOWN:
        {
            [self appendMessageToResults:[NSString stringWithFormat:@"(Event) MSR unknown event, data: %@", cardData.encTrack1]];
            return;
        }
            break;
        case EVENT_MSR_TIMEOUT:
        {
            [self appendMessageToResults:@"(Event) MSR TIMEOUT"];
            return;
        }
        default:
            break;
    }
}

- (void) deviceMessage:(NSString*)message{
    [self appendMessageToResults:message];
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    
    //TODO Why is this invoked twice ? Do we care at this point ?
    NSString *categoryString=[[emvData valueForKeyPath:@"57"][0] objectForKey:@"unencryptedTags"];
    [self createJwt:categoryString];
    RETURN_CODE clearentPaymentSuccessCode = [self doPayment:emvData.unencryptedTags.description];
    if(clearentPaymentSuccessCode) {
        [self appendMessageToResults:@"Clearent Payment Successful"];
    } else {
        [self appendMessageToResults:@"Clearent Payment Failed"];
    }
    
    //Dave TODO loopdata and autocomplete had to do with UI stuff. How do we handle this ?
    //bool loopData = stressTest.on;
    
    [self appendMessageToResults:[NSString stringWithFormat:@"EMV Transaction Data Response: = %@",[[IDT_UniPayIII sharedController] device_getResponseCodeString:error]]];
    
    if (emvData.resultCodeV2 != EMV_RESULT_CODE_V2_NO_RESPONSE) [self appendMessageToResults:[NSString stringWithFormat:@"EMV_RESULT_CODE_V2_response = %2X",emvData.resultCodeV2]];
    if (emvData == nil) {
        return;
    }
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE) {
        [self appendMessageToResults:@"ONLINE REQUEST"];
        //Dave TODO
        //loopData = false;
        //if (autoComplete.on) [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(completeEMV:) userInfo:nil repeats:false];
    }
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        //Dave TODO
        //loopData = false;
        [self appendMessageToResults:@"START SUCCESS: AUTHENTICATION REQUIRED"];
    }
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
        
        [self appendMessageToResults:@"APPROVED"];
    }
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
        [self appendMessageToResults:@"MSR Data Captured"];
    }
    
    if (emvData.cardType == 0) {
        [self appendMessageToResults:@"CONTACT"];
    }
    if (emvData.cardType == 1) {
        [self appendMessageToResults:@"CONTACTLESS"];
    }
    if (emvData.unencryptedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Unencrytped Tags: %@", emvData.unencryptedTags.description]];
    if (emvData.encryptedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Encrypted Tags: %@", emvData.encryptedTags.description]];
    if (emvData.maskedTags != nil) [self appendMessageToResults:[NSString stringWithFormat:@"Masked Tags: %@", emvData.maskedTags.description]];
    if (emvData.unencryptedTags != nil)NSLog(@"Unencrytped Tags: %@", emvData.unencryptedTags.description);
    if (emvData.encryptedTags != nil) NSLog(@"Encrypted Tags: %@", emvData.encryptedTags.description);
    if (emvData.maskedTags != nil) NSLog(@"Masked Tags: %@", emvData.maskedTags.description);
    if (emvData.hasAdvise) [self appendMessageToResults:@"Response Has Advise Request"];
    if (emvData.hasReversal) [self appendMessageToResults:@"Response Has Reversal Request"];
    if (emvData.hasAdvise) NSLog(@"Response Has Advise Request");
    if (emvData.hasReversal) NSLog(@"Response Has Reversal Request");
    if (emvData.cardData != nil) [self swipeMSRData:emvData.cardData];
    
    //Dave TODO
    //[self dismissAllAlertViews];
    //if (loopData)[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startEMV:) userInfo:nil repeats:false];
    
}



@end
