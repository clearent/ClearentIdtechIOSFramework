//
//  ClearentConfigFetcher.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/28/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentConfigurator.h"

typedef void (^ClearentConfigFetcherResponse)(NSDictionary *json);
typedef void (^ClearentConfigFetcherTaskCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface ClearentConfigFetcher : NSObject

    @property (nonatomic) NSURLSession *session;
    @property(nonatomic) NSString *baseUrl;
    @property(nonatomic) NSString *publicKey;
    @property(nonatomic) NSString *deviceSerialNumber;
    @property(nonatomic) NSString *kernelVersion;

    - (id)init:(NSURLSession *)session baseUrl:(NSString*)baseUrl deviceSerialNumber:(NSString*) deviceSerialNumber kernelVersion:(NSString*) kernelVersion publicKey:(NSString*) publicKey;

    - (void)fetchConfiguration: (ClearentConfigFetcherResponse) callback;

    - (NSMutableURLRequest*) createNSMutableURLRequest;

    - (NSString*) createTargetUrl;
    
@end


