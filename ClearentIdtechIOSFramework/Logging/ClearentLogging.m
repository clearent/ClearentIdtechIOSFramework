//
//  ClearentLogging.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentLogging.h"

@implementation ClearentLogging

- (NSDictionary*) asDictionary {
    return @{@"created-date":self.createdDate,@"level":self.level,@"message":self.message};
}

- (NSString*) asJson {
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:0 error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

@end

