//
//  ClearentManualEntry.h
//
//  Handle manually entered cards.
//
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/21/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ClearentManualEntryDelegate.h"
#import "ClearentCard.h"

@interface ClearentManualEntry : NSObject

@property(nonatomic) id<ClearentManualEntryDelegate> clearentManualEntryDelegate;
@property(nonatomic) NSString *clearentBaseUrl;
@property(nonatomic) NSString *publicKey;

/**
 * Initialize this object with your delegate, Clearent's base url (prod or sandbox), and the publicKey.
 */
- (id) init: (id <ClearentManualEntryDelegate>)clearentManualEntryDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey ;

/**
 * This method does a POST request to obtain a transaction token.
 * @param clearentCard an object containing the card data inserted by the user
 */
- (void) createTransactionToken:(ClearentCard*)clearentCard;

/**
 * This method does a POST request to obtain a transaction token.
 * This is similar to createTransactionToken method, the only difference is that in case of createTransactionToken, when the response is received, delegate methods are called instead of the completion block
 *
 * @param clearentCard an object containing the card data inserted by the user
 * @param completion when a response is received from the backend, this completion is called
 */
- (void) createOfflineTransactionToken:(ClearentCard*)clearentCard completion:(void (^_Nullable)(ClearentTransactionToken* _Nullable))completion;

/**
 * Any errors will be returned here
 */
- (void) handleManualEntryError:(NSString*)message;

@end
