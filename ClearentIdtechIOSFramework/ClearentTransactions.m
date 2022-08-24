//
//  ClearentTransactions.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/2/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentTransactions.h"

#import "ClearentConnection.h"
#import "ClearentResponse.h"
#import "Clearent_VP3300.h"
#import "ClearentDelegate.h"
#import "ClearentLumberjack.h"
#import "ClearentDeviceConnector.h"
#import "ClearentUtils.h"

@implementation ClearentTransactions

- (instancetype) init: (ClearentDelegate*)clearentDelegate clearentVP3300:(Clearent_VP3300*) clearentVP3300 {
    
    self = [super init];
    
    if (self) {
        _clearentDelegate = clearentDelegate;
        _clearentVP3300 = clearentVP3300;
    }
    
    return self;
    
}

- (void) runTransaction {
    
    if(_clearentDelegate.clearentPayment != nil) {
        ClearentResponse *clearentResponse = [self startTransactionByReaderInterfaceMode:_clearentDelegate.clearentPayment clearentConnection:_clearentDelegate.clearentConnection];
    } else {
        [_clearentDelegate deviceMessage:CLEARENT_PAYMENT_REQUEST_NOT_FOUND];
    }
    
}

- (RETURN_CODE) startTransactionByReaderInterfaceMode: (CLEARENT_READER_INTERFACE_MODE) readerInterfaceMode {
    
    if(_clearentDelegate.clearentConnection.readerInterfaceMode == CLEARENT_READER_INTERFACE_2_IN_1) {
        return [self emv_startTransaction:_clearentDelegate.clearentPayment];
    } else {
        return [self device_startTransaction:_clearentDelegate.clearentPayment];
    }
    
}

-(RETURN_CODE) emv_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback {
    
    if([self isConfigurationRequested]) {
        [_clearentDelegate deviceMessage:CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION];
        return RETURN_CODE_CANNOT_START_CONTACT_EMV;
    }

    [self clearCurrentRequest];
    
    ClearentPayment *clearentPayment = [self createPaymentRequest:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline  fallback:fallback ];
    
    [_clearentDelegate setClearentPayment:clearentPayment];
    
    RETURN_CODE emvStartRt;
    
    if(![_clearentDelegate.idTechSharedInstance isConnected]) {
        
        [ClearentLumberjack logInfo:@"emv_startTransaction. Tried to start transaction but disconnected"];
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        emvStartRt = RETURN_CODE_ERR_DISCONNECT;
    
    } else {
        
        [_clearentDelegate.idTechSharedInstance emv_disableAutoAuthenticateTransaction:FALSE];
        [ClearentLumberjack logInfo:@"emv_startTransaction TRANSACTION_STARTED"];
        emvStartRt =  [_clearentDelegate.idTechSharedInstance emv_startTransaction:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline fallback:fallback];
        
    }
    
    return emvStartRt;
    
}

- (RETURN_CODE) ctls_startTransaction:(double)amount type:(int)type timeout:(int)timeout tags:(NSMutableDictionary *)tags {
    
    if([self isConfigurationRequested]) {
        [_clearentDelegate deviceMessage:CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION];
        return RETURN_CODE_CANNOT_START_CONTACT_EMV;
    }
    
    [self clearCurrentRequest];
    
    ClearentPayment *clearentPayment = [self createPaymentRequest:amount amtOther:0 type:type timeout:timeout tags:tags forceOnline:false  fallback:true ];
    
    [_clearentDelegate setClearentPayment:clearentPayment];
    
    RETURN_CODE ctlsStartRt;
    
    if(![_clearentDelegate.idTechSharedInstance isConnected]) {
        
        [ClearentLumberjack logInfo:@"ctls_startTransaction. Tried to start transaction but disconnected"];
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        ctlsStartRt = RETURN_CODE_ERR_DISCONNECT;
    
    } else {
        
         [ClearentLumberjack logInfo:@"ctls_startTransaction with vars TRANSACTION_STARTED"];
        ctlsStartRt =  [_clearentDelegate.idTechSharedInstance ctls_startTransaction:amount type:type timeout:timeout tags:tags];
        
    }
    
    return ctlsStartRt;
    
}

- (RETURN_CODE) ctls_cancelTransaction {
    
    [self clearCurrentRequest];
    
    return [_clearentDelegate.idTechSharedInstance ctls_cancelTransaction];
    
}

- (RETURN_CODE) ctls_startTransaction {
    
    [self clearCurrentRequest];
    
    RETURN_CODE ctlsStartRt;
    
    if([self isConfigurationRequested]) {
        
        [_clearentDelegate deviceMessage:CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION];
        
        ctlsStartRt = RETURN_CODE_CANNOT_START_CONTACT_EMV;
        
    } else if(![_clearentDelegate.idTechSharedInstance isConnected]) {
        
        [ClearentLumberjack logInfo:@"ctls_startTransaction no vars. Tried to start transaction but disconnected"];
        
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        
        ctlsStartRt = RETURN_CODE_ERR_DISCONNECT;
        
    } else {
        
        [ClearentLumberjack logInfo:@"ctls_startTransaction no vars TRANSACTION_STARTED"];
        
        ctlsStartRt =   [_clearentDelegate.idTechSharedInstance ctls_startTransaction];
        
    }
    
    return ctlsStartRt;
    
}

-(RETURN_CODE) emv_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest {
    
    RETURN_CODE emvStartRt;
    
    if([self isConfigurationRequested]) {
        
        [_clearentDelegate deviceMessage:CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION];
        
        emvStartRt = RETURN_CODE_CANNOT_START_CONTACT_EMV;
        
    } else if(![_clearentDelegate.idTechSharedInstance isConnected]) {
        
        [ClearentLumberjack logInfo:@"emv_startTransaction. Tried to start transaction but disconnected"];
        
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        
        emvStartRt = RETURN_CODE_ERR_DISCONNECT;
        
    } else {
        
        [_clearentDelegate.idTechSharedInstance emv_disableAutoAuthenticateTransaction:FALSE];
        
        [ClearentLumberjack logInfo:@"emv_startTransaction TRANSACTION_STARTED"];
        
        emvStartRt = [_clearentDelegate.idTechSharedInstance emv_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];
        
    }
    
    return emvStartRt;
    
}

-(ClearentResponse*) startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest clearentConnection:(ClearentConnection*) clearentConnection {
    
    ClearentResponse *clearentResponse;
   
    if(clearentPaymentRequest == nil || clearentConnection == nil) {
        
        clearentResponse = [self createRequiredTransactionRequestResponse];
        
    } else if([self isConfigurationRequested]) {
        
        clearentResponse = [self createConfigurationRequestResponse];
        
    } else {
        
        [self resetTransaction];
        
        [self updateConfiguration:clearentConnection];
        
        [_clearentDelegate setClearentPayment:clearentPaymentRequest];
        
        if(clearentConnection.connectionType == CLEARENT_AUDIO_JACK && ![_clearentVP3300 device_isAudioReaderConnected]) {
            
            clearentResponse = [self createAudioJackNotConnectedResponse];
            
        } else if([_clearentVP3300 device_isAudioReaderConnected] && clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            
            clearentResponse = [self createStillConnectedToAudioJackResponse];
            
        } else if(clearentConnection.connectionType == CLEARENT_AUDIO_JACK && [_clearentVP3300 device_isAudioReaderConnected]) {
            
            [_clearentDelegate setClearentConnection:clearentConnection];
            
            clearentResponse = [self startTransactionByReaderInterfaceMode:clearentPaymentRequest clearentConnection:clearentConnection];
            
        } else if([_clearentVP3300 isConnected] && ![_clearentDelegate.clearentDeviceConnector isNewConnectionRequest:_clearentDelegate.clearentConnection connectionRequest:clearentConnection]) {
            
            [_clearentDelegate setClearentConnection:clearentConnection];
            
            clearentResponse = [self startTransactionByReaderInterfaceMode:clearentPaymentRequest clearentConnection:clearentConnection];
            
        } else {
            
            clearentResponse = [self startTransactionAfterConnection:clearentConnection];
            
        }
    }
    
    if(clearentResponse.responseType == RESPONSE_FAIL) {
        
        [_clearentDelegate deviceMessage:clearentResponse.response];
        
    }
    
    return clearentResponse;
}

- (RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback {
    
    if ([self isConfigurationRequested]) {
        
        [_clearentDelegate deviceMessage:CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION];
        
        return RETURN_CODE_CANNOT_START_CONTACT_EMV;
        
    }
    
    [self clearCurrentRequest];
    
    ClearentPayment *clearentPayment = [self createPaymentRequest:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline  fallback:fallback ];
    
    [_clearentDelegate setClearentPayment:clearentPayment];
    
    return [self device_startTransaction:clearentPayment];
}

//- If the reader if OFF, but SDK thinks it still is connected, you will get a RETURN_CODE_NEO_TIMEOUT, RETURN_CODE_ERR_TIMEDOUT, RETURN_CODE_ERR_TIMEDOUT_
//RESOLUTION:  execute device_disconnectBLE (so SDK gets in sync with disconnected status), and then attempt to reconnect.  If you can reconnect, try transaction again.  If you can't reconnect, report disconnected error to customer.
- (BOOL) isConnectionError: (RETURN_CODE) idTechReturnCode {
    
    if(idTechReturnCode == RETURN_CODE_NEO_TIMEOUT
       || idTechReturnCode == RETURN_CODE_ERR_TIMEDOUT
       || idTechReturnCode == RETURN_CODE_ERR_TIMEDOUT_
       || idTechReturnCode == RETURN_CODE_NEO_TIMEOUT) {
        return YES;
    }
    
    return NO;
}

//- if device is not connected, and the SDK knows it is not connected, you will get back a RETURN_CODE_ERR_DISCONNECT, RETURN_CODE_ERR_DISCONNECT_,
   //RESOLUTION:  Attempt to reconnect.  If you can reconnect, try transaction again.  If you can't reconnect, report disconnected error to customer.
   //
- (BOOL) isDisconnected: (RETURN_CODE) idTechReturnCode {
    
    if(idTechReturnCode == RETURN_CODE_ERR_DISCONNECT
       || idTechReturnCode == RETURN_CODE_ERR_DISCONNECT_) {
        return YES;
    }
    
    return NO;
}

//- If the SDK believes there was a previous transasction already in progress that didn't finish yet, you will get back RETURN_CODE_SDK_BUSY_MSR_, RETURN_CODE_SDK_BUSY_CTLS_, RETURN_CODE_SDK_BUSY_EMV_,RETURN_CODE_SDK_BUSY_MSR,RETURN_CODE_SDK_BUSY_CTLS, RETURN_CODE_SDK_BUSY_CMD
   //RESOLUTION:  Execute device_cancelTranaction.  If successful cancel, try transaction again.  If unsuccessful, device_disconnectBLE, then attempt to reconnect and try again.  If you can't reconnect, report disconnected error to customer.
   //
- (BOOL) isPreviousTransactionInProgress: (RETURN_CODE) idTechReturnCode {
   
    if(idTechReturnCode == RETURN_CODE_SDK_BUSY_CTLS_
       || idTechReturnCode == RETURN_CODE_SDK_BUSY_EMV_
       || idTechReturnCode == RETURN_CODE_SDK_BUSY_MSR
       || idTechReturnCode == RETURN_CODE_SDK_BUSY_CTLS
       || idTechReturnCode == RETURN_CODE_SDK_BUSY_CMD) {
        return YES;
    }
    
    return NO;
}

- (BOOL) isTransactionStarted: (RETURN_CODE) idTechReturnCode {
    
    if(RETURN_CODE_OK_NEXT_COMMAND == idTechReturnCode || RETURN_CODE_DO_SUCCESS == idTechReturnCode || RETURN_CODE_DO_SUCCESS == idTechReturnCode || RETURN_CODE_NEO_SUCCESS == idTechReturnCode) {
        return YES;
    }
    return NO;
}

//- If you send invalid parameters, you will get back RETURN_CODE_ERR_INVALID_PARAMETER_, RETURN_CODE_ERR_INVALID_PARAMETER
//RESOLUTION:  Send correct parameters and try again
//
- (BOOL) isTransactionInvalid: (RETURN_CODE) idTechReturnCode {
    
    if(idTechReturnCode == RETURN_CODE_ERR_INVALID_PARAMETER_
       || idTechReturnCode == RETURN_CODE_ERR_INVALID_PARAMETER) {
        return YES;
    }
    
    return NO;
}

//- If there is a general or unknown failure, you will get back RETURN_CODE_ERR_OTHER_, RETURN_CODE_FAILED_,RETURN_CODE_ERR_OTHER, RETURN_CODE_FAILED
   //RESOLUTION:  Execute device_cancelTranaction.  If successful cancel, try transaction again.  If unsuccessful, device_disconnectBLE, then attempt to reconnect and try again.  If you can't reconnect, report disconnected error to customer.
   //
- (BOOL) isGeneralFailure: (RETURN_CODE) idTechReturnCode {
    
    if(idTechReturnCode == RETURN_CODE_ERR_OTHER_
       || idTechReturnCode == RETURN_CODE_FAILED_
       || idTechReturnCode == RETURN_CODE_ERR_OTHER
       || idTechReturnCode == RETURN_CODE_FAILED) {
        return YES;
    }
    
    return NO;
}

//- If the reader doesn't have terminal/aid files, you will get back a RETURN_CODE_DATA_DOES_NOT_EXIST
   //RESOLUTION:  load your configuration files and try transaction again
   //
- (BOOL) isBadConfiguration: (RETURN_CODE) idTechReturnCode {
    
    if(idTechReturnCode == RETURN_CODE_DATA_DOES_NOT_EXIST) {
        return YES;
    }
    
    return NO;
}

- (RETURN_CODE) device_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest {
    
    RETURN_CODE deviceStartRt;
    
    if([self isConfigurationRequested]) {
        
        [_clearentDelegate deviceMessage:CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION];
        
        deviceStartRt = RETURN_CODE_CANNOT_START_CONTACT_EMV;
        
    } else if(![_clearentDelegate.idTechSharedInstance isConnected]) {
        
        [ClearentLumberjack logInfo:@"device_startTransaction. Tried to start transaction but disconnected"];
        
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        
        deviceStartRt = RETURN_CODE_ERR_DISCONNECT;
        
    } else {
        
        [_clearentDelegate.idTechSharedInstance emv_disableAutoAuthenticateTransaction:FALSE];
        [_clearentDelegate setClearentPayment:clearentPaymentRequest];

        [self.clearentDelegate startFinalFeedbackMonitor:clearentPaymentRequest.timeout];
        //With a faster process there is a scenario where the idtech framework is still doing clean up activities from the previous transaction.
        //a slight delay can help.
        [NSThread sleepForTimeInterval:1.0f];
        deviceStartRt = [_clearentDelegate.idTechSharedInstance device_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];

    }
    
    return deviceStartRt;
    
}

-(RETURN_CODE) device_cancelTransaction {
    [self clearCurrentRequest];
    [_clearentDelegate resetTransaction];
    return [_clearentDelegate.idTechSharedInstance device_cancelTransaction];
}

- (RETURN_CODE) emv_cancelTransaction {
    [self clearCurrentRequest];
    return [_clearentDelegate.idTechSharedInstance emv_cancelTransaction];
}

- (void) clearCurrentRequest{
    [_clearentDelegate clearCurrentRequest];
}

- (ClearentPayment*) createPaymentRequest:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback {
    
    ClearentPayment *paymentRequest = [[ClearentPayment alloc] init];
    [paymentRequest setAmount:amount];
    paymentRequest.amtOther = amtOther;
    paymentRequest.type = type;
    paymentRequest.timeout = timeout;
    paymentRequest.tags = tags;
    paymentRequest.emailAddress = nil;
    paymentRequest.fallback = fallback;
    paymentRequest.forceOnline = forceOnline;
    
    return paymentRequest;
    
}

- (ClearentResponse*) createRequiredTransactionRequestResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    [ClearentLumberjack logInfo:@"createRequiredTransactionRequestResponse. payment request and connection required "];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = CLEARENT_REQUIRED_TRANSACTION_REQUEST_RESPONSE;
    clearentResponse.idtechReturnCode = RETURN_CODE_CANNOT_START_CONTACT_EMV;
    
    return clearentResponse;
    
}

- (ClearentResponse*) createConfigurationRequestResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    [ClearentLumberjack logInfo:@"createConfigurationRequestResponse. configuration is still enabled "];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION;
    clearentResponse.idtechReturnCode = RETURN_CODE_CANNOT_START_CONTACT_EMV;
    
    return clearentResponse;
    
}

- (ClearentResponse*) createStillConnectedToAudioJackResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    [ClearentLumberjack logInfo:@"createStillConnectedToAudioJackResponse. Still connected to audio jack but wants to connect to bluetooth"];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = CLEARENT_UNPLUG_AUDIO_JACK_BEFORE_CONNECTING_TO_BLUETOOTH;
    
    return clearentResponse;
    
}

- (ClearentResponse*) createAudioJackNotConnectedResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    [ClearentLumberjack logInfo:@"createStillConnectedToAudioJackResponse. audio jack is not connected"];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = @"AUDIO JACK NOT CONNECTED";
    
    return clearentResponse;
    
}

- (ClearentResponse*) startTransactionByReaderInterfaceMode: (id<ClearentPaymentRequest>) clearentPaymentRequest
clearentConnection:(ClearentConnection*) clearentConnection {
    
    [_clearentDelegate setClearentPayment:clearentPaymentRequest];

     ClearentResponse *clearentResponse;

     RETURN_CODE startTransactionReturnCode = [self startTransactionByReaderInterfaceMode:_clearentDelegate.clearentConnection.readerInterfaceMode];

     clearentResponse =  [self handleStartTransactionResult: startTransactionReturnCode];

     return clearentResponse;

}

- (ClearentResponse*) createFailedStartResponse {
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    clearentResponse.response = CLEARENT_START_TRANSACTION_FAILED;
    clearentResponse.responseType = RESPONSE_FAIL;
    return clearentResponse;
    
}

- (ClearentResponse*) createFailedStartResponse: (NSString*) responseMessage {
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    clearentResponse.response = responseMessage;
    clearentResponse.responseType = RESPONSE_FAIL;
    return clearentResponse;
}

- (ClearentResponse*) handleStartTransactionResult: (RETURN_CODE) startTransactionReturnCode  {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];

    clearentResponse.idtechReturnCode = startTransactionReturnCode;

    if([self isTransactionStarted:startTransactionReturnCode]) {
        clearentResponse.idtechReturnCode = startTransactionReturnCode;
        clearentResponse.response = CLEARENT_RESPONSE_TRANSACTION_STARTED;
        clearentResponse.responseType = RESPONSE_SUCCESS;
        [ClearentLumberjack logInfo:@"ℹ️ Transaction Started"];
    } else if([self isDisconnected:startTransactionReturnCode]) {

        clearentResponse = [self createFailedStartResponse:CLEARENT_START_TRANSACTION_FAILED_DISCONNECTED];

    } else if([self isTransactionInvalid:startTransactionReturnCode]) {

        clearentResponse = [self createFailedStartResponse:CLEARENT_START_TRANSACTION_FAILED_INVALID_TRANSACTION];

    } else if(RETURN_CODE_MONO_AUDIO_ == startTransactionReturnCode) {

        clearentResponse = [self createFailedStartResponse:CLEARENT_START_TRANSACTION_FAILED_MONO_ERROR];

    } else if([self isPreviousTransactionInProgress:startTransactionReturnCode]) {

        clearentResponse = [self createFailedStartResponse:CLEARENT_START_TRANSACTION_FAILED_EXISTING_TRANSACTION ];

    } else if([self isConnectionError:startTransactionReturnCode]) {

        clearentResponse = [self createFailedStartResponse:CLEARENT_START_TRANSACTION_FAILED_READER_OFF];

        [ClearentLumberjack logInfo:@"⚠️ device_startTransaction FAILED. possible state - If the reader if OFF, but SDK thinks it still is connected."];
    } else if([self isTransactionInvalid:startTransactionReturnCode]) {

        clearentResponse.response = CLEARENT_RESPONSE_INVALID_TRANSACTION;
        clearentResponse.responseType = RESPONSE_FAIL;

    }

    if(clearentResponse.response == nil) {

        clearentResponse.responseType = RESPONSE_FAIL;

        @try{
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"⚠️ We tried to account for known errors. Use device_getResponseCodeString method to identify device_startTransaction return code %d",startTransactionReturnCode]];
            NSString *deviceResponseCodeString = [_clearentDelegate.idTechSharedInstance device_getResponseCodeString:startTransactionReturnCode];
            if(deviceResponseCodeString != nil && ![deviceResponseCodeString isEqualToString:@""] && ![deviceResponseCodeString containsString:@"no error file found"]) {
                NSString *errorMessage = [NSString stringWithFormat:@"%@ - %@", CLEARENT_RESPONSE_TRANSACTION_FAILED, deviceResponseCodeString];
                clearentResponse.response = errorMessage;
            } else {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"⚠️ device_startTransaction return code not found with device_getResponseCodeString: = %d",startTransactionReturnCode]];
                NSString *errorMessage = [NSString stringWithFormat:@"%@ - %d", CLEARENT_RESPONSE_TRANSACTION_FAILED, startTransactionReturnCode];
                clearentResponse.response = errorMessage;
            }
        }
        @catch (NSException *e) {
            [ClearentLumberjack logInfo:@"Unknown Start Transaction Error Code "];
            clearentResponse.response = CLEARENT_RESPONSE_TRANSACTION_FAILED;
        }

    }

    if(clearentResponse != nil && clearentResponse.responseType == RESPONSE_FAIL) {
        [self device_cancelTransaction];
        [_clearentDelegate deviceMessage:clearentResponse.response];
    }

    return clearentResponse;
}

//We are attempting restart a transaction after forcing a bluetooth disconnect. This is a result of certain errors returned from the idtech framework when trying to start
//a transaction. The ClearentResponse in this scenario , in which we return a success, is only meant to stop the client's code from overreacting.
//If we successfully reconnect and restart the transaction or fail after retrying they will receive communication via the feedback method.
- (ClearentResponse*) retryTransactionAfterReconnectAttempt {
    
    [_clearentDelegate.clearentDeviceConnector resetConnection];
    
    [_clearentDelegate setRunStoredPaymentAfterConnecting:TRUE];
    
    _retriedTransactionAfterDisconnect = true;
    
    [NSThread sleepForTimeInterval:0.5f];
    
    return [self startTransactionAfterConnection:_clearentDelegate.clearentConnection];
    
}

- (ClearentResponse*) startTransactionAfterConnection: (ClearentConnection*) clearentConnection {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    clearentResponse.responseType = RESPONSE_SUCCESS;
    
    if(clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        clearentResponse.response = CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE;
    } else  {
        clearentResponse.response = CLEARENT_PLUGIN_AUDIO_JACK;
    }
    
    [_clearentDelegate setRunStoredPaymentAfterConnecting:TRUE];
    
    [self startConnection: clearentConnection];
    
    return clearentResponse;
}

- (void) resetTransaction {
    
    _clearentDelegate.configured = YES;
    [self clearCurrentRequest];
    [_clearentDelegate setRunStoredPaymentAfterConnecting:FALSE];
    [_clearentDelegate.clearentDeviceConnector resetConnection];
    _retriedTransactionAfterDisconnect = false;
    [_clearentDelegate disableCardRemovalTimer];
    
}

- (void) startConnection: (ClearentConnection*) clearentConnection {
    
    [self promptUserToConnectSpecificReader:clearentConnection];
    
    [_clearentDelegate.clearentDeviceConnector startConnection: clearentConnection];
    
}

- (void) promptUserToConnectSpecificReader:(ClearentConnection*) clearentConnection {
    
    if(clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        if(!clearentConnection.searchBluetooth) {
            [_clearentDelegate deviceMessage:CLEARENT_USER_ACTION_PRESS_BUTTON_MESSAGE];
        }
    } else if(clearentConnection.connectionType == CLEARENT_AUDIO_JACK && ![_clearentVP3300 device_isAudioReaderConnected]) {
        [_clearentDelegate deviceMessage:CLEARENT_PLUGIN_AUDIO_JACK];
    }
    
}

- (BOOL) isConfigurationRequested {
    
    if(_clearentDelegate.autoConfiguration || _clearentDelegate.contactlessAutoConfiguration) {
        return true;
    }
    
    return false;
    
}

- (void) updateConfiguration:(ClearentConnection*) clearentConnection {
    
    if(clearentConnection.readerInterfaceMode == CLEARENT_READER_INTERFACE_2_IN_1) {
        [self setContactless:FALSE];
    } else {
        [self setContactless:TRUE];
    }
    
}

- (void) setContactless:(BOOL)enable {
    
    [_clearentDelegate setContactless:enable];
    
}



@end
