//
//  ClearentManualEntry.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/21/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentManualEntry.h"
#import "ClearentLumberjack.h"

static NSString *const GENERIC_ERROR_RESPONSE = @"Fail to create transaction token for manual entry";
static NSString *const CARD_REQUIRED = @"Card number required";
static NSString *const EXPIRATION_DATE_REQUIRED = @"Expiration date required";

@implementation ClearentManualEntry

    - (instancetype) init:(id <ClearentManualEntryDelegate>)clearentManualEntryDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:   (NSString*)publicKey {
        self = [super init];
        if (self) {
            self.clearentManualEntryDelegate = clearentManualEntryDelegate;
            self.publicKey = publicKey;
            self.clearentBaseUrl = clearentBaseUrl;
        }
        return self;
    }

    - (void) handleManualEntryError:(NSString*)message {
        [self handleManualEntryError:message completion:nil];
    }

    - (void) handleManualEntryError:(NSString*)message completion:(void (^)(ClearentTransactionToken* _Nullable))completion {
        [ClearentLumberjack logError:message];
        if (completion == nil) {
            [self.clearentManualEntryDelegate handleManualEntryError:message];
        } else {
            completion(nil);
        }
    }
    
    - (void) createTransactionToken:(ClearentCard*)clearentCard {
        [self createOfflineTransactionToken:clearentCard completion: nil];
    }

    - (void) createOfflineTransactionToken:(ClearentCard*)clearentCard completion:(void (^)(ClearentTransactionToken* _Nullable))completion {
           if(clearentCard == nil || clearentCard.card == nil || [clearentCard.card isEqualToString:@""]) {
               [self handleManualEntryError:CARD_REQUIRED completion: completion];
               return;
           }
           if(clearentCard == nil || clearentCard.expirationDateMMYY == nil || [clearentCard.expirationDateMMYY isEqualToString:@""]) {
               [self handleManualEntryError:EXPIRATION_DATE_REQUIRED completion:completion];
               return;
           }
           NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.clearentBaseUrl, @"rest/v2/mobilejwt/manual"];
           NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
           NSError *error;
           NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentCard.asDictionary options:0 error:&error];
           
           if (error) {
               [ClearentLumberjack logError:@"Failed to serialize card data"];
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE completion: completion];
               return;
           }
           
           [request setHTTPBody:postData];
           [request setHTTPMethod:@"POST"];
           [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
           [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
           [request setValue:self.publicKey forHTTPHeaderField:@"public-key"];
           [request setURL:[NSURL URLWithString:targetUrl]];
           
           [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
             ^(NSData * _Nullable data,
               NSURLResponse * _Nullable response,
               NSError * _Nullable error) {
                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                 NSString *responseStr = nil;
                 if(error != nil) {
                     [self handleManualEntryError:error.description completion:completion];
                    
                 } else if(data != nil) {
                     responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                     if(200 == [httpResponse statusCode]) {
                         [self handleResponse:responseStr completion: completion];
                     } else {
                         [self handleError:responseStr completion: completion];
                     }
                 }
                 data = nil;
                 response = nil;
                 error = nil;
             }] resume];
       }

       
    - (void) handleError:(NSString*)response completion:(void (^)(ClearentTransactionToken* _Nullable))completion {
           NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
           NSError *error;
           NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:&error];
           if (error) {
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE completion:completion];
           } else {
               NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
               NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
               NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
               if(errorMessage != nil) {
                   [self handleManualEntryError:[NSString stringWithFormat:@"%@. %@.", GENERIC_ERROR_RESPONSE, errorMessage] completion:completion];
               } else {
                   [self handleManualEntryError:GENERIC_ERROR_RESPONSE completion: completion];
               }
           }
       }
       
    - (void) handleResponse:(NSString *)response completion:(void (^)(ClearentTransactionToken* _Nullable))completion {
           NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
           NSError *error;
           NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:&error];
           if (error) {
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE completion:completion];
           }
           NSString *responseCode = [jsonDictionary objectForKey:@"code"];
           if([responseCode isEqualToString:@"200"]) {
               [ClearentLumberjack logInfo:@"➡️ Successful transaction token communicated to client app for manual entry"];
               if ([self.clearentManualEntryDelegate respondsToSelector:@selector(successfulTransactionToken:)]) {
                   [self.clearentManualEntryDelegate successfulTransactionToken:response];
               }
               ClearentTransactionToken *clearentTransactionToken = [[ClearentTransactionToken alloc] initWithJson:response];
               if (completion == nil) {
                   [self.clearentManualEntryDelegate successTransactionToken:clearentTransactionToken];
               } else {
                   completion(clearentTransactionToken);
               }
           } else {
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE completion:completion];
           }
       }

@end
