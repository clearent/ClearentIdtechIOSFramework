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
+ (NSString *) getReaderConfiguredFlag;
+ (NSString *) getReaderContactlessConfiguredFlag;
+ (void) updateConfigurationCache:(NSString *) deviceSerialNumber readerConfiguredFlag:(NSString *) readerConfiguredFlag;
+ (void) updateContactlessFlagCache:(NSString *) readerContactlessConfiguredFlag;
+ (void) clearConfigurationCache;
+ (void) clearContactlessConfigurationCache;
+ (BOOL) isDeviceConfigured:(BOOL)autoConfiguration contactlessAutoConfiguration:(BOOL)contactlessAutoConfiguration deviceSerialNumber:(NSString *)deviceSerialNumber;
@end
