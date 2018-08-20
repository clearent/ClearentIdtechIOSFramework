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
    CLOCK_FAILED,
}CLOCK_CONFIGURATION_ERROR_CODE;

@interface ClearentClockConfigurator : NSObject

    @property (nonatomic) IDT_VP3300 *sharedController;

    - (id)initWithIdtechSharedController:(IDT_VP3300*) sharedController;
    - (int) initClock;
    - (NSData*) getClockDateAsYYYYMMDD;
    - (NSData*) getClockTimeAsHHMM;

@end

