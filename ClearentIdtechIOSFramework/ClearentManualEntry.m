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
        [ClearentLumberjack logError:message];
        [self.clearentManualEntryDelegate handleManualEntryError:message];
    }
    
    - (void) createTransactionToken:(ClearentCard*)clearentCard {
           if(clearentCard == nil || clearentCard.card == nil || [clearentCard.card isEqualToString:@""]) {
               [self handleManualEntryError:CARD_REQUIRED];
               return;
           }
           if(clearentCard == nil || clearentCard.expirationDateMMYY == nil || [clearentCard.expirationDateMMYY isEqualToString:@""]) {
               [self handleManualEntryError:EXPIRATION_DATE_REQUIRED];
               return;
           }
           NSString *targetUrl = [NSString stringWithFormat:@"%@/%@", self.clearentBaseUrl, @"rest/v2/mobilejwt/manual"];
           NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
           NSError *error;
           NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentCard.asDictionary options:0 error:&error];
           
           if (error) {
               [ClearentLumberjack logError:@"Failed to serialize card data"];
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE];
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
                     [self handleManualEntryError:error.description];
                    
                 } else if(data != nil) {
                     responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                     if(200 == [httpResponse statusCode]) {
                         [self handleResponse:responseStr];
                     } else {
                         [self handleError:responseStr];
                     }
                 }
                 data = nil;
                 response = nil;
                 error = nil;
             }] resume];
       }

       
    - (void) handleError:(NSString*)response {
           NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
           NSError *error;
           NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:&error];
           if (error) {
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE];
           } else {
               NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
               NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
               NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
               if(errorMessage != nil) {
                   [self handleManualEntryError:[NSString stringWithFormat:@"%@. %@.", GENERIC_ERROR_RESPONSE, errorMessage]];
               } else {
                   [self handleManualEntryError:GENERIC_ERROR_RESPONSE];
               }
           }
       }
       
    - (void) handleResponse:(NSString *)response {
           NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
           NSError *error;
           NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:&error];
           if (error) {
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE];
           }
           NSString *responseCode = [jsonDictionary objectForKey:@"code"];
           if([responseCode isEqualToString:@"200"]) {
               [ClearentLumberjack logInfo:@"➡️ Successful transaction token communicated to client app for manual entry"];
               if ([self.clearentManualEntryDelegate respondsToSelector:@selector(successfulTransactionToken:)]) {
                   [self.clearentManualEntryDelegate successfulTransactionToken:response];
               }
               ClearentTransactionToken *clearentTransactionToken = [[ClearentTransactionToken alloc] initWithJson:response];
               [self.clearentManualEntryDelegate successTransactionToken:clearentTransactionToken];
           } else {
               [self handleManualEntryError:GENERIC_ERROR_RESPONSE];
           }
       }

@end
