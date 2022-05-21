//
//  ClearentCard.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/21/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentCard : NSObject

@property (nonatomic) NSString *card;
@property (nonatomic) NSString *csc;
@property(nonatomic) NSString *expirationDateMMYY;
@property(nonatomic) NSString *softwareType;
@property(nonatomic) NSString *softwareTypeVersion;

- (NSString*) asJson;
- (NSDictionary*) asDictionary;

@end
