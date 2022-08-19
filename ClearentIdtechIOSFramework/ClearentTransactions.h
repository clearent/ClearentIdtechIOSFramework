//
//  ClearentTransactions.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/2/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

@class ClearentPaymentRequest;
@class ClearentDelegate;
@class Clearent_VP3300;
@class ClearentResponse;
@class ClearentConnection;
#import "ClearentPayment.h"
#import <IDTech/IDT_VP3300.h>


@protocol ClearentTransactions <NSObject>

- (ClearentDelegate*) clearentDelegate;
- (Clearent_VP3300*) clearentVP3300;
- (RETURN_CODE) emv_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback;
- (ClearentResponse*) startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest clearentConnection:(ClearentConnection*) clearentConnection;
- (RETURN_CODE) emv_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest;
-(RETURN_CODE) ctls_startTransaction:(double)amount type:(int)type timeout:(int)timeout tags:(NSMutableDictionary *)tags;
- (RETURN_CODE) ctls_cancelTransaction;
- (RETURN_CODE) ctls_startTransaction;
- (RETURN_CODE) device_cancelTransaction;
- (RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback;
- (RETURN_CODE) emv_cancelTransaction;
- (RETURN_CODE) device_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest;
- (void) runTransaction;
- (BOOL) retriedTransactionAfterDisconnect;
- (ClearentResponse*) handleStartTransactionResult: (RETURN_CODE) startTransactionReturnCode;

@end

@interface ClearentTransactions : NSObject <ClearentTransactions>

@property (nonatomic) ClearentDelegate *clearentDelegate;
@property (nonatomic) Clearent_VP3300 *clearentVP3300;
@property (nonatomic) BOOL retriedTransactionAfterDisconnect;

- (instancetype) init : (ClearentDelegate*) clearentDelegate clearentVP3300:(Clearent_VP3300*) clearentVP3300;
- (RETURN_CODE) emv_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback;
- (ClearentResponse*) startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest clearentConnection:(ClearentConnection*) clearentConnection;
- (RETURN_CODE) emv_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest;
- (RETURN_CODE) ctls_startTransaction:(double)amount type:(int)type timeout:(int)timeout tags:(NSMutableDictionary *)tags;
- (RETURN_CODE) ctls_cancelTransaction;
- (RETURN_CODE) ctls_startTransaction;
- (RETURN_CODE) device_cancelTransaction;
- (RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback;
- (RETURN_CODE) emv_cancelTransaction;
- (RETURN_CODE) device_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest;
- (void) runTransaction;
- (ClearentResponse*) handleStartTransactionResult: (RETURN_CODE) startTransactionReturnCode;


@end
