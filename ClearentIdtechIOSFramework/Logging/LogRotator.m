//
//  Teleport.m
//  Pods
//
//  Created by Kenneth on 1/17/15.
//
//

#import "LogRotator.h"

#import "Singleton.h"
#import "TeleportUtils.h"
#import "ClearentLogging.h"

static const int TP_LOG_ROTATION_TIMER_INTERVAL = 120ull;
static const char* const TP_LOG_ROTATION_QUEUE_NAME = "com.clearent.LogRotation";
static const long long TP_MAX_LOG_FILE_SIZE = 900000ull;
static const int TP_MAX_ROTATE_INTERVAL_IN_SECS = 600;

@interface LogRotator() {
    NSString *_currentLogPath;
    NSDate *_lastRotation;
    dispatch_queue_t _logRotationQueue;
    dispatch_source_t _timer;
}

@end

@implementation LogRotator

- (id) init
{
    if((self = [super init]))
    {
        _currentLogPath = nil;
        _lastRotation = [NSDate date];
        _logRotationQueue = dispatch_queue_create(TP_LOG_ROTATION_QUEUE_NAME, DISPATCH_QUEUE_SERIAL);

        [TeleportUtils teleportDebug:@"Rotation Queue: %@", _logRotationQueue];
    }
    return self;
}


- (void)startLogRotation
{
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, _logRotationQueue);
    if (_timer)
    {
        uint64_t interval = TP_LOG_ROTATION_TIMER_INTERVAL * NSEC_PER_SEC;
        uint64_t leeway = 1ull * NSEC_PER_SEC;
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, leeway);
        dispatch_source_set_event_handler(_timer, ^{
            [self rotateIfNeeded];
        });
        dispatch_resume(_timer);
    }
}

- (NSString *)logPathSuffix {
    return @".log";
}

- (NSString *)logDir {
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [cacheDirectory stringByAppendingPathComponent:@"com.clearent.data"];
}

- (NSString *)currentLogFilePath {
    return _currentLogPath;
}

// *Not thread-safe* Need to be synchronized by caller.
- (void)rotateIfNeeded
{
    [TeleportUtils teleportDebug:@"Log rotation woke up"];

    if (_currentLogPath == nil) {       //No current log. Create a new one
        [self rotate];
    } else {
        NSDate *timeToRotate = [_lastRotation dateByAddingTimeInterval:TP_MAX_ROTATE_INTERVAL_IN_SECS];
        if ([self fileSize:_currentLogPath] > TP_MAX_LOG_FILE_SIZE
            || [[NSDate date] timeIntervalSinceReferenceDate] > [timeToRotate timeIntervalSinceReferenceDate] ) {
            [self rotate];
        }
    }
}

- (long long)fileSize:(NSString *)filePath
{
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attributesError];
    
    if (attributesError)
        return -1ll;

    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    return [fileSizeNumber longLongValue];
}

- (void)rotate
{
    NSString *logDir = [self ensureLogDir];
    NSString *nextFileName = [NSString stringWithFormat:@"%f%@", [[NSDate date] timeIntervalSince1970] * 1000, [self logPathSuffix]];
    [TeleportUtils teleportDebug:@"Rotating FROM: %@", _currentLogPath];
    _currentLogPath = [logDir stringByAppendingPathComponent:nextFileName];
    [TeleportUtils teleportDebug:@"TO: %@", _currentLogPath];
    //Do not direct stderr to file. Let's handle writing to the file.
    //freopen([_currentLogPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath: _currentLogPath];
    if(fileHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:_currentLogPath contents:nil attributes:nil];
        NSMutableData *data;
        const char *bytestring = "Beginning of log file";
        data = [NSMutableData dataWithBytes:bytestring length:strlen(bytestring)];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
    _lastRotation = [NSDate date];
}

- (NSString *)ensureLogDir
{
    NSString *nextDirectory = [self logDir];
    BOOL isDir = NO;
    NSError *err1;
    NSError *err2;
    if ([[NSFileManager defaultManager] fileExistsAtPath:nextDirectory isDirectory:&isDir])
    {
        [TeleportUtils teleportDebug:@"Dir existed: %@", nextDirectory];
        if (!isDir) {
            [TeleportUtils teleportDebug:@"WARNING!!! Existed but not a dir. Recreating %@", nextDirectory];
            [[NSFileManager defaultManager] removeItemAtPath:nextDirectory error:&err1];
            [[NSFileManager defaultManager]createDirectoryAtPath:nextDirectory withIntermediateDirectories:YES attributes:nil error:&err2];
        }
    }
    else
    {
        [TeleportUtils teleportDebug:@"Dir not existed: %@. Creating", nextDirectory];
        [[NSFileManager defaultManager]createDirectoryAtPath:nextDirectory withIntermediateDirectories:YES attributes:nil error:&err2];
    }
    if (err1 || err2) {
        [TeleportUtils teleportDebug:@"ERROR!!!: error1: %@\nerror2: %@", err1, err2];;
        return nil;
    }
    return nextDirectory;
}
@end
