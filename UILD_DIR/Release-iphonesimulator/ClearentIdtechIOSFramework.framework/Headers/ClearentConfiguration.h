//
//  ClearentConfiguration.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/25/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearentConfiguration : NSObject

    @property (assign, getter=isValid) BOOL valid;
    @property(nonatomic) NSDictionary *rawJson;
    @property(nonatomic) NSDictionary *contactAids;
    @property(nonatomic) NSDictionary *publicKeys;

    - (id) initWithJson: (NSDictionary*) rawJson;

@end
