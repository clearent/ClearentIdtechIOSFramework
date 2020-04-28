//
//  ClearentManualEntryDelegate.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/21/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ClearentTransactionToken.h"

@protocol ClearentManualEntryDelegate <NSObject>

/**
* This will notify you when a Clearent Transaction Token has been successfully created based on the card data read from the ID Tech device. The object returned represents a Clearent Response.
* When you want to perform the payment transaction use the 'jwt' from this response as a header called 'mobilejwt'. See demo for an example (the payment transaction API is not supported in
* this SDK).
*/
-(void) successTransactionToken:(ClearentTransactionToken *) clearentTransactionToken;

/**
 * If an error occurs this method will be called.
 */
- (void) handleManualEntryError:(NSString*)message;

@optional
/**
 * This will notify you when a Clearent Transaction Token has been successfully created based on the manual card entry. The json returned represents a Clearent Response from the rest/v2/mobilejwt/manual endpoint.
 * When you want to perform the payment transaction use the 'jwt' from this response as a header called 'mobilejwt' when calling rest/v2/mobile/transactions. See demo for an example.
 */
-(void) successfulTransactionToken:(NSString*)jsonString __deprecated_msg("use successTransactionToken method with ClearentTransactionToken instead.");


@end
