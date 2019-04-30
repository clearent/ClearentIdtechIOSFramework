//
//  ClearentLoggingRequest.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentLoggingRequest.h"
#import "ClearentUtils.h"

@implementation ClearentLoggingRequest

- (NSDictionary*) asDictionary {
    NSDictionary* hostProfileData = [ClearentUtils hostProfileData];
    NSDictionary* dict = @{@"device-serial-number":self.deviceSerialNumber,@"loggings":self.logging,@"host-profile":hostProfileData};
    return dict;
}

- (NSString*) asJson {
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:0 error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

@end
