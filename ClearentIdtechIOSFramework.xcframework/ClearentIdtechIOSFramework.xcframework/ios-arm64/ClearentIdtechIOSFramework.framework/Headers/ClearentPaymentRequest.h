//
//  ClearentPaymentRequest.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 8/13/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

/** When you start a transaction you can pass this object in to describe the payment request.
    amount,amtOther,type,timeout,tags,forceOnline,fallback - are all passthrough values for the IDTech framework. Clearent will use the amount and email address with its system but the rest help IDTech's framework work.
 
 amount - Transaction amount value  (tag value 9F02)
 amtOther - Other amount value, if any  (tag value 9F03)
 type - Transaction type (tag value 9C).
 timeout - Timeout value in seconds.
 tags -  Any other tags to be included in the request.  Passed as NSData.  Example, tag 9F0C with amount 0x000000000100 would be 0x9F0C06000000000100
 If tags 9F02 (amount),9F03 (other amount), or 9C (transaction type) are included, they will take priority over these values supplied as individual parameters to this method.
 Tag DFEE1A can be used to specify tags to be returned in response, in addition to the default tags. Example DFEE1A049F029F03 will return tags 9F02 and 9F03 with the response
 
 forceOnline -  TRUE = do not allow offline approval,  FALSE = allow ICC to approve offline if terminal capable
 autoAuthenticate -  Will automatically execute Authenticate Transacation after start transaction returns successful
 fallback - Indicate if it supports fallback to MSR
 
 email - address used for special processing such as offline decline receipts
 **/

@protocol ClearentPaymentRequest <NSObject>

- (double) amount;

- (double) amtOther;

- (int) type;

- (int) timeout;

- (NSData*) tags;

- (BOOL) forceOnline;

- (BOOL) fallback;

@optional
- (NSString*) emailAddress;

@end

