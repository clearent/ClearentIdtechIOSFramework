//
//  ClearentUIManager.m
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 24.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

#import "ClearentUIManager.h"

static ClearentUIManager *sharedUImanager = nil;

@implementation ClearentUIManager

+ (id)sharedUIManager {
    if (sharedUImanager == nil) {
        sharedUImanager = [[ClearentUIManager alloc] init];
    }
    
    return sharedUImanager;
}

- (ClearentPaymentProcessingViewController *)paymentProcessingViewController {
    ClearentPaymentProcessingViewController *vc = [[ClearentPaymentProcessingViewController alloc] initWithNibName:@"ClearentPaymentProcessingViewController" bundle:[NSBundle bundleForClass:[ClearentPaymentProcessingViewController self]]];
    
    return vc;
}

@end
