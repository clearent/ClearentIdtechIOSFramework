//
//  Clearent_VP3300.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/4/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.

#import "Clearent_VP3300.h"
#import "ClearentDelegate.h"
#import "ClearentLumberjack.h"
#import "ClearentPayment.h"
#import <IDTech/IDTUtility.h>
#import "ClearentCache.h"
#import "ClearentDeviceConnector.h"
#import "ClearentTransactions.h"
#import "ClearentLumberjack.h"

@implementation Clearent_VP3300 

  static NSString *const READER_CONFIGURED_FLAG_LETTER_P_IN_HEX = @"50";
  static NSString *const MERCHANT_NAME_AND_LOCATION_HIJACKED_AS_PRECONFIGURED_FLAG  = @"9F4E";

  ClearentDelegate *clearentDelegate;
  ClearentDeviceConnector *clearentDeviceConnector;
  ClearentTransactions *clearentTransactions;

- (instancetype) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey {
    self = [super init];
    if (self) {
        clearentDelegate = [[ClearentDelegate alloc] init:publicDelegate clearentBaseUrl:clearentBaseUrl publicKey:publicKey idTechSharedInstance: [IDT_VP3300 sharedController]];
        clearentTransactions = [[ClearentTransactions alloc] init:clearentDelegate clearentVP3300:self];
        [IDT_VP3300 sharedController].delegate = clearentDelegate;
 
        [ClearentLumberjack initLumberJack:clearentBaseUrl publicKey:publicKey];
        
    }
    return self;
}

- (instancetype) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration {
    self = [super init];
    if (self) {
        clearentDelegate = [[ClearentDelegate alloc] initWithConfig:publicDelegate clearentVP3300Configuration:clearentVP3300Configuration  idTechSharedInstance: [IDT_VP3300 sharedController]];
        clearentTransactions = [[ClearentTransactions alloc] init:clearentDelegate clearentVP3300:self];
        [IDT_VP3300 sharedController].delegate = clearentDelegate;
        if(!clearentVP3300Configuration.disableRemoteLogging) {
            
            [ClearentLumberjack initLumberJack:clearentVP3300Configuration.clearentBaseUrl publicKey:clearentVP3300Configuration.publicKey];
            
        }
    }
    return self;
}

- (instancetype) initWithConnectionHandling : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration  {
    self = [super init];
    if (self) {
        SEL runTransactionSelector = NSSelectorFromString(@"runTransaction");
        if ([self respondsToSelector:runTransactionSelector]) {
            clearentDelegate.runTransactionSelector = runTransactionSelector;
        }
        clearentDelegate = [[ClearentDelegate alloc] initWithPaymentCallback:publicDelegate clearentVP3300Configuration:clearentVP3300Configuration callbackObject:self withSelector:runTransactionSelector idTechSharedInstance: [IDT_VP3300 sharedController]];

        [IDT_VP3300 sharedController].delegate = clearentDelegate;
        
        clearentDeviceConnector = [[ClearentDeviceConnector alloc] init:clearentDelegate clearentVP3300:self ];
        [clearentDelegate setClearentDeviceConnector:clearentDeviceConnector];
        clearentTransactions = [[ClearentTransactions alloc] init:clearentDelegate clearentVP3300:self];

        
        if(!clearentVP3300Configuration.disableRemoteLogging) {

            [ClearentLumberjack initLumberJack:clearentVP3300Configuration.clearentBaseUrl publicKey:clearentVP3300Configuration.publicKey];
            
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

//-(void) device_connectToUSB {
//    [[IDT_VP3300 sharedController] device_connectToUSB];
//}

-(RETURN_CODE) ctls_cancelTransaction {
    [self clearCurrentRequest];
    return [[IDT_VP3300 sharedController] ctls_cancelTransaction];
}

-(RETURN_CODE) ctls_startTransaction {
    return [clearentTransactions ctls_startTransaction];
}

-(RETURN_CODE) device_cancelConnectToAudioReader {
    return [[IDT_VP3300 sharedController] device_cancelConnectToAudioReader];
}

-(RETURN_CODE) device_connectToAudioReader {
    return [[IDT_VP3300 sharedController]  device_connectToAudioReader];
}

-(RETURN_CODE) device_getFirmwareVersion:(NSString* __autoreleasing *)response {
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

-(RETURN_CODE) device_sendIDGCommand:(unsigned char)command subCommand:(unsigned char)subCommand data:(NSData*)data response:(NSData* __autoreleasing *)response {
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

-(RETURN_CODE) emv_getEMVL2Version:(NSString* __autoreleasing *)response {
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

-(RETURN_CODE) emv_retrieveAIDList:(NSArray* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] emv_retrieveAIDList:response];
}

-(RETURN_CODE) emv_retrieveApplicationData:(NSString*)AID response:(NSDictionary* __autoreleasing *)responseAID {
    return [[IDT_VP3300 sharedController] emv_retrieveApplicationData:AID response:responseAID];
}

-(RETURN_CODE) emv_retrieveCAPK:(NSString*)rid index:(NSString*)index response:(CAKey**)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCAPK:rid index:index response:response];
}

-(RETURN_CODE) emv_retrieveCAPKFile:(NSString*)rid index:(NSString*)index response:(NSData* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCAPKFile:rid index:index response:response];
}

-(RETURN_CODE) emv_retrieveCAPKList:(NSArray* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCAPKList:response];
}

-(RETURN_CODE) emv_retrieveCRLList:(NSMutableArray* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] emv_retrieveCRLList:response];
}

-(RETURN_CODE) emv_retrieveTerminalData:(NSDictionary* __autoreleasing *)responseData {
    return [[IDT_VP3300 sharedController] emv_retrieveTerminalData:responseData];
}

-(RETURN_CODE) emv_retrieveTransactionResult:(NSData*)tags retrievedTags:(NSDictionary* __autoreleasing *)retrievedTags {
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
    return [clearentTransactions emv_startTransaction:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline fallback:fallback];
}

-(RETURN_CODE) emv_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest {
    return [clearentTransactions emv_startTransaction:clearentPaymentRequest];
}

-(RETURN_CODE) config_getSerialNumber:(NSString* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] config_getSerialNumber:response];
}

-(RETURN_CODE) icc_exchangeAPDU:(NSData*)dataAPDU response:(APDUResponse* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] icc_exchangeAPDU:dataAPDU response:response];
}

-(RETURN_CODE) icc_getICCReaderStatus:(ICCReaderStatus**)readerStatus {
    return [[IDT_VP3300 sharedController] icc_getICCReaderStatus:readerStatus];
}

-(RETURN_CODE) icc_powerOnICC:(NSData* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] icc_powerOnICC:response];
}

-(RETURN_CODE) icc_powerOffICC:(NSString* __autoreleasing *)error {
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

-(RETURN_CODE) ctls_getConfigurationGroup:(int)group response:(NSDictionary* __autoreleasing *)response {
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

-(RETURN_CODE) ctls_retrieveAIDList:(NSArray* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] ctls_retrieveAIDList:response];
}

-(RETURN_CODE)  ctls_retrieveApplicationData:(NSString*)AID response:(NSDictionary* __autoreleasing *)response {
    return [[IDT_VP3300 sharedController] ctls_retrieveApplicationData:AID response:response];
}

-(RETURN_CODE)  ctls_retrieveCAPK:(NSData*)capk key:(NSData* __autoreleasing *)key {
    return [[IDT_VP3300 sharedController] ctls_retrieveCAPK:capk key:key];
}

-(RETURN_CODE)  ctls_retrieveCAPKList:(NSArray* __autoreleasing *)keys {
    return [[IDT_VP3300 sharedController] ctls_retrieveCAPKList:keys];
}

-(RETURN_CODE)  ctls_retrieveTerminalData:(NSData* __autoreleasing *)tlv {
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
    return [clearentTransactions ctls_startTransaction:amount type:type timeout:timeout tags:tags];
}

-(RETURN_CODE) device_cancelTransaction {
    return [clearentTransactions device_cancelTransaction];
}

-(void) device_disconnectBLE {
    return [[IDT_VP3300 sharedController] device_disconnectBLE];
}

-(bool) device_enableBLEDeviceSearch:(NSUUID*)identifier {
    [self setSupportedServiceScanFilters];
    return [[IDT_VP3300 sharedController] device_enableBLEDeviceSearch:identifier];
}

-(RETURN_CODE)  device_getAutoPollTransactionResults:(IDTEMVData* __autoreleasing *)result {
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
    return [clearentTransactions device_startTransaction:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline fallback:fallback];
}

-(RETURN_CODE) emv_callbackResponsePIN:(EMV_PIN_MODE_Types)mode KSN:(NSData*)KSN PIN:(NSData*)PIN {
    return [[IDT_VP3300 sharedController] emv_callbackResponsePIN:(EMV_PIN_MODE_Types)mode KSN:KSN PIN:PIN];
}

-(RETURN_CODE) emv_cancelTransaction {
    return [clearentTransactions emv_cancelTransaction];
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

- (ClearentResponse*) startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest clearentConnection:(ClearentConnection*) clearentConnection {
    return [clearentTransactions startTransaction:clearentPaymentRequest clearentConnection:clearentConnection];
}

-(void) runTransaction {
    [clearentTransactions runTransaction];
}
         
-(RETURN_CODE) device_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest {
    return [clearentTransactions device_startTransaction:clearentPaymentRequest];
}

- (void) clearCurrentRequest{
    [clearentDelegate clearCurrentRequest];
}

- (void) clearContactlessConfigurationCache {
    [clearentDelegate clearContactlessConfigurationCache];
}

-(void) setServiceScanFilter:(NSArray<CBUUID *> *) filter {
    return [[IDT_Device sharedController] setServiceScanFilter:filter];
}

- (void) setServiceScanFilters {
    CBUUID *serviceFilterVP3300 = [CBUUID UUIDWithString:@"1820"];
    NSArray<CBUUID *> *filter = [[NSArray alloc] initWithObjects:serviceFilterVP3300, nil];
    [self setServiceScanFilter:filter];
}

- (void) setSupportedServiceScanFilters {
    CBUUID *serviceFilterVP3300 = [CBUUID UUIDWithString:@"1820"];
    CBUUID *serviceFilterVP3350 = [CBUUID UUIDWithString:@"0783b03e-8535-b5a0-7140-a304d2495cb7"];
    NSArray<CBUUID *> *filter = [[NSArray alloc] initWithObjects:serviceFilterVP3300,serviceFilterVP3350, nil];
    [self setServiceScanFilter:filter];
}

-(void) applyClearentConfiguration {
    clearentDelegate.configured = NO;
    if (clearentDelegate.autoConfiguration) {
        [clearentDelegate clearConfigurationCache];
    }
    if (clearentDelegate.contactlessAutoConfiguration) {
        [clearentDelegate clearContactlessConfigurationCache];
    }
    [ClearentLumberjack logInfo:@"applyClearentConfiguration:Manual configuration requested"];
    if (clearentDelegate.autoConfiguration || clearentDelegate.contactlessAutoConfiguration) {
        clearentDelegate.configured = false;
         [ClearentLumberjack logInfo:@"applyClearentConfiguration:configuration has been enabled. clear cache and reset configuration flag"];
    }
    
    if(![clearentDelegate isDeviceConfigured]) {
         [ClearentLumberjack logInfo:@"applyClearentConfiguration:called"];
        [clearentDelegate applyClearentConfiguration];
    } else {
        [ClearentLumberjack logInfo:@"applyClearentConfiguration:did not apply configuration because the reader is still considered configured. setting configuration flag to true"];
        [clearentDelegate deviceMessage:CLEARENT_READER_CONFIGURED_MESSAGE];
        [clearentDelegate setConfigured:true];
    }
}
/**
 RETURN_CODE_NO_DATA_AVAILABLE_ when not found
 */
-(RETURN_CODE) isContactlessConfigured {
    RETURN_CODE returnCode = RETURN_CODE_DO_SUCCESS;
    if(![[IDT_VP3300 sharedController] isConnected]) {
        [ClearentLumberjack logInfo:@"isContactlessConfigured. Reader disconnected"];
        returnCode = RETURN_CODE_ERR_DISCONNECT;
    } else {
        NSDictionary *result;
        returnCode = [[IDT_VP3300 sharedController]  ctls_getConfigurationGroup:1 response:&result];
        if (RETURN_CODE_DO_SUCCESS == returnCode) {
            if(result == nil || result.count == 0) {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"isContactlessConfigured Group 1 not found:\n%@", result.description]];
                returnCode = RETURN_CODE_NO_DATA_AVAILABLE_;
            } 
        } else {
             returnCode = RETURN_CODE_NO_DATA_AVAILABLE_;
             [ClearentLumberjack logInfo:[NSString stringWithFormat:@"isContactlessConfigured Group 1 error Response: = %@",[[IDT_VP3300 sharedController] device_getResponseCodeString:returnCode]]];
        }
    }
   
    return returnCode;
}

/**
 RETURN_CODE_NO_DATA_AVAILABLE_ when not found
 */
-(RETURN_CODE) isReaderPreconfigured {
    RETURN_CODE returnCode = RETURN_CODE_DO_SUCCESS;
    if(![[IDT_VP3300 sharedController] isConnected]) {
        [ClearentLumberjack logInfo:@"isReaderPreconfigured. Reader disconnected"];
        returnCode = RETURN_CODE_ERR_DISCONNECT;
    } else {
        NSDictionary *terminalData;
        returnCode = [[IDT_VP3300 sharedController]  emv_retrieveTerminalData:&terminalData];
        if (RETURN_CODE_DO_SUCCESS == returnCode) {
            NSString *merchantNameAndLocationHijackedAsConfiguredFlag = [IDTUtility dataToHexString:[terminalData objectForKey:MERCHANT_NAME_AND_LOCATION_HIJACKED_AS_PRECONFIGURED_FLAG]];
            if(merchantNameAndLocationHijackedAsConfiguredFlag != nil && [merchantNameAndLocationHijackedAsConfiguredFlag isEqualToString:READER_CONFIGURED_FLAG_LETTER_P_IN_HEX]) {
                [ClearentLumberjack logInfo:@"🤩 🤩 🤩 🤩 🤩 IDTECH READER IS PRECONFIGURED 🤩 🤩 🤩 🤩 🤩"];
            } else {
                if(merchantNameAndLocationHijackedAsConfiguredFlag != nil) {
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"isReaderPreconfigured 9f4e value is: %@", merchantNameAndLocationHijackedAsConfiguredFlag]];
                } else {
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"isReaderPreconfigured No 9F4E tag found"]];
                }
                returnCode = RETURN_CODE_NO_DATA_AVAILABLE_;
            }
        } else {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"isReaderPreconfigured Failed to get 9F4E tag : = %@",[[IDT_VP3300 sharedController] device_getResponseCodeString:returnCode]]];
            returnCode = RETURN_CODE_NO_DATA_AVAILABLE_;
        }
    }
   
    return returnCode;
}


- (void) addRemoteLogRequest:(NSString*) clientSoftwareVersion message:(NSString*) message {
    if(clientSoftwareVersion != nil && message != nil) {
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"🐨CLIENT:%@:%@",clientSoftwareVersion, message]];
    }
}

- (void) sendRemoteLogs {
    [ClearentLumberjack flush];
}


-(void) startConnection:(ClearentConnection*) clearentConnection {
    [clearentDeviceConnector startConnection:clearentConnection];
}

//- (void) adjustBluetoothAdvertisingInterval {
//    [self performSelector:@selector(adjustit) withObject:nil afterDelay:5.0];
//}

//- (void) adjustit {
//    [clearentDeviceConnector adjustBluetoothAdvertisingInterval];
//}

- (void) clearBluetoothDeviceCache {
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
}

-(void) setPublicKey:(NSString*)publicKey {
    [clearentDelegate updatePublicKey:publicKey];
    [ClearentLumberjack updatePublicKey:publicKey];
}

@end


