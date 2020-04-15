//
//  ClearentFeedback.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/27/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import "ClearentFeedback.h"

@implementation ClearentFeedback


- (instancetype) initBluetooth:(NSString *)message {
    self = [super init];
       if (self) {
           
           self.message = message;
           self.feedBackMessageType = FEEDBACK_BLUETOOTH;
           self.returnCode = 0;

       }
       return self;
}


- (instancetype) initUserAction:(NSString *)message {
   self = [super init];
    if (self) {
        
        self.message = message;
        self.feedBackMessageType = FEEDBACK_BLUETOOTH;
        self.returnCode = 0;

    }
    return self;
}

- (instancetype) initInfo:(NSString *)message {
   self = [super init];
    if (self) {
        
        self.message = message;
        self.feedBackMessageType = FEEDBACK_INFO;
        self.returnCode = 0;

    }
    return self;
}

@end
