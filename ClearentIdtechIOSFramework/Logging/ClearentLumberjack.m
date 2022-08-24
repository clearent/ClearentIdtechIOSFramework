//
//  ClearentLumberjack.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/17/21.
//  Copyright © 2021 Clearent, L.L.C. All rights reserved.
//

#import "ClearentLumberjack.h"
#import "ClearentLumberjackRemoteLogger.h"


@implementation ClearentLumberjack

BOOL enhancedFeedback = NO;

ClearentLumberjackRemoteLogger *clearentLumberjackRemoteLogger;
DDFileLogger *clearentFileLogger;


+ (void) initLumberJack:(NSString *) baseUrl publicKey:(NSString *) publicKey
{
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    
    clearentLumberjackRemoteLogger = [[ClearentLumberjackRemoteLogger alloc] init];
    clearentFileLogger = [[DDFileLogger alloc] init];
    
    clearentLumberjackRemoteLogger.baseUrl = baseUrl;
    clearentLumberjackRemoteLogger.publicKey = publicKey;
    clearentLumberjackRemoteLogger.saveInterval = 30;
   

    [DDLog addLogger:clearentLumberjackRemoteLogger];
    [DDLog addLogger:clearentFileLogger];
}

+ (void) logInfo:(NSString*) logMessage {
    if(logMessage != nil) {
        DDLogInfo(logMessage);
    }
}


+ (void) logError:(NSString*) logMessage {
    if(logMessage != nil) {
        DDLogInfo(logMessage);
    }
}

+ (void) flush {
    [DDLog flushLog];
}

+ (void) updatePublicKey:(NSString*) publicKey {
    if(publicKey != nil) {
        clearentLumberjackRemoteLogger.publicKey = publicKey;
    }
}

@end
