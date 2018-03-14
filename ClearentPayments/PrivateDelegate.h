//
//  PrivateDelegate.h
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PublicDelegate.h"
#import "IDTech/IDT_UniPayIII.h"
#import "ClearentTransactionToken.h"
#import "ClearentTransactionTokenRequest.h"

@interface PrivateDelegate : NSObject<IDT_UniPayIII_Delegate>
@property(nonatomic) id<Clearent_Public_IDT_UniPayIII_Delegate> publicDelegate;
- (void) init : (id <Clearent_Public_IDT_UniPayIII_Delegate>) publicDelegate;
- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(IDTEMVData*)emvData;
- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest;
- (NSDictionary *)responseAsDictionary:(NSString *)stringJson;
@end

