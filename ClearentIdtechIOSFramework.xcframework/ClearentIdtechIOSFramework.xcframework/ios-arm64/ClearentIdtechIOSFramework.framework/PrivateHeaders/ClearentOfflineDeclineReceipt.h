//
//  ClearentOfflineDeclineReceipt.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 8/13/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentOfflineDeclineReceipt : NSObject

@property (nonatomic) NSString *tlv;
@property (nonatomic) NSString *firmwareVersion;
@property(nonatomic) NSString *deviceSerialNumber;
@property(nonatomic) NSString *kernelVersion;
@property(nonatomic) NSString *maskedTrack2Data;
@property(nonatomic) NSString *emailAddress;
@property(nonatomic) NSString *applicationPreferredNameTag9F12;
@property (nonatomic) NSString *amount;

- (NSString*) asJson;
- (NSDictionary*) asDictionary;

@end
