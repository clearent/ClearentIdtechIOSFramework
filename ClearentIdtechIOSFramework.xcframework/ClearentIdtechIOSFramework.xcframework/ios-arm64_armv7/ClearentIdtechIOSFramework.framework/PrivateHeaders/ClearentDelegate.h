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
#import "ClearentConnection.h"
#import "ClearentFeedback.h"
#import "ClearentBluetoothDevice.h"
#import "ClearentDeviceConnector.h"

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

@property(nonatomic) id<ClearentPaymentRequest> clearentPayment;
@property(nonatomic) id<ClearentVP3300Configuration> clearentVP3300Configuration;
@property(nonatomic) ClearentConnection *clearentConnection;
@property(nonatomic) BOOL runStoredPaymentAfterConnecting;

@property (assign, getter=isConfigured) BOOL configured;

@property(nonatomic) SEL runTransactionSelector;
@property(nonatomic) id callbackObject;
@property (nonatomic,strong) ClearentDeviceConnector *clearentDeviceConnector;
@property (nonatomic,strong) IDT_VP3300 *idTechSharedInstance;

- (id) init: (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey idTechSharedInstance: (IDT_VP3300*) idTechSharedInstance ;

- (id) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration idTechSharedInstance: (IDT_VP3300*) idTechSharedInstance ;


- (id) initWithPaymentCallback : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration callbackObject:(id)callbackObject withSelector:(SEL)runTransactionSelector idTechSharedInstance: (IDT_VP3300*) idTechSharedInstance ;

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData;

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest;

-(void) deviceConnected;

- (void) deviceMessage:(NSString*)message;

- (void) feedback:(ClearentFeedback*)clearentFeedback;

- (void) startFallbackSwipe;

/**
 The reader has an emv configuration applied each time connects. After a successful configuration the device serial number and a flag denoting the reader was configured is stored using NSUserDefaults. If there is a need to clear out this information, maybe to support a configuration change/future updates, call this method to clear out the cache.
 */
- (void) clearConfigurationCache;

- (NSString *) getDeviceSerialNumber;

- (NSString *) getFirmwareVersion;

/**
 The reader has a contactless configuration applied each time connects. After a successful configuration the device serial number and a flag denoting the reader was configured for contactless is stored using NSUserDefaults. If there is a need to clear out this information, maybe to support a configuration change/future updates, call this method to clear out the cache.
 */
- (void) clearContactlessConfigurationCache;

- (BOOL) isDeviceConfigured;

- (void) applyClearentConfiguration;

- (void) clearCurrentRequest;

- (void) sendBluetoothDevices;

- (void) sendFeedback:(NSString*) message;

/**
Contactless Event
During a Contactless transaction, if events are enabled, they will be sent to this protocol,

@param event Event Type:
- 01 = LED Event
- 02 = Buzzer Event
- 03 = LCD Message
@param scheme LCD Message Scheme
@param data Data
   - When Event Type 01:
   -- 0x00 = LED0 off
   -- 0x10 = LED1 off
   -- 0x20 = LED2 off
   -- 0x30 = LED3 off
   -- 0xF0 = ALL off
   -- 0x01 = LED0 on
   -- 0x11 = LED1 on
   -- 0x21 = LED2 on
   -- 0x31 = LED3 on
   -- 0xF1 = ALL on
   - When Event Type 02:
   -- 0x10 = Short Beep No Change
   -- 0x11 = Short Beep No Change
   -- 0x12 = Double Short Beep
   -- 0x13 = Triple Short Beep
   -- 0x20 = 200ms Beep
   -- 0x21 = 400ms Beep
   -- 0x22 = 600ms Beep
   - When Event Type 03:
   -- Message ID (please refer to table in NEO Reference Guide)
*/
- (void) ctlsEvent:(Byte)event scheme:(Byte)scheme  data:(Byte)data;

- (void) startFinalFeedbackMonitor:(int) timeout;

- (void) disableCardRemovalTimer;

- (void) updatePublicKey:(NSString *)publicKey;

- (void) resetTransaction;

- (void) setEnhancedMessaging;

@end


