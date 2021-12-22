//
//  ClearentLumberjack.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/17/21.
//  Copyright © 2021 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG_LEVEL_DEF ddLogLevel
#define DD_LEGACY_MESSAGE_TAG 0
#import <CocoaLumberjack/CocoaLumberjack.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface ClearentLumberjack : NSObject
    + (void) initLumberJack:(NSString *) baseUrl publicKey:(NSString *) publicKey;
    + (void) logInfo:(NSString*) logMessage;
    + (void) logError:(NSString*) logMessage;
    + (void) flush;
    + (void) updatePublicKey:(NSString*) logMessage;
@end
