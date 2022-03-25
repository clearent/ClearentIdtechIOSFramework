//
//  ClearentUIManager.h
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 24.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentPaymentProcessingViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ClearentUIManager : NSObject

+ (id)sharedUIManager;
- (ClearentPaymentProcessingViewController *)paymentProcessingViewController;

@end

NS_ASSUME_NONNULL_END
