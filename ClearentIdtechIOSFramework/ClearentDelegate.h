//
//  ClearentDelegate.h
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IDTech/IDT_VP3300.h>
#import "ClearentPublicVP3300Delegate.h"
#import "ClearentTransactionTokenRequest.h"
#import "ClearentPaymentRequest.h"
#import "ClearentVP3300Configuration.h"

//EMV_DIP("EMV_DIP", "05"),
typedef enum {FALLBACK_SWIPE=80, NONTECH_FALLBACK_SWIPE=95, CONTACTLESS_EMV=07, CONTACTLESS_MAGNETIC_SWIPE=91} supportedEmvEntryMode;
typedef enum {SWIPE=90} supportedNonEmvEntryMode;


@interface ClearentDelegate : NSObject<IDT_VP3300_Delegate>

    @property(nonatomic) NSString *firmwareVersion;
    @property(nonatomic) NSString *deviceSerialNumber;
    @property(nonatomic) NSString *kernelVersion;
    @property(nonatomic) NSString *baseUrl;
    @property(nonatomic) NSString *publicKey;
    @property(nonatomic) BOOL autoConfiguration;
    @property(nonatomic) BOOL contactless;
    @property(nonatomic) BOOL contactlessAutoConfiguration;
    @property(nonatomic) id<Clearent_Public_IDTech_VP3300_Delegate> publicDelegate;
    @property(nonatomic) int originalEntryMode;

    @property(nonatomic) NSString *defaultBluetoothFriendlyName;
    @property(nonatomic) NSString *bluetoothDeviceID;
    @property(nonatomic) BOOL bluetoothSearchInProgress;

    @property(nonatomic) id<ClearentPaymentRequest> clearentPayment;
    @property(nonatomic) id<ClearentVP3300Configuration> clearentVP3300Configuration;

    @property (assign, getter=isConfigured) BOOL configured;

    - (id) init: (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey ;
    - (id) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration;

    - (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData;
    - (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest;
    -(void) deviceConnected;
    - (void) deviceMessage:(NSString*)message;
    - (void) startFallbackSwipe;

/**
 The reader has an emv configuration applied each time connects. After a successful configuration the device serial number and a flag denoting the reader was configured is stored using NSUserDefaults. If there is a need to clear out this information, maybe to support a configuration change/future updates, call this method to clear out the cache.
 */
- (void) clearConfigurationCache;

- (NSString *) getDeviceSerialNumber;

- (NSString *) getFirmwareVersion;

- (void) resetInvalidDeviceData;

/**
 The reader has a contactless configuration applied each time connects. After a successful configuration the device serial number and a flag denoting the reader was configured for contactless is stored using NSUserDefaults. If there is a need to clear out this information, maybe to support a configuration change/future updates, call this method to clear out the cache.
 */
- (void) clearContactlessConfigurationCache;

- (BOOL) isDeviceConfigured;

- (void) resetBluetoothSearch;

@end


