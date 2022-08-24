//
//  ClearentVP3300Config.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/26/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import "ClearentVP3300Config.h"

@implementation ClearentVP3300Config : NSObject

- (instancetype) initContactlessNoConfiguration:(NSString*) baseUrl publicKey:(NSString*) publicKey {
    
    self = [super init];
    
    if (self) {
        
        self.clearentBaseUrl = baseUrl;
        self.publicKey = publicKey;
        self.contactAutoConfiguration = false;
        self.contactlessAutoConfiguration = false;
        self.contactless = true;
        self.disableRemoteLogging = false;
        self.enableEnhancedFeedback = false;
        
    }
    
    return self;
}

- (instancetype) initNoContactlessNoConfiguration:(NSString*) baseUrl publicKey:(NSString*) publicKey {
    
    self = [super init];
    
    if (self) {
        
        self.clearentBaseUrl = baseUrl;
        self.publicKey = publicKey;
        self.contactAutoConfiguration = false;
        self.contactlessAutoConfiguration = false;
        self.contactless = false;
        self.disableRemoteLogging = false;
        self.enableEnhancedFeedback = false;
        
    }
    
    return self;
}

- (instancetype) initEnableContactlessAndEnhancedFeedback:(NSString*) baseUrl publicKey:(NSString*) publicKey {
    
    self = [super init];
    
    if (self) {
        
        self.clearentBaseUrl = baseUrl;
        self.publicKey = publicKey;
        self.contactAutoConfiguration = false;
        self.contactlessAutoConfiguration = false;
        self.contactless = true;
        self.disableRemoteLogging = false;
        self.enableEnhancedFeedback = true;
        
    }
    
    return self;
}

@end
