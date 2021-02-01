//
//  Teleport.m
//  Pods
//
//  Created by Kenneth on 1/17/15.
//
//

#import "LogReaper.h"
#import "Teleport.h"
#import "TeleportUtils.h"
#import <UIKit/UIKit.h>

static const int TP_LOG_REAPING_TIMER_INTERVAL = 60ull;
static const char* const TP_LOG_REAPING_QUEUE_NAME = "com.clearent.LogReaping";

@interface LogReaper() {
    LogRotator *_logRotator;
    dispatch_queue_t _logReapingQueue;
    dispatch_source_t _timer;
    NSUUID *_uuid;
    id <Forwarder> _forwarder;
}

@end

@implementation LogReaper

- (id) init
{
    [NSException raise:@"Only initWithLogRotator is allowed" format:@"Hello Apple, can you give us a better way of preventing wrong init methods being called?"];
    return nil;

}

- (id) initWithLogRotator: (LogRotator *) logRotator AndForwarder: (SimpleHttpForwarder *) forwarder
{
    if((self = [super init]))
    {
        _logRotator = logRotator;
        _forwarder = forwarder;

        _uuid = [[UIDevice currentDevice] identifierForVendor];
        [TeleportUtils teleportDebug:@"UUID: %@", _uuid];
        _logReapingQueue = dispatch_queue_create(TP_LOG_REAPING_QUEUE_NAME, DISPATCH_QUEUE_SERIAL);
        [TeleportUtils teleportDebug:@"Reaping Queue: %@", _logReapingQueue];
        
    }
    return self;
}


- (void) startLogReaping
{
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                    0, 0, _logReapingQueue);
    if (_timer)
    {
        uint64_t interval = TP_LOG_REAPING_TIMER_INTERVAL * NSEC_PER_SEC;
        uint64_t leeway = 1ull * NSEC_PER_SEC;
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, TP_LOG_REAPING_TIMER_INTERVAL * NSEC_PER_SEC / 2 ), interval, leeway);
        dispatch_source_set_event_handler(_timer, ^{
            [self reap];
        });
        dispatch_resume(_timer);
    }
}

- (void) reap
{
    [TeleportUtils teleportDebug:@"Log reaping woke up"];

    if ([_logRotator currentLogFilePath] == nil) {
        [TeleportUtils teleportDebug:@"Rotator is not ready yet. Nothing to be done"];
        return;
    }

    NSArray *sortedFiles = nil;
    @try {
          sortedFiles = [self getSortedFilesWithSuffix:[_logRotator logPathSuffix] fromFolder:[_logRotator logDir]];
          [TeleportUtils teleportDebug:[NSString stringWithFormat:@"# of log files found: %lu", (unsigned long)sortedFiles.count]];
       }
       @catch (NSException *e) {
           NSLog("failed to sort files");
       }
    
    if (sortedFiles == nil || sortedFiles.count < 1) {
        return;
    }

    NSString *oldestFile = nil;
    NSError* error = nil;
    
    @try {
        
        oldestFile = [(NSDictionary*)[sortedFiles objectAtIndex:0] objectForKey:@"path"];
      
        if(oldestFile != nil) {
            [TeleportUtils teleportDebug:[NSString stringWithFormat:@"Oldest log file: %@", oldestFile]];
            NSData *fileData = [NSData dataWithContentsOfFile:oldestFile options: 0 error: &error];
            if (fileData == nil)
            {
               NSLog(@"Failed to read file, error %@", error);
              [TeleportUtils teleportDebug:@"The oldestfile is not available in reap"];
            }
            else
            {
                [_forwarder forwardLog:fileData forDeviceId:[_uuid UUIDString]];
            }
        }
        
    }
    @catch (NSException *e) {
        [TeleportUtils teleportDebug:[NSString stringWithFormat:@"Exception: %@", e]];
    }
    @finally {
        // Delete log file after reapped
        // Consider log file reaped even in case of exception for maximum robustness.
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        
        @try {
               
            if(oldestFile != nil) {
              [manager removeItemAtPath:oldestFile error:&error];
               
               if (error) {
                   [TeleportUtils teleportDebug:[NSString stringWithFormat:@"Exception: %@", error]];
               }
            }
               
        }
        @catch (NSException *e) {
            NSLog(@"failed to remote item at path");
        }
        
        
        if (sortedFiles != nil && sortedFiles.count == 1) {
            [TeleportUtils teleportDebug:@"Rotate when last file deleted"];
            [_logRotator rotate];
        }
        
    }
}

//This is reusable method which takes folder path and returns sorted file list
-(NSArray*) getSortedFilesWithSuffix: (NSString *) suffix fromFolder: (NSString*) folderPath
{
    @try{
        NSError *error = nil;
        NSArray* filesArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
        if (error) {
            [TeleportUtils teleportDebug:@"Error: %@", error];
            return [[NSArray alloc] init]; //return empty array in case of error
        }

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF EndsWith %@", suffix];
        filesArray =  [filesArray filteredArrayUsingPredicate:predicate];

        NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[filesArray count]];
        
        for(NSString* file in filesArray) {
            
            if (![file isEqualToString:@".DS_Store"]) {
                NSString* filePath = [folderPath stringByAppendingPathComponent:file];
                NSDictionary* properties = [[NSFileManager defaultManager]
                                            attributesOfItemAtPath:filePath
                                            error:&error];
                NSDate* modDate = [properties objectForKey:NSFileModificationDate];
                
                [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                               filePath, @"path",
                                               modDate, @"lastModDate",
                                               nil]];
                
            }
        }
        
        // Sort using a block - order inverted as we want latest date first
        NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:
                                ^(NSDictionary* path1, NSDictionary* path2)
                                {
                                    return [(NSDate*)[path1 objectForKey:@"lastModDate"] compare:
                                                               [path2 objectForKey:@"lastModDate"]];
                                }];
        return sortedFiles;
    }
    @catch (NSException *e) {
        NSLog(@"failed to getSortedFilesWithSuffix");
    }
    
    return nil;
    
}
@end
