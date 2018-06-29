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
@end

@implementation ClearentClockConfigurator_Tests

- (void)setUp {
    [super setUp];
    //TODO figure out how to mock the idtech singleton if we want to test the initClock method
     self.clearentClockConfigurator = [[ClearentClockConfigurator alloc] initWithIdtechSharedController:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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
