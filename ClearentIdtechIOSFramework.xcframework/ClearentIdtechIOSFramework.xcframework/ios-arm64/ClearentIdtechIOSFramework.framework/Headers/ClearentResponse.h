//
//  ClearentResponse.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/30/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RESPONSE_TYPE) {
    RESPONSE_SUCCESS = 0,
    RESPONSE_FAIL = 1,
    RESPONSE_TYPE_UNKNOWN = NSUIntegerMax
};

@protocol ClearentResponse <NSObject>

- (NSString*) response;
- (RESPONSE_TYPE*) responseType;
- (int) idtechReturnCode;

@end

@interface ClearentResponse: NSObject <ClearentResponse>
@property (nonatomic) NSString *response;
@property (nonatomic) RESPONSE_TYPE responseType;
@property (nonatomic) int idtechReturnCode;
@end

