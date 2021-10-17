//
//  ClearentLumberjackRemoteLogger.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 10/17/21.
//  Copyright © 2021 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDAbstractDatabaseLogger.h>

@interface ClearentLumberjackRemoteLogger : DDAbstractDatabaseLogger

    @property (nonatomic, strong) NSString *baseUrl;

    @property (nonatomic, strong) NSString *publicKey;

@end
