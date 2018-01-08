//
//  ClearentTransactionTokenRequest.h
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentTransactionTokenRequest : NSObject
@property (nonatomic) NSString *tlv;
@property (nonatomic) BOOL isEncrypted;
- (NSString*) asJson;
- (NSDictionary*) asDictionary;
@end
