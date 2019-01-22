//
//  ClearentManualEntryDelegate.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/21/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol ClearentManualEntryDelegate <NSObject>

/**
 * This will notify you when a Clearent Transaction Token has been successfully created based on the manual card entry. The json returned represents a Clearent Response from the rest/v2/mobilejwt/manual endpoint.
 * When you want to perform the payment transaction use the 'jwt' from this response as a header called 'mobilejwt' when calling rest/v2/mobile/transactions. See demo for an example.
 */
-(void) successfulTransactionToken:(NSString*)jsonString;

/**
 * If an error occurs this method will be called.
 */
- (void) handleManualEntryError:(NSString*)message;

@end
