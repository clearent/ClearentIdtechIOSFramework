//
//  ClearentConfiguration.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConfiguration.h"

@implementation ClearentConfiguration

- (instancetype) initWithJson: (NSDictionary*) rawJson {
    self = [super init];
    if (self) {
        self.rawJson = rawJson;
        self.valid = NO;
        [self initFromJson];
    }
    return self;
}

- (void) initFromJson {
    if(self.rawJson == nil) {
        return;
    }
    NSDictionary *payload = [self.rawJson objectForKey:@"payload"];
    if(payload == nil) {
        return;
    }
    NSDictionary *mobileDevice = [payload objectForKey:@"mobile-device"];
    if(mobileDevice == nil) {
        return;
    }
    self.contactAids = [mobileDevice objectForKey:@"contact-aids"];
    if(self.contactAids == nil) {
        return;
    }
    
    self.publicKeys = [mobileDevice objectForKey:@"ca-public-keys"];
    if(self.publicKeys == nil) {
        return;
    }
    self.contactlessPublicKeys = [mobileDevice objectForKey:@"contactless-ca-public-keys"];
    self.contactlessGroups = [mobileDevice objectForKey:@"idtech-contactless-groups"];
    self.contactlessSupportedAids = [mobileDevice objectForKey:@"idtech-contactless-supported-aids"];
    self.contactlessAids = [mobileDevice objectForKey:@"idtech-contactless-aids"];
    
    self.valid = YES;
}

@end


