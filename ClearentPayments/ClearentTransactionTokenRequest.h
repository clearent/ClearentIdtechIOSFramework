//
//  ClearentTransactionTokenRequest.h
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentTransactionTokenRequest : NSObject
@property (nonatomic, weak) NSString *tlv;
@property (nonatomic) BOOL encrypted;
@property (nonatomic, weak) NSString *firmwareVersion;
@property (nonatomic, weak) NSString *deviceSerialNumber;
- (NSString*) asJson;
- (NSDictionary*) asDictionary;
@end
