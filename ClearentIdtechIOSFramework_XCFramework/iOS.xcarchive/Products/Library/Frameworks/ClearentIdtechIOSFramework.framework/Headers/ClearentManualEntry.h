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


- (void) createTransactionToken:(ClearentCard*)clearentCard;

/**
 * Any errors will be returned here
 */
- (void) handleManualEntryError:(NSString*)message;

@end
