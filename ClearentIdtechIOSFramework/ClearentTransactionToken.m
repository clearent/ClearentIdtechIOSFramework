//
//  ClearentTransactionToken.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/30/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import "ClearentTransactionToken.h"
#import "ClearentLumberjack.h"

@implementation ClearentTransactionToken

- (instancetype) initWithJson : (NSString *)jsonString {
    self = [super init];
    if (self) {
        if (jsonString != nil) {
            @try {
                 NSDictionary *successfulResponseDictionary = [self jsonAsDictionary:jsonString];
                 NSDictionary *payload = [successfulResponseDictionary objectForKey:@"payload"];
                 NSDictionary *emvJwt = [payload objectForKey:@"mobile-jwt"];
                 _cvm = [emvJwt objectForKey:@"cvm"];
                 _lastFour = [emvJwt objectForKey:@"last-four"];
                 _trackDataHash = [emvJwt objectForKey:@"track-data-hash"];
                 _jwt = [emvJwt objectForKey:@"jwt"];
                _cardType = [emvJwt objectForKey:@"card-type"];
            } @catch (NSException *exception) {
                _cvm = nil;
                _lastFour = nil;
                _trackDataHash = nil;
                _jwt = nil;
                _cardType = nil;;
            }
        }
    }
    return self;
}

- (NSDictionary *)jsonAsDictionary:(NSString*) stringJson {
    NSData *data = [stringJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [ClearentLumberjack logError:[NSString stringWithFormat:@"Failed to create ClearentTransactionToken %@", stringJson]];
    }
    
    return jsonDictionary;
}

@end
