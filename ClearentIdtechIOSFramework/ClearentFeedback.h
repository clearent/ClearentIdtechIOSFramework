//
//  ClearentFeedback.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/27/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FEEDBACK_MESSAGE_TYPE) {
    FEEDBACK_USER_ACTION = 0,
    FEEDBACK_INFO = 1,
    FEEDBACK_BLUETOOTH = 2,
    FEEDBACK_TYPE_UNKNOWN = NSUIntegerMax
};

@protocol ClearentFeedback <NSObject>

- (NSString*) message;
- (FEEDBACK_MESSAGE_TYPE*) feedBackMessageType;
- (int) returnCode;

@end

@interface ClearentFeedback: NSObject <ClearentFeedback>
@property (nonatomic) NSString *message;
@property (nonatomic) FEEDBACK_MESSAGE_TYPE feedBackMessageType;
@property (nonatomic) int returnCode;

- (instancetype) initBluetooth:(NSString*) message;
- (instancetype) initUserAction:(NSString*) message;
- (instancetype) initInfo:(NSString*) message;
@end
