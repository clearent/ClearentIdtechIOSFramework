//
//  Clearent_UniPayIII.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/4/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Clearent_UniPayIII.h"
#import "ClearentDelegate.h"

@implementation Clearent_UniPayIII

static ClearentDelegate *clearentDelegate;

- (void) init : (id <Clearent_Public_IDT_UniPayIII_Delegate>) publicDelegate {
    NSLog(@"Set the delegate in the ID Tech solution to our ClearentDelegate, which will call the Public delegate when needed.");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clearentDelegate = [[ClearentDelegate alloc] init];
        [clearentDelegate init:publicDelegate];
        [IDT_UniPayIII sharedController].delegate = clearentDelegate;
        NSLog(@"Clearent_UniPayIII initialized");
    });
}

- (NSString*) SDK_version {
    return [IDT_Device SDK_version];
}

-(void) close {
    [[IDT_UniPayIII sharedController] close];
}

-(void) device_connectToUSB {
    [[IDT_UniPayIII sharedController] device_connectToUSB];
}

-(RETURN_CODE) ctls_cancelTransaction {
    return [[IDT_UniPayIII sharedController] ctls_cancelTransaction];
}

-(RETURN_CODE) ctls_startTransaction {
    return [[IDT_UniPayIII sharedController] ctls_startTransaction];
}

-(RETURN_CODE) device_cancelConnectToAudioReader {
    return [[IDT_UniPayIII sharedController] device_cancelConnectToAudioReader];
}

-(RETURN_CODE) device_connectToAudioReader {
    return [[IDT_UniPayIII sharedController]  device_connectToAudioReader];
}

-(RETURN_CODE) device_getFirmwareVersion:(NSString**)response {
    return [[IDT_UniPayIII sharedController] device_getFirmwareVersion:response];
}

-(bool) device_enableBLEDeviceSearch:(IDT_DEVICE_Types)type identifier:(NSUUID*)identifier {
    return [[IDT_UniPayIII sharedController] device_enableBLEDeviceSearch:type identifier:identifier];
}

-(bool) device_disableBLEDeviceSearch {
    return [[IDT_UniPayIII sharedController] device_disableBLEDeviceSearch];
}

-(NSUUID*) device_connectedBLEDevice {
    return [[IDT_UniPayIII sharedController] device_connectedBLEDevice];
}

-(BOOL) device_isAudioReaderConnected {
    return [[IDT_UniPayIII sharedController] device_isAudioReaderConnected];
}

-(NSString *) device_getResponseCodeString: (int) errorCode {
    return [[IDT_UniPayIII sharedController] device_getResponseCodeString:errorCode];
}

-(bool) device_isConnected:(IDT_DEVICE_Types)device {
    return [[IDT_UniPayIII sharedController] device_isConnected:device];
}

-(RETURN_CODE) device_sendIDGCommand:(unsigned char)command subCommand:(unsigned char)subCommand data:(NSData*)data response:(NSData**)response {
    return [[IDT_UniPayIII sharedController] device_sendIDGCommand:command subCommand:subCommand data:data response:response];
}

-(RETURN_CODE) device_setAudioVolume:(float)val {
    return [[IDT_UniPayIII sharedController] device_setAudioVolume:val];
}

-(RETURN_CODE) device_setPassThrough:(BOOL)enablePassThrough {
    return [[IDT_UniPayIII sharedController] device_setPassThrough:enablePassThrough];
}

-(RETURN_CODE) device_startRKI {
    return [[IDT_UniPayIII sharedController] device_startRKI];
}

-(RETURN_CODE) emv_authenticateTransaction:(NSData*)tags {
    return [[IDT_UniPayIII sharedController] emv_authenticateTransaction:tags];
}

-(RETURN_CODE) emv_callbackResponseLCD:(int)mode selection:(unsigned char) selection {
    return [[IDT_UniPayIII sharedController] emv_callbackResponseLCD:mode selection:selection];
}

-(RETURN_CODE) emv_completeOnlineEMVTransaction:(BOOL)isSuccess hostResponseTags:(NSData*)tags {
    return [[IDT_UniPayIII sharedController] emv_completeOnlineEMVTransaction:isSuccess hostResponseTags:tags];
}

-(void) emv_disableAutoAuthenticateTransaction:(BOOL)disable {
    [[IDT_UniPayIII sharedController] emv_disableAutoAuthenticateTransaction:disable];
}

-(RETURN_CODE) emv_getEMVL2Version:(NSString**)response {
    return [[IDT_UniPayIII sharedController] emv_getEMVL2Version:response];
}

-(RETURN_CODE) emv_removeApplicationData:(NSString*)AID {
    return [[IDT_UniPayIII sharedController] emv_removeApplicationData:AID];
}

-(RETURN_CODE) emv_removeCAPK:(NSString*)rid index:(NSString*)index {
    return [[IDT_UniPayIII sharedController] emv_removeCAPK:rid index:index];
}

-(RETURN_CODE) emv_removeCRLList {
    return [[IDT_UniPayIII sharedController] emv_removeCRLList];
}

-(RETURN_CODE) emv_removeTerminalData {
    return [[IDT_UniPayIII sharedController] emv_removeTerminalData];
}

-(RETURN_CODE) emv_retrieveAIDList:(NSArray**)response {
    return [[IDT_UniPayIII sharedController] emv_retrieveAIDList:response];
}

-(RETURN_CODE) emv_retrieveApplicationData:(NSString*)AID response:(NSDictionary**)responseAID {
    return [[IDT_UniPayIII sharedController] emv_retrieveApplicationData:AID response:responseAID];
}

-(RETURN_CODE) emv_retrieveCAPK:(NSString*)rid index:(NSString*)index response:(CAKey**)response {
    return [[IDT_UniPayIII sharedController] emv_retrieveCAPK:rid index:index response:response];
}

-(RETURN_CODE) emv_retrieveCAPKFile:(NSString*)rid index:(NSString*)index response:(NSData**)response {
    return [[IDT_UniPayIII sharedController] emv_retrieveCAPKFile:rid index:index response:response];
}

-(RETURN_CODE) emv_retrieveCAPKList:(NSArray**)response {
    return [[IDT_UniPayIII sharedController] emv_retrieveCAPKList:response];
}

-(RETURN_CODE) emv_retrieveCRLList:(NSMutableArray**)response {
    return [[IDT_UniPayIII sharedController] emv_retrieveCRLList:response];
}

-(RETURN_CODE) emv_retrieveTerminalData:(NSDictionary**)responseData {
    return [[IDT_UniPayIII sharedController] emv_retrieveTerminalData:responseData];
}

-(RETURN_CODE) emv_retrieveTransactionResult:(NSData*)tags retrievedTags:(NSDictionary**)retrievedTags {
    return [[IDT_UniPayIII sharedController] emv_retrieveTransactionResult:tags retrievedTags:retrievedTags];
}

-(RETURN_CODE) emv_setApplicationData:(NSString*)aidName configData:(NSDictionary*)data {
    return [[IDT_UniPayIII sharedController] emv_setApplicationData:aidName configData:data];
}

-(RETURN_CODE) emv_setCAPK:(CAKey)key {
    return [[IDT_UniPayIII sharedController] emv_setCAPK:key];
}

-(RETURN_CODE) emv_setCAPKFile:(NSData*)file {
    return [[IDT_UniPayIII sharedController] emv_setCAPKFile:file];
}

-(RETURN_CODE) emv_setCRLEntries:(NSData*)data {
    return [[IDT_UniPayIII sharedController] emv_setCRLEntries:data];
}

-(RETURN_CODE) emv_setTerminalData:(NSDictionary*)data {
    return [[IDT_UniPayIII sharedController] emv_setTerminalData:data];
}

-(RETURN_CODE) emv_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback {
    return [[IDT_UniPayIII sharedController] emv_startTransaction:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline fallback:fallback];
}

-(RETURN_CODE) config_getSerialNumber:(NSString**)response {
    return [[IDT_UniPayIII sharedController] config_getSerialNumber:response];
}

-(RETURN_CODE) icc_exchangeAPDU:(NSData*)dataAPDU response:(APDUResponse**)response {
    return [[IDT_UniPayIII sharedController] icc_exchangeAPDU:dataAPDU response:response];
}

-(RETURN_CODE) icc_getICCReaderStatus:(ICCReaderStatus**)readerStatus {
    return [[IDT_UniPayIII sharedController] icc_getICCReaderStatus:readerStatus];
}

-(RETURN_CODE) icc_powerOnICC:(NSData**)response {
    return [[IDT_UniPayIII sharedController] icc_powerOnICC:response];
}

-(RETURN_CODE) icc_powerOffICC:(NSString**)error {
    return [[IDT_UniPayIII sharedController] icc_powerOffICC:error];
}

-(RETURN_CODE) msr_cancelMSRSwipe {
    return [[IDT_UniPayIII sharedController] msr_cancelMSRSwipe];
}

-(RETURN_CODE) msr_startMSRSwipe {
    return [[IDT_UniPayIII sharedController] msr_startMSRSwipe];
}

-(bool) isConnected {
    return [[IDT_UniPayIII sharedController] isConnected];
}

@end
