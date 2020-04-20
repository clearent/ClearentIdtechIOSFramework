//
//  ClearentFeedback_Tests.m
//  ClearentIdtechIOSFramework-Tests
//
//  Created by David Higginbotham on 4/20/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ClearentIdtechIOSFramework/ClearentFeedback.h>

@interface ClearentFeedback_Tests : XCTestCase

@end

@implementation ClearentFeedback_Tests


- (void) testFeedbackUnknown {
    
    ClearentFeedback *clearentFeedback = [ClearentFeedback createFeedback:@"Unknown"];

    XCTAssertEqualObjects(@"Unknown", clearentFeedback.message);
    XCTAssertTrue(clearentFeedback.feedBackMessageType == CLEARENT_FEEDBACK_INFO);
   
}

- (void) testFeedbackBluetooth {
    
    ClearentFeedback *clearentFeedback = [ClearentFeedback createFeedback:@"BLUETOOTH CONNECTED"];

    XCTAssertEqualObjects(@"BLUETOOTH CONNECTED", clearentFeedback.message);
    XCTAssertTrue(clearentFeedback.feedBackMessageType == CLEARENT_FEEDBACK_BLUETOOTH);
   
}


- (void) testFeedbackError {
    
    ClearentFeedback *clearentFeedback = [ClearentFeedback createFeedback:CLEARENT_FAILED_TO_SEND_DECLINE_RECEIPT];

    XCTAssertEqualObjects(CLEARENT_FAILED_TO_SEND_DECLINE_RECEIPT, clearentFeedback.message);
    XCTAssertTrue(clearentFeedback.feedBackMessageType == CLEARENT_FEEDBACK_ERROR);
   
}

- (void) testFeedbackInfo {
    
    ClearentFeedback *clearentFeedback = [ClearentFeedback createFeedback:CLEARENT_AUDIO_JACK_DISCONNECTED];

    XCTAssertEqualObjects(CLEARENT_AUDIO_JACK_DISCONNECTED, clearentFeedback.message);
    XCTAssertTrue(clearentFeedback.feedBackMessageType == CLEARENT_FEEDBACK_INFO);
   
}

@end

