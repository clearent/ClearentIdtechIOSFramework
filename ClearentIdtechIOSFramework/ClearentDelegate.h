//
//  ClearentDelegate.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//
// The ClearentDelegate's goal is to wrap the functionality exposed to the public and insert
// itself into the IdTech framework allowing for Clearent to manage the credit card data for the client.
// It also gives us opportunity to do other things on behalf of the client, such as emv configuration.

#import <Foundation/Foundation.h>
#import "ClearentIdtechIOSFramework/PublicDelegate.h"
#import "IDTech/IDT_UniPayIII.h"
#import "ClearentIdtechIOSFramework/ClearentTransactionTokenRequest.h"

typedef enum {FALLBACK_SWIPE=80, NONTECH_FALLBACK_SWIPE=95, CONTACTLESS_EMV=07, CONTACTLESS_MAGNETIC_SWIPE=91} supportedEmvEntryMode;
typedef enum {SWIPE=90} supportedNonEmvEntryMode;
 
@interface ClearentDelegate : NSObject<IDT_UniPayIII_Delegate>
@property(nonatomic) NSString *firmwareVersion;
@property(nonatomic) NSString *deviceSerialNumber;
@property(nonatomic) NSString *kernelVersion;
@property(nonatomic) id<Clearent_Public_IDT_UniPayIII_Delegate> publicDelegate;
- (void) init : (id <Clearent_Public_IDT_UniPayIII_Delegate>) publicDelegate;
- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData;
- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest;
-(void) deviceConnected;
-(void) configuration;
- (ClearentTransactionTokenRequest*) createClearentTransactionToken:(BOOL)emv encrypted:(BOOL)encrypted track2Data:(NSString*) track2Data;
@end

