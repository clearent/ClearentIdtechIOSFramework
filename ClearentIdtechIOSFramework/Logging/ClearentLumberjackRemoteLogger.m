//
//  ClearentLumberjackRemoteLogger.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/17/21.
//  Copyright © 2021 Clearent, L.L.C. All rights reserved.
//

#import "ClearentLumberjackRemoteLogger.h"
#import "ClearentLoggingRequest.h"
#import "ClearentLogging.h"
#import "ClearentUtils.h"
#import "ClearentCache.h"

static NSString *const LOG_RELATIVE_URL = @"rest/v2/mobile/log";
static NSString *const END_OF_LINE_INDICATOR = @"endofline";
static NSString *const LINE_DELIMITER = @"clrnt";


@implementation ClearentLumberjackRemoteLogger {
    NSMutableArray *_logMessagesArray;
}

- (id)init {
    self = [super init];
    if (self) {
        
        self.deleteInterval = 0;
        self.maxAge = 0;
        self.deleteOnEverySave = NO;
        self.saveInterval = 120;
        self.saveThreshold = 1000;

        // Make sure we POST the logs when the application is suspended
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveOnSuspend)
                                                     name:@"UIApplicationWillResignActiveNotification"
                                                   object:nil];

    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Overridden methods from DDAbstractDatabaseLogger

- (BOOL)db_log:(DDLogMessage *)logMessage
{
    // Return YES if an item was added to the buffer.
    // Return NO if the logMessage was ignored.

    // Initialize the log messages array if we havn't already (or its recently been cleared by saving).
    if ( ! _logMessagesArray) {
        _logMessagesArray = [NSMutableArray arrayWithCapacity:1000];
    }

    if ([_logMessagesArray count] > 2000) {
        // Too much logging is coming in too fast. Let's not put this message in the array
        // However, we want the abstract logger to retry at some time later, so
        // let's return YES, so the log message counters in the abstract logger keeps getting incremented.
        return YES;
    }

    [_logMessagesArray addObject:logMessage];
    return YES;
}

- (void)db_save
{
    [self db_saveAndDelete];
}

- (void)db_delete
{
    // We don't ever want to delete log messages
}

- (void)db_saveAndDelete
{

    if ( ! [self isOnInternalLoggerQueue]) {
        NSAssert(NO, @"db_saveAndDelete should only be executed on the internalLoggerQueue thread, if you're seeing this, your doing it wrong.");
    }
    
    if ([_logMessagesArray count] == 0) {
        return;
    }

    NSArray *oldLogMessagesArray = [_logMessagesArray copy];

    _logMessagesArray = [NSMutableArray arrayWithCapacity:0];

    [self postLogsToClearent:oldLogMessagesArray];

}

- (void) postLogsToClearent:(NSArray *)oldLogMessagesArray {

    if ([oldLogMessagesArray count] == 0) {
        NSLog(@"postLogsToClearent:no logs");
        return;
    }
    
    ClearentLoggingRequest *clearentLoggingRequest = [self parseData:oldLogMessagesArray];
    
    if(clearentLoggingRequest != nil && clearentLoggingRequest.logging != nil) {
        
        @try {
                [self uploadData:clearentLoggingRequest forField:@"file" URL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.baseUrl,LOG_RELATIVE_URL]] completion:^(BOOL success, NSString *errorMessage) {
                  }];
        } @catch (NSException *e) {
            NSLog(@"exception when calling clearent remote logging");
        }
    }
}

-(ClearentLoggingRequest*) parseData:(NSArray*) oldLogMessagesArray
{
    
    ClearentLoggingRequest *clearentLoggingRequest = [[ClearentLoggingRequest alloc] init];
    
    @try {
           clearentLoggingRequest.deviceSerialNumber = [ClearentCache getCurrentDeviceSerialNumber];

           NSMutableArray* clearentLoggings = [NSMutableArray arrayWithCapacity:[oldLogMessagesArray count]];
           
           for (DDLogMessage *ddLogMessage in oldLogMessagesArray) {
               if(![ddLogMessage.message isEqualToString:@""]) {
                   ClearentLogging *clearentLogging = [[ClearentLogging alloc] init];
                   if(ddLogMessage.level == DDLogLevelError) {
                       clearentLogging.level = @"error";
                   } else if(ddLogMessage.level == DDLogLevelInfo) {
                       clearentLogging.level = @"info";
                   } else if(ddLogMessage.level == DDLogLevelWarning) {
                       clearentLogging.level = @"warn";
                   } else {
                       clearentLogging.level = @"debug";
                   }
                   
                   clearentLogging.message = ddLogMessage.message;
                   NSString *dateString = [NSDateFormatter localizedStringFromDate:ddLogMessage.timestamp
                                    dateStyle:NSDateFormatterMediumStyle
                                    timeStyle:NSDateFormatterMediumStyle];
                   clearentLogging.createdDate = dateString;
                   [clearentLoggings addObject:clearentLogging.asDictionary];
               }
           }
           
           NSData* data = [ NSJSONSerialization dataWithJSONObject:clearentLoggings options:0 error:nil ];
           NSError *serializationError;
           NSDictionary *loggingsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
           if(serializationError) {
               clearentLoggingRequest.logging = nil;
           } else {
               clearentLoggingRequest.logging = loggingsDictionary;
           }
          
       }
       @catch (NSException *e) {
           NSLog(@"failed to parse logging data");
           if(clearentLoggingRequest != nil) {
               clearentLoggingRequest.logging = nil;
           }
       }
    
    return clearentLoggingRequest;
    
}

- (void)uploadData:(ClearentLoggingRequest *)clearentLoggingRequest
                forField:(NSString *)fieldName
                     URL:(NSURL*)targetUrl
              completion:(void (^)(BOOL success, NSString *errorMessage))completion
{
   
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *serializationError;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentLoggingRequest.asDictionary options:0 error:&serializationError];
    
    if (serializationError) {
        return;
    }
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPBody:postData];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[ClearentUtils createExchangeChainId:clearentLoggingRequest.deviceSerialNumber] forHTTPHeaderField:@"exchangeChainId"];
    [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
    [request setURL:targetUrl];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              if (completion) {
                  completion(FALSE, [NSString stringWithFormat:@"%s: failed to send log error: %@", __FUNCTION__, error]);
              }
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  NSLog(@"Successful remote log");
              } else {
                  if (completion) {
                      completion(FALSE, [NSString stringWithFormat:@"%s: failed to send log error: %@", __FUNCTION__, error]);
                  }
              }
          }
          data = nil;
          response = nil;
          error = nil;
      }] resume];
}


- (void) saveOnSuspend {
#ifdef DEBUG
    NSLog(@"Suspending, posting logs to Clearent");
#endif
    
    dispatch_async(_loggerQueue, ^{
        [self db_save];
    });
}

@end
