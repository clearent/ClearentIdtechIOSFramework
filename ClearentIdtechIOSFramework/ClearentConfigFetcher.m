//
//  ClearentConfigFetcher.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/28/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConfigFetcher.h"
#import "ClearentUtils.h"

static NSString *const RELATIVE_URL = @"rest/v2/mobile/devices";

@implementation ClearentConfigFetcher

- (instancetype)init: (NSURLSession *)session baseUrl:(NSString*)baseUrl deviceSerialNumber:(NSString*) deviceSerialNumber kernelVersion:(NSString*) kernelVersion publicKey:(NSString*) publicKey;
{
    self = [super init];
    if (self) {
        _session = session;
        _baseUrl = baseUrl;
        _deviceSerialNumber = deviceSerialNumber;
        _kernelVersion = kernelVersion;
        _publicKey = publicKey;
    }
    return self;
}

- (void)fetchConfiguration: (ClearentConfigFetcherResponse)callback {
    NSURLSession *session = [self session];
    NSMutableURLRequest *request = [self createNSMutableURLRequest];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:[ClearentConfigFetcher getClearentConfigFetcherTaskCompletionHandler:(ClearentConfigFetcherResponse)callback]];
    [task resume];
}

+ (ClearentConfigFetcherTaskCompletionHandler) getClearentConfigFetcherTaskCompletionHandler:(ClearentConfigFetcherResponse)callback {
    return ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSString *responseStr = nil;
        if(error != nil) {
            callback(nil);
        } else if(data != nil) {
            responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if(200 == [httpResponse statusCode]) {
                NSData *data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error;
                NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:0
                                                                                 error:&error];
                if (error) {
                    callback(nil);
                } else {
                    callback(jsonDictionary);
                }
            } else {
                callback(nil);
            }
        }
    };
}

- (NSMutableURLRequest*) createNSMutableURLRequest {
    NSMutableURLRequest *nSMutableURLRequest = [[NSMutableURLRequest alloc] init];
    [nSMutableURLRequest setHTTPMethod:@"GET"];
    [nSMutableURLRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [nSMutableURLRequest setValue:_publicKey  forHTTPHeaderField:@"public-key"];
    [nSMutableURLRequest setValue:[ClearentUtils createExchangeChainId:_deviceSerialNumber] forHTTPHeaderField:@"exchangeChainId"];
    [nSMutableURLRequest setURL:[NSURL URLWithString:[self createTargetUrl]]];
    return nSMutableURLRequest;
}

- (NSString*) createTargetUrl {
    NSString *trimmedDeviceSerialNumber = [_deviceSerialNumber substringToIndex:10];
    NSString *urlEncodedKernelVersion = [_kernelVersion stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    return [NSString stringWithFormat:@"%@/%@/%@/%@", _baseUrl, RELATIVE_URL,  trimmedDeviceSerialNumber, urlEncodedKernelVersion];
}

@end
