//
//  Teleport.m
//  Pods
//
//  Created by Kenneth on 1/17/15.
//
//

#import "Teleport.h"
#import "Singleton.h"
#import "LogRotator.h"
#import "LogReaper.h"
#import "LogAdder.h"


BOOL TELEPORT_DEBUG = NO;
BOOL TELEPORT_ENABLED = NO;

@interface Teleport() {
    LogRotator *_logRotator;
    LogReaper *_logReaper;
    id <Forwarder> _forwarder;
}

@end
@implementation Teleport

IMPLEMENT_EXCLUSIVE_SHARED_INSTANCE(Teleport)

+ (void) startWithForwarder:(id <Forwarder>)forwarder;
{
    Teleport *instance = [Teleport sharedInstance];
    [instance startWithForwarder:forwarder];
}

#pragma mark - Lifecycle -

- (void)startWithForwarder:(id <Forwarder>)forwarder {
    _forwarder = forwarder;

    if (TELEPORT_DEBUG) { //turned on teleport we are debugging Teleport
        TELEPORT_ENABLED = YES;
    }
    else {
#ifndef DEBUG   //Send to backend only when it's in production mode
        TELEPORT_ENABLED = YES;
#endif
    }
    
    if (TELEPORT_ENABLED) {
        _logRotator = [[LogRotator alloc] init];
        _logReaper = [[LogReaper alloc] initWithLogRotator:_logRotator AndForwarder:_forwarder];
        
        [_logRotator startLogRotation];
        [_logReaper startLogReaping];
    }
}

+ (void) logInfo:(NSString*) logMessage {
    if(TELEPORT_ENABLED) {
        if(logMessage != nil) {
            Teleport *instance = [Teleport sharedInstance];
            [instance logInfo:[NSString stringWithFormat:@" %@", logMessage]];
        }
    }
}

- (void) logInfo:(NSString*) logMessage {
    if(TELEPORT_ENABLED) {
        if ([_logRotator currentLogFilePath] == nil) {
            [_logRotator rotate];
        }
        if(logMessage != nil) {
            [LogAdder logInfo:logMessage currentLogFilePath:[_logRotator currentLogFilePath]];
        }
    }
}

+ (void) logError:(NSString*) logMessage {
    if(TELEPORT_ENABLED) {
        if(logMessage != nil) {
            Teleport *instance = [Teleport sharedInstance];
            [instance logError:[NSString stringWithFormat:@"💩💩💩 %@%@", logMessage, @" 💩💩💩"]];
        }
    }
}

- (void) logError:(NSString*) logMessage {
    if(TELEPORT_ENABLED) {
        if ([_logRotator currentLogFilePath] == nil) {
            [_logRotator rotate];
        }
        if(logMessage != nil) {
            [LogAdder logError:logMessage currentLogFilePath:[_logRotator currentLogFilePath]];
        }
    }
}

@end
