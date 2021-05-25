//
//  ClearentCard.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 1/21/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import "ClearentCard.h"

@implementation ClearentCard

- (NSDictionary*) asDictionary {
    NSDictionary* dict;
    if(self.softwareType == nil) {
        self.softwareType = @"ClearentIdtechIOSFramework";
    }
    if(self.softwareTypeVersion == nil) {
        self.softwareTypeVersion = @"v2.1.0";
    }
    
    if(self.csc != nil) {
        dict = @{@"card":self.card,@"exp-date":self.expirationDateMMYY,@"csc":self.csc,@"software-type":self.softwareType,@"software-type-version":self.softwareTypeVersion};
    } else {
        dict = @{@"card":self.card,@"exp-date":self.expirationDateMMYY,@"software-type":self.softwareType,@"software-type-version":self.softwareTypeVersion};
    }
    return dict;
}

- (NSString*) asJson {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.asDictionary
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

@end

