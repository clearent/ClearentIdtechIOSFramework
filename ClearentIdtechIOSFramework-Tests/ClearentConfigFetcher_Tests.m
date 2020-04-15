//
//  ClearentConfigFetcher_Tests.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 6/29/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClearentIdtechIOSFramework/ClearentConfigFetcher.h>
#import <OCMock/OCMock.h>

@interface ClearentConfigFetcher_Tests : XCTestCase

@end

@implementation ClearentConfigFetcher_Tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}
//
//- (void)useOHHTTPStubsToMockNetworkCall {
//
//    NSDictionary *sampleJson = [self getSampleJson:@"ClearentConfiguration"];
//    ClearentConfigFetcher *clearentConfigFetcher = [[ClearentConfigFetcher alloc] init:mockSession baseUrl:@"baseUrl" deviceSerialNumber:@"d1234567891" kernelVersion:@"kernelVersion" publicKey:@"publicKey"];
//
//    ClearentConfigFetcherResponse mockBlock = ^(NSDictionary *json) {
//        XCTAssertNotNil(json);
//    };
//
//    [clearentConfigFetcher fetchConfiguration: mockBlock];
//
//}


- (void) testShouldCreateValidHttpRequest {

    ClearentConfigFetcher *clearentConfigFetcher = [[ClearentConfigFetcher alloc] init:[NSURLSession sharedSession] baseUrl:@"baseUrl" deviceSerialNumber:@"d1234567891" kernelVersion:@"kernelVersion" publicKey:@"publicKeyTest123"];

    NSMutableURLRequest *nsMutableUrlRequest = [clearentConfigFetcher createNSMutableURLRequest];

    NSDictionary *allHeaders = [nsMutableUrlRequest allHTTPHeaderFields];
    XCTAssertEqualObjects(@"application/json", [allHeaders objectForKey:@"Accept"]);
    XCTAssertEqualObjects(@"publicKeyTest123", [allHeaders objectForKey:@"public-key"]);
    NSString *url = [[nsMutableUrlRequest URL] absoluteString] ;
    XCTAssertEqualObjects(@"baseUrl/rest/v2/mobile/devices/d123456789/kernelVersion", url);
    NSString *httpMethod = [nsMutableUrlRequest HTTPMethod];
    XCTAssertEqualObjects(@"GET", httpMethod);
}

- (void) testShouldCreateValidUrl {
    ClearentConfigFetcher *clearentConfigFetcher = [[ClearentConfigFetcher alloc] init:[NSURLSession sharedSession] baseUrl:@"baseUrl" deviceSerialNumber:@"T1234567891111111" kernelVersion:@"kernelVersion" publicKey:@"publicKeyTest123"];
    NSString *url = [clearentConfigFetcher createTargetUrl] ;
    XCTAssertEqualObjects(@"baseUrl/rest/v2/mobile/devices/T123456789/kernelVersion", url);
}

- (NSDictionary*) getSampleJson:(NSString*) fileName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *filepath = [bundle pathForResource:fileName ofType:@"json"];
    NSError *error;
    NSString *jsonStr = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertFalse(error);
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    XCTAssertFalse(error);
    return jsonDic;
}

@end
