//
//  ClearentFeedback.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/27/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import "ClearentFeedback.h"

@implementation ClearentFeedback

NSString *const CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE = @"Card read error";
NSString *const CLEARENT_USE_CHIP_READER = @"USE CHIP READER";
NSString *const CLEARENT_CVM_UNSUPPORTED = @"CVM Unsupported. Insert card with chip first, then start transaction. Or try swipe.";
NSString *const CLEARENT_CONTACTLESS_UNSUPPORTED = @"Contactless not supported. Insert card with chip first, then start transaction.";
NSString *const CLEARENT_MSD_CONTACTLESS_UNSUPPORTED = @"This type (MSD) of contactless is not supported. Insert card with chip first, then start transaction.";

NSString *const CLEARENT_USER_ACTION_SWIPE_FAIL_TRY_INSERT_OR_SWIPE = @"FAILED TO READ CARD. TRY INSERT/SWIPE";
NSString *const CLEARENT_BLUETOOTH_CONNECTED = @"BLUETOOTH CONNECTED";
NSString *const CLEARENT_BLUETOOTH_SEARCH = @"SEARCHING FOR POWERED ON BLUETOOTH READERS";
NSString *const CLEARENT_PLUGIN_AUDIO_JACK = @"PLUGIN AUDIO JACK";
NSString *const CLEARENT_NEW_BLUETOOTH_CONNECTION_REQUESTED = @"NEW BLUETOOTH CONNECTION REQUESTED. DISCONNECT CURRENT BLUETOOTH";
NSString *const CLEARENT_DISCONNECTING_BLUETOOTH_PLUGIN_AUDIO_JACK = @"DISCONNECTING BLUETOOTH. PLUG IN AUDIO JACK";
NSString *const CLEARENT_UNPLUG_AUDIO_JACK_BEFORE_CONNECTING_TO_BLUETOOTH = @"UNPLUG AUDIO JACK BEFORE CONNECTING TO BLUETOOTH";
NSString *const CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE = @"PRESS BUTTON ON READER";
NSString *const CLEARENT_USER_ACTION_3_IN_1_MESSAGE = @"PLEASE SWIPE, TAP, OR INSERT";
NSString *const CLEARENT_USER_ACTION_2_IN_1_MESSAGE = @"INSERT/SWIPE CARD";
NSString *const CLEARENT_CARD_OFFLINE_DECLINED = @"Card declined";
NSString *const CLEARENT_FALLBACK_TO_SWIPE_REQUEST = @"FALLBACK_TO_SWIPE_REQUEST";
NSString *const CLEARENT_TIMEOUT_ERROR_RESPONSE = @"TIME OUT";
NSString *const CLEARENT_TIMEOUT_ERROR_RESPONSE2 = @"TIMEOUT";
NSString *const CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE = @"Create Transaction Token Failed";
NSString *const CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE = @"Sending Declined Receipt Failed";
NSString *const CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE = @"CARD SECURED";
NSString *const CLEARENT_CARD_READ_OK_TO_REMOVE_CARD = @"CARD READ OK, REMOVE CARD";
NSString *const CLEARENT_TRANSLATING_CARD_TO_TOKEN = @"GOING ONLINE";
NSString *const CLEARENT_SUCCESSFUL_DECLINE_RECEIPT_MESSAGE = @"DECLINED RECEIPT SENT, REMOVE CARD";
NSString *const CLEARENT_FAILED_TO_READ_CARD_ERROR_RESPONSE = @"Failed to read card";
NSString *const CLEARENT_INVALID_FIRMWARE_VERSION = @"Device Firmware version not found";
NSString *const CLEARENT_INVALID_KERNEL_VERSION = @"Device Kernel Version Unknown";

NSString *const CLEARENT_READER_CONFIGURED_MESSAGE = @"Reader configured and ready";

NSString *const CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION = @"DISABLE CONFIGURATION REQUEST TO RUN TRANSACTION";
NSString *const CLEARENT_READER_IS_NOT_CONFIGURED = @"READER NOT CONFIGURED";
NSString *const CLEARENT_DEVICE_NOT_CONNECTED = @"DEVICE NOT CONNECTED";
NSString *const CLEARENT_REQUIRED_TRANSACTION_REQUEST_RESPONSE = @"PAYMENT REQUEST AND CONNECTION REQUIRED";
NSString *const CLEARENT_RESPONSE_TRANSACTION_STARTED = @"TRANSACTION STARTED";
NSString *const CLEARENT_RESPONSE_TRANSACTION_FAILED = @"TRANSACTION FAILED";
NSString *const CLEARENT_RESPONSE_INVALID_TRANSACTION = @"INVALID TRANSACTION";
NSString *const CLEARENT_UNABLE_TO_GO_ONLINE = @"UNABLE TO GO ONLINE";
NSString *const CLEARENT_GENERIC_CONTACTLESS_FAILED = @"TAP FAILED";
NSString *const CLEARENT_CONTACTLESS_FALLBACK_MESSAGE = @"TAP FAILED. INSERT/SWIPE";
NSString *const CLEARENT_CONTACTLESS_RETRY_MESSAGE = @"RETRY TAP";
NSString *const CLEARENT_CHIP_FOUND_ON_SWIPE = @"CARD HAS CHIP. TRY INSERT";
NSString *const CLEARENT_AUDIO_JACK_ATTACHED = @"AUDIO JACK ATTACHED";
NSString *const CLEARENT_AUDIO_JACK_CONNECTED = @"AUDIO JACK CONNECTED";
NSString *const CLEARENT_AUDIO_JACK_LOW_VOLUME = @"AUDIO JACK LOW VOLUME. TURN UP VOLUME AND RECONNECT";
NSString *const CLEARENT_CONNECTING_AUDIO_JACK = @"CONNECTING AUDIO JACK";
NSString *const CLEARENT_AUDIO_JACK_REMOVED = @"AUDIO JACK REMOVED";
NSString *const CLEARENT_PAYMENT_REQUEST_NOT_FOUND = @"PAYMENT REQUEST NOT FOUND";
NSString *const CLEARENT_PLEASE_WAIT = @"PLEASE WAIT...";
NSString *const CLEARENT_TRANSACTION_PROCESSING = @"PROCESSING...";
NSString *const CLEARENT_TRANSACTION_AUTHORIZING = @"AUTHORIZING...";
NSString *const CLEARENT_BLUETOOTH_FRIENDLY_NAME_REQUIRED = @"Bluetooth friendly name required";
NSString *const CLEARENT_TRANSACTION_TERMINATED = @"TERMINATED";
NSString *const CLEARENT_TRANSACTION_TERMINATE = @"TERMINATE";
NSString *const CLEARENT_USE_MAGSTRIPE = @"USE MAGSTRIPE";
NSString *const CLEARENT_DEVICE_CONNECTED_WAITING_FOR_CONFIG = @"Device connected. Waiting for configuration to complete...";
NSString *const CLEARENT_BLUETOOTH_DISCONNECTED = @"BLUETOOTH DISCONNECTED";
NSString *const CLEARENT_AUDIO_JACK_DISCONNECTED = @"AUDIO JACK DISCONNECTED";
NSString *const CLEARENT_POWERING_UP = @"Powering up reader...";
NSString *const CLEARENT_TAP_PRESENT_ONE_CARD_ONLY = @"PRESENT ONE CARD ONLY";
NSString *const CLEARENT_CARD_BLOCKED = @"CARD BLOCKED";
NSString *const CLEARENT_CARD_EXPIRED = @"CARD EXPIRED";
NSString *const CLEARENT_CARD_UNSUPPORTED = @"CARD UNSUPPORTED";
NSString *const CLEARENT_TAP_FAILED_INSERT_SWIPE = @"TAP FAILED. INSERT/SWIPE";
NSString *const CLEARENT_TAP_OVER_MAX_AMOUNT = @"AMOUNT IS OVER MAXIMUM LIMIT ALLOWED FOR TAP.";
NSString *const CLEARENT_TAP_FAILED_INSERT_CARD_FIRST = @"TAP FAILED. INSERT CHIP CARD FIRST BEFORE TRYING AGAIN. IF PHONE TRY AGAIN OR ASK FOR CARD.";
NSString *const CLEARENT_CHIP_UNRECOGNIZED = @"CHIP NOT RECOGNIZED, PULL CARD OUT, WAIT FOR GREEN LED, TRY SWIPE";
NSString *const CLEARENT_BAD_CHIP = @"BAD CHIP, PULL CARD OUT, WAIT FOR GREEN LED, TRY SWIPE";
NSString *const CLEARENT_FAILED_TO_SEND_DECLINE_RECEIPT = @"UNABLE TO GO ONLINE, FAILED TO SEND DECLINED RECEIPT";
NSString *const CLEARENT_PULLED_CARD_OUT_EARLY = @"FAILED TO START SWIPE. TRY AGAIN BUT THIS TIME PULL CARD OUT WHEN INSTRUCTED";
NSString *const CLEARENT_CONNECTION_TYPE_REQUIRED = @"CONNECTION TYPE REQUIRED";
NSString *const CLEARENT_CONNECTION_PROPERTIES_REQUIRED = @"CONNECTION PROPERTIES REQUIRED";
NSString *const CLEARENT_TRY_ICC_AGAIN = @"TRY ICC AGAIN";
NSString *const CLEARENT_INSERT_CARD = @"INSERT CARD";
NSString *const CLEARENT_TRY_MSR_AGAIN = @"TRY MSR AGAIN";
NSString *const CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR = @"TIMEOUT";
NSString *const CLEARENT_CARD_INSERTED = @"CARD INSERTED";
NSString *const CLEARENT_CARD_READ_SUCCESS = @"CARD READ OK";
NSString *const CLEARENT_CARD_READ_ERROR = @"CARD READ ERROR";
NSString *const CLEARENT_SEE_PHONE = @"SEE PHONE";
NSString *const CLEARENT_START_TRANSACTION_FAILED = @"TRANSACTION FAILED - MOVE CARD AWAY FROM READER AND TRY AGAIN";
NSString *const CLEARENT_START_TRANSACTION_FAILED_DISCONNECTED = @"Reader disconnected. Try again";
NSString *const CLEARENT_START_TRANSACTION_FAILED_INVALID_TRANSACTION = @"Invalid Transaction. Try again";
NSString *const CLEARENT_START_TRANSACTION_FAILED_MONO_ERROR = @"Transaction error. Use pin reset, then try again";
NSString *const CLEARENT_START_TRANSACTION_FAILED_EXISTING_TRANSACTION = @"Transaction failed. Existing Transaction. Try again";
NSString *const CLEARENT_START_TRANSACTION_FAILED_READER_OFF = @"Transaction timeout. Try again";
NSString *const CLEARENT_DISCONNECT_WHILE_TRANSACTION = @"Reader disconnected during transaction. Try again";

- (instancetype) initBluetooth:(NSString *)message {
    
    self = [super init];
    
    if (self) {
        
        self.message = message;
        self.feedBackMessageType = CLEARENT_FEEDBACK_BLUETOOTH;
        self.returnCode = 0;

    }
    
    return self;
}


- (instancetype) initUserAction:(NSString *)message {
    
    self = [super init];
    
    if (self) {
        
        self.message = message;
        self.feedBackMessageType = CLEARENT_FEEDBACK_BLUETOOTH;
        self.returnCode = 0;

    }
    
    return self;
}

- (instancetype) initInfo:(NSString *)message {
    
    self = [super init];
    
    if (self) {
        
      self.message = message;
      self.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
      self.returnCode = 0;

    }
    
    return self;
}

+ (NSDictionary*) feedbackValues {
    return @{
            CLEARENT_GENERIC_CARD_READ_ERROR_RESPONSE: [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_USE_CHIP_READER: [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CVM_UNSUPPORTED: [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_CONTACTLESS_UNSUPPORTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_MSD_CONTACTLESS_UNSUPPORTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_USER_ACTION_SWIPE_FAIL_TRY_INSERT_OR_SWIPE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_BLUETOOTH_CONNECTED: [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_BLUETOOTH_SEARCH: [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_PLUGIN_AUDIO_JACK: [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_NEW_BLUETOOTH_CONNECTION_REQUESTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_BLUETOOTH],
            CLEARENT_DISCONNECTING_BLUETOOTH_PLUGIN_AUDIO_JACK : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_UNPLUG_AUDIO_JACK_BEFORE_CONNECTING_TO_BLUETOOTH : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_USER_ACTION_3_IN_1_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_USER_ACTION_2_IN_1_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CARD_OFFLINE_DECLINED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_FALLBACK_TO_SWIPE_REQUEST : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_TIMEOUT_ERROR_RESPONSE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_TIMEOUT_ERROR_RESPONSE2 : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_GENERIC_DECLINE_RECEIPT_ERROR_RESPONSE: [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_SUCCESSFUL_TOKENIZATION_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_TRANSLATING_CARD_TO_TOKEN: [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_SUCCESSFUL_DECLINE_RECEIPT_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_FAILED_TO_READ_CARD_ERROR_RESPONSE: [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_INVALID_FIRMWARE_VERSION: [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_INVALID_KERNEL_VERSION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_READER_CONFIGURED_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_READER_IS_NOT_CONFIGURED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_DEVICE_NOT_CONNECTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_REQUIRED_TRANSACTION_REQUEST_RESPONSE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_RESPONSE_TRANSACTION_STARTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_RESPONSE_TRANSACTION_FAILED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_RESPONSE_INVALID_TRANSACTION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_UNABLE_TO_GO_ONLINE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_GENERIC_CONTACTLESS_FAILED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_CONTACTLESS_FALLBACK_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CONTACTLESS_RETRY_MESSAGE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CHIP_FOUND_ON_SWIPE: [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_AUDIO_JACK_ATTACHED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_AUDIO_JACK_CONNECTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_AUDIO_JACK_LOW_VOLUME : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CONNECTING_AUDIO_JACK : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_AUDIO_JACK_REMOVED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_PAYMENT_REQUEST_NOT_FOUND : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            //CLEARENT_PLEASE_WAIT : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            //CLEARENT_TRANSACTION_PROCESSING : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            //CLEARENT_TRANSACTION_AUTHORIZING: [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_BLUETOOTH_FRIENDLY_NAME_REQUIRED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_TRANSACTION_TERMINATED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_TRANSACTION_TERMINATE: [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_USE_MAGSTRIPE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_DEVICE_CONNECTED_WAITING_FOR_CONFIG : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_BLUETOOTH_DISCONNECTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_BLUETOOTH],
            CLEARENT_AUDIO_JACK_DISCONNECTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_POWERING_UP : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_TAP_PRESENT_ONE_CARD_ONLY : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CARD_BLOCKED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_CARD_EXPIRED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_CARD_UNSUPPORTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_TAP_FAILED_INSERT_SWIPE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_TAP_OVER_MAX_AMOUNT : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_TAP_FAILED_INSERT_CARD_FIRST : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CHIP_UNRECOGNIZED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_BAD_CHIP : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_FAILED_TO_SEND_DECLINE_RECEIPT : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_PULLED_CARD_OUT_EARLY : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_TRY_ICC_AGAIN : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_INSERT_CARD : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_TRY_MSR_AGAIN : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_TRANSACTION_FINAL_FALLBACK_ERROR : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_CARD_INSERTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CARD_READ_SUCCESS : [NSNumber numberWithInt:CLEARENT_FEEDBACK_INFO],
            CLEARENT_CARD_READ_ERROR : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_CARD_READ_OK_TO_REMOVE_CARD : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_SEE_PHONE : [NSNumber numberWithInt:CLEARENT_FEEDBACK_USER_ACTION],
            CLEARENT_START_TRANSACTION_FAILED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_DISCONNECT_WHILE_TRANSACTION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_START_TRANSACTION_FAILED_DISCONNECTED : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_START_TRANSACTION_FAILED_INVALID_TRANSACTION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_START_TRANSACTION_FAILED_MONO_ERROR : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_START_TRANSACTION_FAILED_EXISTING_TRANSACTION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_START_TRANSACTION_FAILED_READER_OFF : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR],
            CLEARENT_DISCONNECT_WHILE_TRANSACTION : [NSNumber numberWithInt:CLEARENT_FEEDBACK_ERROR]
        };
}

+ (ClearentFeedback*) createFeedback:(NSString*) message {
    
    ClearentFeedback *clearentFeedback = [[ClearentFeedback alloc] init];
    
    if(message != nil && ![message isEqualToString:@""]
       && ![message isEqualToString:@"TAP, OR INSERT"]
       && ![message isEqualToString:@"CARD"]
       && ![message containsString:@"Bluetooth LE is turned on"]) {
        
        NSString *feedbackMessage;
        
        if([message isEqualToString:@"INSERT/SWIPE"]) {
            feedbackMessage = CLEARENT_USER_ACTION_2_IN_1_MESSAGE;
        } else if([message isEqualToString:@"PLEASE SWIPE,"]) {
            feedbackMessage = CLEARENT_USER_ACTION_3_IN_1_MESSAGE;
        } else {
            feedbackMessage = message;
        }
        
        clearentFeedback.message = feedbackMessage;
        
        [self updateFeedbackType:clearentFeedback];
        
    } else {
        clearentFeedback.message = @"";
        clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
    }
    
    return clearentFeedback;
    
}

+ (void) updateFeedbackType: (ClearentFeedback*) clearentFeedback {

    if([ClearentFeedback feedbackValues] != nil && [[ClearentFeedback feedbackValues] count] > 0) {
        
        if([clearentFeedback.message containsString:@"PLEASE WAIT"]) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_USER_ACTION;
            clearentFeedback.message = @"PLEASE WAIT...";
            clearentFeedback.returnCode = 0;
            return;
        } else if([clearentFeedback.message containsString:@"PROCESSING"]) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
            clearentFeedback.returnCode = 0;
            clearentFeedback.message = @"PROCESSING...";
            return;
        } else if ([clearentFeedback.message containsString:@"AUTHORIZING"]) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
            clearentFeedback.returnCode = 0;
            clearentFeedback.message = @"AUTHORIZING...";
            return;
        }
            
        int feedbackMessageType = [[[ClearentFeedback feedbackValues] valueForKey:clearentFeedback.message] intValue];
        if(feedbackMessageType == 0 && ![clearentFeedback.message containsString:@"TAP FAILED"]) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_ERROR;
            clearentFeedback.returnCode = 0;
        } else if([clearentFeedback.message containsString:@"TAP FAILED"] || [clearentFeedback.message containsString:@"PLEASE WAIT"]) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_USER_ACTION;
            clearentFeedback.returnCode = 0;
        } else if([clearentFeedback.message containsString:@"PROCESSING"]) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
            clearentFeedback.returnCode = 0;
            clearentFeedback.message = @"PROCESSING...";
        } else if ([clearentFeedback.message containsString:@"AUTHORIZING"]) {
           clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
            clearentFeedback.returnCode = 0;
            clearentFeedback.message = @"AUTHORIZING...";
        } else if(feedbackMessageType == 1) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_USER_ACTION;
            clearentFeedback.returnCode = 0;
        } else if(feedbackMessageType == 2) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_INFO;
            clearentFeedback.returnCode = 0;
        } else if(feedbackMessageType == 3) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_BLUETOOTH;
            clearentFeedback.returnCode = 0;
        } else if(feedbackMessageType == 4) {
            clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_ERROR;
            clearentFeedback.returnCode = 9999999;
        }
    } else {
        clearentFeedback.feedBackMessageType = CLEARENT_FEEDBACK_TYPE_UNKNOWN;
        clearentFeedback.returnCode = 9999999;
    }
}

@end
