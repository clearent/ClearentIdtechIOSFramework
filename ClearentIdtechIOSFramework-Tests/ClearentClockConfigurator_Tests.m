//
//  ClearentClockConfigurator_Tests.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 6/28/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ClearentIdtechIOSFramework/ClearentIdtechIOSFramework.h"
#import "ClearentClockConfigurator.h"

@interface ClearentClockConfigurator_Tests : XCTestCase
@property (nonatomic) ClearentClockConfigurator *clearentClockConfigurator;
@property (nonatomic) IDT_VP3300 *sharedController;
@end

@implementation ClearentClockConfigurator_Tests

- (void)setUp {
    [super setUp];
     self.clearentClockConfigurator = [[ClearentClockConfigurator alloc] initWithIdtechSharedController:nil];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testShouldGetClockDateAsYYYYMMDD {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *nowYYYYMMDD = [NSString stringWithFormat:@"%@%@%@", @"<", [dateFormatter stringFromDate:now], @">"] ;
    
    NSData *clockDateYYYYMMDD = [self.clearentClockConfigurator getClockDateAsYYYYMMDD];
    XCTAssertNotNil(clockDateYYYYMMDD);
    XCTAssertEqualObjects([clockDateYYYYMMDD description], nowYYYYMMDD);
}

- (void) testShouldGetClockTimeAsHHMM {
    NSData *clockTimeHHMM = [self.clearentClockConfigurator getClockTimeAsHHMM];
    XCTAssertNotNil(clockTimeHHMM);
}


@end
