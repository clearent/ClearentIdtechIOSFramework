#import "SimpleHttpForwarder.h"
#import "TeleportUtils.h"
#import "ClearentLoggingRequest.h"
#import "ClearentLogging.h"
#import "ClearentUtils.h"
#import "ClearentCache.h"

static NSString *const LOG_RELATIVE_URL = @"rest/v2/mobile/log";
static NSString *const END_OF_LINE_INDICATOR = @"endofline";
static NSString *const LINE_DELIMITER = @"clrnt";

@interface SimpleHttpForwarder()
@end

@implementation SimpleHttpForwarder

   BOOL enabled;

+ (SimpleHttpForwarder *)forwarderWithAggregatorUrl:(NSString *)url publicKey:(NSString *)publicKey {
    SimpleHttpForwarder *forwarder = [[SimpleHttpForwarder alloc] init];
    forwarder.aggregatorUrl = url;
    forwarder.publicKey = publicKey;
    enabled = YES;
    return forwarder;
}

- (void)forwardLog:(NSData *)log forDeviceId:(NSString *)devId {
    if (self.aggregatorUrl == nil || self.aggregatorUrl.length == 0)
        return;
    
    if ([log length] < 1)
        return;
    
    if (!enabled) {
        return;
    }
    
    ClearentLoggingRequest *clearentLoggingRequest = [self parseData:log];
    [self uploadData:clearentLoggingRequest forField:@"file" URL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.aggregatorUrl,LOG_RELATIVE_URL]] completion:^(BOOL success, NSString *errorMessage) {
        [TeleportUtils teleportDebug:[NSString stringWithFormat:@"success = %d; errorMessage = %@", success, errorMessage]];
    }];
}

-(ClearentLoggingRequest*) parseData:(NSData*) responseData
{
    ClearentLoggingRequest *clearentLoggingRequest = [[ClearentLoggingRequest alloc] init];
    clearentLoggingRequest.deviceSerialNumber = [ClearentCache getCurrentDeviceSerialNumber];
    
    NSString *stringFromData = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSArray *logLines = [stringFromData componentsSeparatedByString:END_OF_LINE_INDICATOR];

    NSMutableArray* clearentLoggings = [NSMutableArray arrayWithCapacity:[logLines count]];
    
    for (NSString *line in logLines) {
        if(![line isEqualToString:@""]) {
            ClearentLogging *clearentLogging = [[ClearentLogging alloc] init];
            NSArray *logData = [line componentsSeparatedByString:LINE_DELIMITER];
            if(logData != nil) {
                clearentLogging.level = logData[0];
                clearentLogging.message = logData[1];
                clearentLogging.createdDate = logData[2];
                [clearentLoggings addObject:clearentLogging.asDictionary];
            }
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
        [TeleportUtils teleportDebug:[NSString stringWithFormat: @"serializationError = %@", serializationError]];
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
                  if (completion) {
                      [self checkIfServerHasDisabledLogging: responseStr];
                      completion(TRUE, @"Ok");
                  }
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

- (void) checkIfServerHasDisabledLogging:(NSString *)response {
    if(response == nil) {
        return;
    }
    @try {
        NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:0
                                                                             error:&error];
        if (error) {
            return;
        }
        NSDictionary *payloadDictionary = [responseDictionary objectForKey:@"payload"];
        NSDictionary *mobileLogDictionary = [payloadDictionary objectForKey:@"mobile-log"];
        NSString *disableLogging = [mobileLogDictionary objectForKey:@"disable-logging"];
        if([disableLogging boolValue]) {
            [TeleportUtils teleportDebug:@"Remote logging has been disabled by the server. If the app is restarted you can enable a one time log request."];
            enabled = NO;
        }
    }
    @catch (NSException *e) {
        [TeleportUtils teleportDebug:@"Remote logging response could not be read. Logging can never be disabled."];
    }
   
}

@end

