//
//  PaymentRequest.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/17/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import "ClearentPayment.h"

@implementation ClearentPayment

static int const DEFAULT_TRANSACTION_TIMEOUT = 30;

- (instancetype) initSale {
    
    self = [super init];
    
    if (self) {
        
        self.amount = 0;
        self.amtOther = 0;
        self.type = 0;
        self.timeout = DEFAULT_TRANSACTION_TIMEOUT;
        self.tags = nil;
        self.emailAddress = nil;
        self.fallback = true;
        self.forceOnline = false;
    }
    
    return self;
}

@end

