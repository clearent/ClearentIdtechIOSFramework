//
//  ClearentIDTUtility.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 7/5/22.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentIDTUtility.h"
#import <IDTech/IDTUtility.h>

@implementation ClearentIDTUtility


+ (NSString *) getSubString:(NSString*)str startPosition:(int)start length:(int)len; {
    return [IDTUtility getSubString:str startPosition:start length:len];
}

+ (NSString*) dataToString:(NSData*)data; {
    return [IDTUtility dataToString:data];
}

+ (NSString*) dataToString:(NSData*)data startByte:(int)start length:(int)len; {
    return [IDTUtility dataToString:data startByte:start length:len];
}

@end
