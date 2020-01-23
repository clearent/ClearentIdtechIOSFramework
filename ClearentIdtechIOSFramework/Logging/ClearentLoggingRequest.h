//
//  ClearentLoggingRequest.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentLoggingRequest : NSObject

@property(nonatomic) NSString *deviceSerialNumber;
@property(nonatomic) NSDictionary *logging;

- (NSString*) asJson;
- (NSDictionary*) asDictionary;

@end
