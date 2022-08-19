//
//  ClearentIDTUtility.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 7/5/22.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface ClearentIDTUtility : NSObject

+ (NSString *) getSubString:(NSString*)str startPosition:(int)start length:(int)len;
+ (NSString*) dataToString:(NSData*)data;
+ (NSString*) dataToString:(NSData*)data startByte:(int)start length:(int)len;

@end
