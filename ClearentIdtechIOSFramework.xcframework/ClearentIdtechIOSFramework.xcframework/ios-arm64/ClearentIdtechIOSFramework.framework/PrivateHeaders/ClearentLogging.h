//
//  ClearentLogging.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface ClearentLogging : NSObject

@property(nonatomic) NSString *createdDate;
@property(nonatomic) NSString *level;
@property(nonatomic) NSString *message;

- (NSString*) asJson;
- (NSDictionary*) asDictionary;

@end
