//
//  LogAdder.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/5/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface LogAdder : NSObject

+ (void) logInfo:(NSString*) logMessage currentLogFilePath:(NSString*) currentLogFilePath;
+ (void) logError:(NSString*) logMessage currentLogFilePath:(NSString*) currentLogFilePath;
+ (void) log:(NSString*) logMessage currentLogFilePath:(NSString*) currentLogFilePath level:(NSString*) level;
+ (NSString *) createLogging:(NSString *) message level:(NSString *) level;

@end
