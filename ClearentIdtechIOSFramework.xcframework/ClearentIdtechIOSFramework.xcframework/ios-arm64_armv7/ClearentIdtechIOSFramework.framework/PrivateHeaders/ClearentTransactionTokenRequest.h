//
//  ClearentTransactionTokenRequest.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//.

#import <Foundation/Foundation.h>

@interface ClearentTransactionTokenRequest : NSObject

    @property (nonatomic) NSString *tlv;
    @property (nonatomic) BOOL encrypted;
    @property (nonatomic) BOOL emv;
    @property (nonatomic) NSString *firmwareVersion;
    @property(nonatomic) NSString *deviceSerialNumber;
    @property(nonatomic) NSString *kernelVersion;
    @property(nonatomic) NSString *track2Data;
    @property(nonatomic) NSString *maskedTrack2Data;
    @property(nonatomic) NSString *ksn;
    @property(nonatomic) NSString *applicationPreferredNameTag9F12;

    - (NSString*) asJson;
    - (NSDictionary*) asDictionary;

@end
