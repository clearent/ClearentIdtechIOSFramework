//
//  ClearentUtils.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface ClearentUtils : NSObject

+ (NSString*) createExchangeChainId:(NSString *)embeddedValue;
+ (NSString*) deviceName;
+ (NSString*) osVersion;
+ (NSString*) sdkVersion;
+ (NSDictionary*) hostProfileData;

@end
