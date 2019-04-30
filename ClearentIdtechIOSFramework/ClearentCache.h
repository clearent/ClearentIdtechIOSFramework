//
//  ClearentCache.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/6/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentCache : NSObject

+ (NSString *) getStoredDeviceSerialNumber;
+ (void) updateConfigurationCache:(NSString *) deviceSerialNumber readerConfiguredFlag:(NSString *) readerConfiguredFlag;
+ (void) clearConfigurationCache;

@end
