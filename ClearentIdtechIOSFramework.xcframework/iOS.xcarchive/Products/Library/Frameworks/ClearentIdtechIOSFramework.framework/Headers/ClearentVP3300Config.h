//
//  ClearentVP3300Config.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/26/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import "ClearentVP3300Configuration.h"

@interface ClearentVP3300Config: NSObject <ClearentVP3300Configuration>
@property (nonatomic) NSString* clearentBaseUrl;
@property (nonatomic) NSString* publicKey;
@property (nonatomic) BOOL contactAutoConfiguration;
@property (nonatomic) BOOL contactlessAutoConfiguration;
@property (nonatomic) BOOL contactless;
@property (nonatomic) BOOL disableRemoteLogging;
@property (nonatomic) BOOL enableEnhancedFeedback;

- (instancetype) initContactlessNoConfiguration:(NSString*) baseUrl publicKey:(NSString*) publicKey;

- (instancetype) initNoContactlessNoConfiguration:(NSString*) baseUrl publicKey:(NSString*) publicKey;

- (instancetype) initEnableContactlessAndEnhancedFeedback:(NSString*) baseUrl publicKey:(NSString*) publicKey;

@end

