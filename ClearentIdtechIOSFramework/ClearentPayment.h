//
//  PaymentRequest.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/17/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import "ClearentPaymentRequest.h"

@interface ClearentPayment: NSObject <ClearentPaymentRequest>
@property (nonatomic) double amount;
@property (nonatomic) double amtOther;
@property (nonatomic) int type;
@property (nonatomic) int timeout;
@property (nonatomic) NSData *tags;
@property (nonatomic) BOOL forceOnline;
@property (nonatomic) BOOL fallback;
@property (nonatomic) NSString* emailAddress;

- (instancetype) initSale;
@end
