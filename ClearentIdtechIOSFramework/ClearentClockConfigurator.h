//
//  ClearentClockConfigurator.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 6/22/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDTech/IDT_VP3300.h"
#import "IDTech/IDTUtility.h"

typedef enum{
    CLOCK_CONFIGURATION_SUCCESS,
    TIME_FAILED,
    DATE_FAILED,
}CLOCK_CONFIGURATION_ERROR_CODE;

@interface ClearentClockConfigurator : NSObject
+ (int) initClockDate;
+ (int) initClockTime;
@end

