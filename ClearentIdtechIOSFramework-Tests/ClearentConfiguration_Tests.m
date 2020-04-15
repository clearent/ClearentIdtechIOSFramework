//
//  ClearentConfiguration.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 6/27/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClearentIdtechIOSFramework/ClearentConfiguration.h>


@interface ClearentConfiguration_Tests : XCTestCase
@property (nonatomic) ClearentConfiguration *clearentConfiguration;
@end

@implementation ClearentConfiguration_Tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void) testShouldHandleNilOnInit {
    self.clearentConfiguration = [[ClearentConfiguration alloc] initWithJson:nil];
    XCTAssertNil(self.clearentConfiguration.rawJson);
    XCTAssertFalse(self.clearentConfiguration.isValid);
}

- (void) testShouldIdentifyAsValidWhenInitializedCorrectlyWithJson {
    [self initWithSampleJson:@"ClearentConfiguration"];
    XCTAssertTrue(self.clearentConfiguration.isValid);
}

- (void) testShouldRequireContactAidsToBeConsideredValid {
    [self initWithSampleJson:@"ClearentConfiguration"];
    XCTAssertNotNil(self.clearentConfiguration.contactAids);
    XCTAssertTrue(self.clearentConfiguration.isValid);
}

- (void) testShouldbeInvalidIfNoContactAids {
    [self initWithSampleJson:@"ClearentConfigNoContactAids"];
    XCTAssertNil(self.clearentConfiguration.contactAids);
    XCTAssertFalse(self.clearentConfiguration.isValid);
}

- (void) testShouldRequirePublicKeysToBeConsideredValid {
    [self initWithSampleJson:@"ClearentConfiguration"];
    XCTAssertNotNil(self.clearentConfiguration.publicKeys);
    XCTAssertTrue(self.clearentConfiguration.isValid);
}

- (void) testShouldbeInvalidIfNoPublicKeys {
    [self initWithSampleJson:@"ClearentConfigNoPublicKeys"];
    XCTAssertNil(self.clearentConfiguration.publicKeys);
    XCTAssertFalse(self.clearentConfiguration.isValid);
}

- (void) initWithSampleJson:(NSString*) fileName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *filepath = [bundle pathForResource:fileName ofType:@"json"];
    NSError *error;
    NSString *jsonStr = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertFalse(error);
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    XCTAssertFalse(error);
    self.clearentConfiguration = [[ClearentConfiguration alloc] initWithJson:jsonDic];
    XCTAssertNotNil(self.clearentConfiguration.rawJson);
}

@end
