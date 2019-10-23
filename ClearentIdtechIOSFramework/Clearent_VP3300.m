//
//  Clearent_VP3300.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/4/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.

#import <Foundation/Foundation.h>
#import "Clearent_VP3300.h"
#import "ClearentDelegate.h"
#import "Teleport.h"
#import "PaymentRequest.h"

@implementation Clearent_VP3300 

  static NSString *const READER_IS_NOT_CONFIGURED = @"Cannot run transaction. Reader is not configured.";
  static NSString *const DEVICE_NOT_CONNECTED = @"Device is not connected";
  static NSString *const BLUETOOTH_FRIENDLY_NAME_REQUIRED = @"Bluetooth friendly name required";

  ClearentDelegate *clearentDelegate;

- (instancetype) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey {
    self = [super init];
    if (self) {
        clearentDelegate = [[ClearentDelegate alloc] init:publicDelegate clearentBaseUrl:clearentBaseUrl publicKey:publicKey];
        [IDT_VP3300 sharedController].delegate = clearentDelegate;
        //Using Variant of Teleport-NSLog -> https://github.com/kennethjiang/Teleport-NSLog
        //Disabled intercept of logging in favor of adding our own logs to a rotating file solution.
        //When reaping occurs, we send the logs to Clearent.
        TELEPORT_DEBUG = YES;
        [Teleport startWithForwarder:
        [SimpleHttpForwarder forwarderWithAggregatorUrl:clearentBaseUrl publicKey:publicKey]];
    }
    return self;
}

- (instancetype) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration {
    self = [super init];
    if (self) {
        clearentDelegate = [[ClearentDelegate alloc] initWithConfig:publicDelegate clearentVP3300Configuration:clearentVP3300Configuration];
        [IDT_VP3300 sharedController].delegate = clearentDelegate;
        if(!clearentVP3300Configuration.disableRemoteLogging) {
        //Using Variant of Teleport-NSLog -> https://github.com/kennethjiang/Teleport-NSLog
        //Disabled intercept of logging in favor of adding our own logs to a rotating file solution.
        //When reaping occurs, we send the logs to Clearent.
            TELEPORT_DEBUG = YES;
            [Teleport startWithForwarder:
            [SimpleHttpForwarder forwarderWithAggregatorUrl:clearentVP3300Configuration.clearentBaseUrl publicKey:clearentVP3300Configuration.publicKey]];
        }
    }
    return self;
}

- (NSString*) SDK_version {
    return [IDT_Device SDK_version];
}

-(void) close {
    [self clearCurrentRequest];
    [[IDT_VP3300 sharedController] close];
}

-(void) device_connectToUSB {
    [[IDT_VP3300 sharedController] device_connectToUSB];
}

-(RETURN_CODE) ctls_cancelTransaction {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] ctls_cancelTransaction];
}

-(RETURN_CODE) ctls_startTransaction {
    [self clearCurrentRequest];
    RETURN_CODE ctlsStartRt;
    if(![clearentDelegate isDeviceConfigured]) {
        [clearentDelegate deviceMessage:READER_IS_NOT_CONFIGURED];
        ctlsStartRt = RETURN_CODE_EMV_FAILED;
    } else {
         [Teleport logInfo:@"ctls_startTransaction"];
        ctlsStartRt =   [[IDT_VP3300 sharedController] ctls_startTransaction];
    }
    return ctlsStartRt;
}

-(RETURN_CODE) device_cancelConnectToAudioReader {
    return [[IDT_VP3300 sharedController] device_cancelConnectToAudioReader];
}

-(RETURN_CODE) device_connectToAudioReader {
    return [[IDT_VP3300 sharedController]  device_connectToAudioReader];
}

-(RETURN_CODE) device_getFirmwareVersion:(NSString**)response {
    return [[IDT_VP3300 sharedController] device_getFirmwareVersion:response];
}

-(bool) device_disableBLEDeviceSearch {
    return [[IDT_VP3300 sharedController] device_disableBLEDeviceSearch];
}

-(NSUUID*) device_connectedBLEDevice {
    return [[IDT_VP3300 sharedController] device_connectedBLEDevice];
}

-(BOOL) device_isAudioReaderConnected {
    return [[IDT_VP3300 sharedController] device_isAudioReaderConnected];
}

-(NSString *) device_getResponseCodeString: (int) errorCode {
    return [[IDT_VP3300 sharedController] device_getResponseCodeString:errorCode];
}

-(bool) device_isConnected:(IDT_DEVICE_Types)device {
    return [[IDT_VP3300 sharedController] device_isConnected:device];
}

-(RETURN_CODE) device_sendIDGCommand:(unsigned char)command subCommand:(unsigned char)subCommand data:(NSData*)data response:(NSData**)response {
    return [[IDT_VP3300 sharedController] device_sendIDGCommand:command subCommand:subCommand data:data response:response];
}

-(RETURN_CODE) device_setAudioVolume:(float)val {
    return [[IDT_VP3300 sharedController] device_setAudioVolume:val];
}

-(RETURN_CODE) device_setPassThrough:(BOOL)enablePassThrough {
    return [[IDT_VP3300 sharedController] device_setPassThrough:enablePassThrough];
}

-(RETURN_CODE) device_startRKI {
    return [[IDT_VP3300 sharedController] device_startRKI];
}

-(RETURN_CODE) emv_authenticateTransaction:(NSData*)tags {
    return [[IDT_VP3300 sharedController] emv_authenticateTransaction:tags];
}

-(RETURN_CODE) emv_callbackResponseLCD:(int)mode selection:(unsigned char) selection {
    return [[IDT_VP3300 sharedController] emv_callbackResponseLCD:mode selection:selection];
}

-(RETURN_CODE) emv_completeOnlineEMVTransaction:(BOOL)isSuccess hostResponseTags:(NSData*)tags {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:isSuccess hostResponseTags:tags];
}

-(void) emv_disableAutoAuthenticateTransaction:(BOOL)disable {
    [[IDT_VP3300 sharedController] emv_disableAutoAuthenticateTransaction:disable];
}

-(RETURN_CODE) emv_getEMVL2Version:(NSString**)response {
    return [[IDT_VP3300 sharedController] emv_getEMVL2Version:response];
}

-(RETURN_CODE) emv_removeApplicationData:(NSString*)AID {
    return [[IDT_VP3300 sharedController] emv_removeApplicationData:AID];
}

-(RETURN_CODE) emv_removeCAPK:(NSString*)rid index:(NSString*)index {
    return [[IDT_VP3300 sharedController] emv_removeCAPK:rid index:index];
}

-(RETURN_CODE) emv_removeCRLList {
    return [[IDT_VP3300 sharedController] emv_removeCRLList];
}

-(RETURN_CODE) emv_removeTerminalData {
    return [[IDT_VP3300 sharedController] emv_removeTerminalData];
}

-(RETURN_CODE) emv_retrieveAIDList:(NSArray**)response {
    return [[IDT_VP3300 sharedController] emv_retrieveAIDList:response];
}

-(RETURN_CODE) emv_retrieveApplicationData:(NSString*)AID response:(NSDictionary**)responseAID {
    return [[IDT_VP3300 sharedController] emv_retrieveApplicationData:AID response:responseAID];
}

-(RETURN_CODE) emv_retrieveCAPK:(NSString*)rid index:(NSString*)index response:(CAKey**)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCAPK:rid index:index response:response];
}

-(RETURN_CODE) emv_retrieveCAPKFile:(NSString*)rid index:(NSString*)index response:(NSData**)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCAPKFile:rid index:index response:response];
}

-(RETURN_CODE) emv_retrieveCAPKList:(NSArray**)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCAPKList:response];
}

-(RETURN_CODE) emv_retrieveCRLList:(NSMutableArray**)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCRLList:response];
}

-(RETURN_CODE) emv_retrieveTerminalData:(NSDictionary**)responseData {
    return [[IDT_VP3300 sharedController] emv_retrieveTerminalData:responseData];
}

-(RETURN_CODE) emv_retrieveTransactionResult:(NSData*)tags retrievedTags:(NSDictionary**)retrievedTags {
    return [[IDT_VP3300 sharedController] emv_retrieveTransactionResult:tags retrievedTags:retrievedTags];
}

-(RETURN_CODE) emv_setApplicationData:(NSString*)aidName configData:(NSDictionary*)data {
    return [[IDT_VP3300 sharedController] emv_setApplicationData:aidName configData:data];
}

-(RETURN_CODE) emv_setCAPK:(CAKey)key {
    return [[IDT_VP3300 sharedController] emv_setCAPK:key];
}

-(RETURN_CODE) emv_setCAPKFile:(NSData*)file {
    return [[IDT_VP3300 sharedController] emv_setCAPKFile:file];
}

-(RETURN_CODE) emv_setCRLEntries:(NSData*)data {
    return [[IDT_VP3300 sharedController] emv_setCRLEntries:data];
}

-(RETURN_CODE) emv_setTerminalData:(NSDictionary*)data {
    return [[IDT_VP3300 sharedController] emv_setTerminalData:data];
}

-(RETURN_CODE) emv_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback {
    [self clearCurrentRequest];
    RETURN_CODE emvStartRt;
    if(![clearentDelegate isDeviceConfigured]) {
        [clearentDelegate deviceMessage:READER_IS_NOT_CONFIGURED];
        emvStartRt = RETURN_CODE_EMV_FAILED;
    } else {
        
        //it was determined that for our solution this method needed to be called. This is the idtech's default but just in case
        //the developer decides to set it to true we need to set it back to false, otherwise our solution does not work.
        [[IDT_VP3300 sharedController] emv_disableAutoAuthenticateTransaction:FALSE];
        
        [Teleport logInfo:@"emv_startTransaction"];
        emvStartRt =  [[IDT_VP3300 sharedController] emv_startTransaction:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline fallback:fallback];
    }
    if(RETURN_CODE_OK_NEXT_COMMAND == emvStartRt) {
        [clearentDelegate deviceMessage:@"Transaction next"];
    }
    return emvStartRt;
}

-(RETURN_CODE) config_getSerialNumber:(NSString**)response {
    return [[IDT_VP3300 sharedController] config_getSerialNumber:response];
}

-(RETURN_CODE) icc_exchangeAPDU:(NSData*)dataAPDU response:(APDUResponse**)response {
    return [[IDT_VP3300 sharedController] icc_exchangeAPDU:dataAPDU response:response];
}

-(RETURN_CODE) icc_getICCReaderStatus:(ICCReaderStatus**)readerStatus {
    return [[IDT_VP3300 sharedController] icc_getICCReaderStatus:readerStatus];
}

-(RETURN_CODE) icc_powerOnICC:(NSData**)response {
    return [[IDT_VP3300 sharedController] icc_powerOnICC:response];
}

-(RETURN_CODE) icc_powerOffICC:(NSString**)error {
    return [[IDT_VP3300 sharedController] icc_powerOffICC:error];
}

-(RETURN_CODE) msr_cancelMSRSwipe {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] msr_cancelMSRSwipe];
}

-(RETURN_CODE) msr_startMSRSwipe {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] msr_startMSRSwipe];
}

-(bool) isConnected {
    return [[IDT_VP3300 sharedController] isConnected];
}

-(void) assignBypassDelegate:(id<IDT_VP3300_Delegate>)del {
     return [[IDT_VP3300 sharedController] assignBypassDelegate:del];
}

-(RETURN_CODE) ctls_getConfigurationGroup:(int)group response:(NSDictionary**)response {
    return [[IDT_VP3300 sharedController] ctls_getConfigurationGroup:group response:response];
}

-(RETURN_CODE) ctls_removeAllCAPK {
    return [[IDT_VP3300 sharedController] ctls_removeAllCAPK];
}

-(RETURN_CODE) ctls_removeApplicationData:(NSString*)AID {
    return [[IDT_VP3300 sharedController] ctls_removeApplicationData:AID];
}

-(RETURN_CODE)  ctls_removeCAPK:(NSData*)capk {
    return [[IDT_VP3300 sharedController] ctls_removeCAPK:capk ];
}

-(RETURN_CODE)  ctls_removeConfigurationGroup:(int)group {
    return [[IDT_VP3300 sharedController] ctls_removeConfigurationGroup:group ];
}

-(RETURN_CODE) ctls_retrieveAIDList:(NSArray**)response {
    return [[IDT_VP3300 sharedController] ctls_retrieveAIDList:response];
}

-(RETURN_CODE)  ctls_retrieveApplicationData:(NSString*)AID response:(NSDictionary**)response {
    return [[IDT_VP3300 sharedController] ctls_retrieveApplicationData:AID response:response];
}

-(RETURN_CODE)  ctls_retrieveCAPK:(NSData*)capk key:(NSData**)key {
    return [[IDT_VP3300 sharedController] ctls_retrieveCAPK:capk key:key];
}

-(RETURN_CODE)  ctls_retrieveCAPKList:(NSArray**)keys {
    return [[IDT_VP3300 sharedController] ctls_retrieveCAPKList:keys];
}

-(RETURN_CODE)  ctls_retrieveTerminalData:(NSData**)tlv {
    return [[IDT_VP3300 sharedController] ctls_retrieveTerminalData:tlv];
}

-(RETURN_CODE)  ctls_setApplicationData:(NSData*)tlv{
     return [[IDT_VP3300 sharedController] ctls_setApplicationData:tlv];
}

-(RETURN_CODE)  ctls_setCAPK:(NSData*)key {
    return [[IDT_VP3300 sharedController] ctls_setCAPK:key];
}

-(RETURN_CODE) ctls_setConfigurationGroup:(NSData*)tlv {
   return [[IDT_VP3300 sharedController] ctls_setConfigurationGroup:tlv];
}

-(RETURN_CODE) ctls_setTerminalData:(NSData*)tlv {
    return [[IDT_VP3300 sharedController] ctls_setTerminalData:tlv];
}

-(RETURN_CODE) ctls_startTransaction:(double)amount type:(int)type timeout:(int)timeout tags:(NSMutableDictionary *)tags {
    [self clearCurrentRequest];
    RETURN_CODE ctlsStartRt;
    if(![clearentDelegate isDeviceConfigured]) {
        [clearentDelegate deviceMessage:READER_IS_NOT_CONFIGURED];
        ctlsStartRt = RETURN_CODE_EMV_FAILED;
    } else {
         [Teleport logInfo:@"ctls_startTransaction with vars"];
        ctlsStartRt =  [[IDT_VP3300 sharedController] ctls_startTransaction:amount type:type timeout:timeout tags:tags];
    }
    return ctlsStartRt;
}

-(RETURN_CODE) device_cancelTransaction {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] device_cancelTransaction];
}

-(void) device_disconnectBLE {
    return [[IDT_VP3300 sharedController] device_disconnectBLE];
}

-(bool) device_enableBLEDeviceSearch:(NSUUID*)identifier {
    [self setServiceScanFilterWithService1820];
    return [[IDT_VP3300 sharedController] device_enableBLEDeviceSearch:identifier];
}

-(RETURN_CODE)  device_getAutoPollTransactionResults:(IDTEMVData**)result {
    return [[IDT_VP3300 sharedController] device_getAutoPollTransactionResults:result];
}

-(NSString*) device_getBLEFriendlyName {
    return [[IDT_VP3300 sharedController] device_getBLEFriendlyName];
}

-(void) device_setBLEFriendlyName:(NSString*)friendlyName {
    return [[IDT_VP3300 sharedController] device_setBLEFriendlyName:friendlyName];
}

-(RETURN_CODE)  device_setBurstMode:(int) mode {
    return [[IDT_VP3300 sharedController] device_setBurstMode:mode];
}

-(RETURN_CODE) device_setPollMode:(int) mode {
     return [[IDT_VP3300 sharedController] device_setPollMode:mode];
}

-(RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback {
    [self clearCurrentRequest];
    
    PaymentRequest *paymentRequest = [self createPaymentRequest:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline  fallback:fallback ];
    [clearentDelegate setClearentPaymentRequest:paymentRequest];
    return [self device_startTransaction:paymentRequest];
}

- (PaymentRequest*) createPaymentRequest:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback {
    PaymentRequest *paymentRequest = [[PaymentRequest alloc] init];
    [paymentRequest setAmount:amount];
    paymentRequest.amtOther = amtOther;
    paymentRequest.type = type;
    paymentRequest.timeout = timeout;
    paymentRequest.tags = tags;
    paymentRequest.emailAddress = nil;
    paymentRequest.fallback = fallback;
    paymentRequest.forceOnline = forceOnline;
    return paymentRequest;
}


-(RETURN_CODE) emv_callbackResponsePIN:(EMV_PIN_MODE_Types)mode KSN:(NSData*)KSN PIN:(NSData*)PIN {
    return [[IDT_VP3300 sharedController] emv_callbackResponsePIN:(EMV_PIN_MODE_Types)mode KSN:KSN PIN:PIN];
}

-(RETURN_CODE) emv_cancelTransaction {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] emv_cancelTransaction];
}

-(RETURN_CODE) emv_getTerminalMajorConfiguration:(NSUInteger**)configuration {
    return [[IDT_VP3300 sharedController] emv_getTerminalMajorConfiguration:configuration];
}

-(RETURN_CODE) emv_setTerminalMajorConfiguration:(int)configuration {
    return [[IDT_VP3300 sharedController] emv_setTerminalMajorConfiguration:configuration];
}

-(void) processBypassResponse:(NSData*)data {
    return [[IDT_VP3300 sharedController] processBypassResponse:data];
}

- (void) clearConfigurationCache {
    [clearentDelegate clearConfigurationCache];
}

- (void) setAutoConfiguration:(BOOL)enable {
    [clearentDelegate setAutoConfiguration:enable];
}

- (void) setContactless:(BOOL)enable {
    [clearentDelegate setContactless:enable];
}

- (void) setContactlessAutoConfiguration:(BOOL)enable {
     [clearentDelegate setContactlessAutoConfiguration:enable];
}

-(RETURN_CODE) device_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest {
    
    RETURN_CODE deviceStartRt;
//    if(![[IDT_VP3300 sharedController] isConnected]) {
//        [clearentDelegate deviceMessage:DEVICE_NOT_CONNECTED];
//        deviceStartRt = RETURN_CODE_ERR_DISCONNECT;
    //} else if(![clearentDelegate isDeviceConfigured]) {
    if(![clearentDelegate isDeviceConfigured]) {
        [clearentDelegate deviceMessage:READER_IS_NOT_CONFIGURED];
        deviceStartRt = RETURN_CODE_EMV_FAILED;
        RETURN_CODE cancelTransactionRt = [[IDT_VP3300 sharedController] device_cancelTransaction];
        if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
            [clearentDelegate deviceMessage:@"Transaction cancelled"];
        }
    } else {
        //it was determined that for our solution this method needed to be called. This is the idtech's default but just in case
        //the developer decides to set it to true we need to set it back to false, otherwise our solution does not work.
        
        //RETURN_CODE_SDK_BUSY_MSR_
         [NSThread sleepForTimeInterval:0.5f];
        
        [[IDT_VP3300 sharedController] emv_disableAutoAuthenticateTransaction:FALSE];
        
        [Teleport logInfo:@"device_startTransaction with clearent payment obj"];
        [clearentDelegate setClearentPaymentRequest:clearentPaymentRequest];
        [self resetInvalidDeviceData];
        
      //  [self workaroundCardSeatedIssue: clearentPaymentRequest];
        
        deviceStartRt = [[IDT_VP3300 sharedController] device_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];

        if(RETURN_CODE_DO_SUCCESS != deviceStartRt || RETURN_CODE_OK_NEXT_COMMAND != deviceStartRt) {
            if([[IDT_VP3300 sharedController] isConnected]) {
                [clearentDelegate deviceMessage:@"Transaction failed to start. Retrying..."];
                [NSThread sleepForTimeInterval:0.5f];
                RETURN_CODE cancelTransactionRt = [[IDT_VP3300 sharedController] device_cancelTransaction];
            
                deviceStartRt = [[IDT_VP3300 sharedController] device_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];
                
                if (RETURN_CODE_DO_SUCCESS != deviceStartRt) {
                    [clearentDelegate deviceMessage:@"Retry failed. Cancel Transaction and try again"];
                }
            } else {
                [clearentDelegate deviceMessage:DEVICE_NOT_CONNECTED];
            }
        }
        
    }
    return deviceStartRt;
}

//It appears the idtech firmware has a flag that indicates a card is seated in the reader. This breaks idtech's device_startTransaction which is meant to support
//contactless, dip, and swipe. If we don't attempt to get the cardSeated changed to false the contactless feature is disabled.
//If Idtech fixes the issue then the worst overhead this method will have is asking the reader for the icc reader status.

//todo if the card is inserted this logic might contribute to an issue with audio jack readers

- (void) workaroundCardSeatedIssue:(id<ClearentPaymentRequest>) clearentPaymentRequest {
    
       if(![[IDT_VP3300 sharedController] isConnected]) {
            [Teleport logInfo:@"workaroundCardSeatedIssue:Reader is disconnected"];
           return;
       }
    
       ICCReaderStatus* response;
       RETURN_CODE icc_getICCReaderStatusRt = [[IDT_VP3300 sharedController] icc_getICCReaderStatus:&response];
    
       if(RETURN_CODE_DO_SUCCESS != icc_getICCReaderStatusRt) {
           [Teleport logInfo:@"workaroundCardSeatedIssue:Failed to retrieve the icc reader status"];
           if(response == nil) {
               [Teleport logInfo:@"workaroundCardSeatedIssue:No icc reader status response"];
               return;
           }
       }
          
       if(response->cardPresent) {
          [Teleport logInfo:@"workaroundCardSeatedIssue:Skip the workaround for the contactless card seated issue. icc reader status is cardPresent"];
           return;
       }
    
       if(response->cardSeated) {
           [Teleport logInfo:@"workaroundCardSeatedIssue:Card is Seated. Start the device transaction and then cancel it"];
           RETURN_CODE device_startTransactionRt = [[IDT_VP3300 sharedController] device_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];
           if(RETURN_CODE_OK_NEXT_COMMAND == device_startTransactionRt) {
               [clearentDelegate deviceMessage:@"Transaction next"];
           }
           if (RETURN_CODE_DO_SUCCESS == device_startTransactionRt) {
               [NSThread sleepForTimeInterval:0.2f];
               [Teleport logInfo:@"workaroundCardSeatedIssue:Cancel the transaction"];
               RETURN_CODE cancelTransactionRt = [[IDT_VP3300 sharedController] device_cancelTransaction];
               if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
                   [Teleport logInfo:@"workaroundCardSeatedIssue:transaction cancelled"];
                   ICCReaderStatus* icc_getICCReaderStatusResponse;
                   RETURN_CODE icc_getICCReaderStatusRt2 = [[IDT_VP3300 sharedController] icc_getICCReaderStatus:&icc_getICCReaderStatusResponse];
                   if(icc_getICCReaderStatusResponse != nil) {
                       if(icc_getICCReaderStatusResponse->cardSeated) {
                           [Teleport logInfo:@"workaroundCardSeatedIssue:Card is still seated"];
                       } else {
                          [Teleport logInfo:@"workaroundCardSeatedIssue:Card not seated"];
                       }
                    }
               } else {
                   [Teleport logInfo:@"workaroundCardSeatedIssue:Cancel transaction failed"];
               }
           } else {
               [Teleport logInfo:@"workaroundCardSeatedIssue:Start transaction failed"];
           }
       } else {
           [Teleport logInfo:@"workaroundCardSeatedIssue: Card is unseated. No need for workaround"];
       }
}

- (void) clearCurrentRequest{
    [clearentDelegate setClearentPaymentRequest:nil];
}

//Sometimes our initial call to the reader requesting information fails. We still need to allow the system to continue on since this data is not considered critical to
//the run of the transaction.
- (void) resetInvalidDeviceData {
   [clearentDelegate resetInvalidDeviceData];
}

- (void) clearContactlessConfigurationCache {
    [clearentDelegate clearContactlessConfigurationCache];
}

-(void) setServiceScanFilter:(NSArray<CBUUID *> *) filter {
    return [[IDT_Device sharedController] setServiceScanFilter:filter];
}

- (void) setServiceScanFilterWithService1820 {
    NSArray<CBUUID *> *filter = [[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:@"1820"], nil];
    [self setServiceScanFilter:filter];
}

-(void) startBluetoothScan:(NSString*) friendlyName {
    [clearentDelegate resetBluetoothSearch];
    if (friendlyName == nil || friendlyName.length == 0) {
        [clearentDelegate deviceMessage:BLUETOOTH_FRIENDLY_NAME_REQUIRED];
    } else {
        [clearentDelegate setDefaultBluetoothFriendlyName:friendlyName];
        [self device_setBLEFriendlyName:friendlyName];
        NSUUID* val = nil;
        bool device_enableBLEDeviceSearchReturnCode = [self device_enableBLEDeviceSearch:val];
        if(device_enableBLEDeviceSearchReturnCode) {
            [clearentDelegate deviceMessage:@"Bluetooth scan started. Press button"];
        } else {
            [clearentDelegate deviceMessage:@"Bluetooth scan primer failed"];
            [Teleport logInfo:@"Bluetooth scan primer failed"];
        }
    }
}

@end


