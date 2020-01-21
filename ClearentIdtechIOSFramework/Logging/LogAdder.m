//
//  LogAdder.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/5/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import "LogAdder.h"
#import "ClearentLogging.h"

static NSString *const END_OF_LINE_INDICATOR = @"endofline";
static NSString *const CREATED_DATE_FORMAT = @"yyyy-MM-dd-HH-mm-ss-SSS-zzz";

@implementation LogAdder

+ (void) logInfo:(NSString*) logMessage currentLogFilePath:(NSString*) currentLogFilePath {
    if(logMessage != nil) {
        [LogAdder log:logMessage currentLogFilePath:currentLogFilePath level:@"info"];
    }
}

+ (void) logError:(NSString*) logMessage currentLogFilePath:(NSString*) currentLogFilePath {
    if(logMessage != nil) {
        [LogAdder log:logMessage currentLogFilePath:currentLogFilePath level:@"error"];
    }
}

+ (void) log:(NSString*) logMessage currentLogFilePath:(NSString*) currentLogFilePath level:(NSString*) level {
    if(logMessage != nil) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:currentLogFilePath];
        if (fileHandle){
            [fileHandle seekToEndOfFile];
            logMessage = [NSString stringWithFormat:@"%@%@",[LogAdder createLogging:logMessage level:level] , END_OF_LINE_INDICATOR];
            [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    }
}

+ (NSString *) createLogging:(NSString *) message level:(NSString *) level {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:CREATED_DATE_FORMAT];
    NSDate *now = [[NSDate alloc] init];
    NSString *createdDate = [dateFormat stringFromDate:now];
    if(message == nil) {
        message = @"empty";
    }
    if(level == nil) {
        level = @"info";
    }
    return [NSString stringWithFormat:@"%@clrnt%@clrnt%@", level, message, createdDate];
}

@end
