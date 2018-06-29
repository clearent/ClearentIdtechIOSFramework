//
//  ClearentConfigFetcher.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/28/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConfigFetcher.h"

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

- (void)fetchConfiguration: (ClearentConfigFetcherResponse)callback;
{
    NSURLSession *session = [self session];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:_publicKey  forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:[self createTargetUrl]]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
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
                NSLog(@"config: %@", jsonDictionary);
                if (error) {
                    callback(nil);
                } else {
                    callback(jsonDictionary);
                }
            } else {
                callback(nil);
            }
        }
        data = nil;
        response = nil;
        error = nil;
        
    }];
    [task resume];
}

- (NSString*) createTargetUrl {
    NSString *trimmedDeviceSerialNumber = [_deviceSerialNumber substringToIndex:10];
    NSString *urlEncodedKernelVersion = [_kernelVersion stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    return [NSString stringWithFormat:@"%@/%@/%@/%@", _baseUrl, RELATIVE_URL,  trimmedDeviceSerialNumber, urlEncodedKernelVersion];
}

@end
