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
#import "Teleport.h"
#import "ClearentDeviceConnector.h"

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
        
        [Teleport logInfo:@"emv_startTransaction. Tried to start transaction but disconnected"];
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        emvStartRt = RETURN_CODE_ERR_DISCONNECT;
    
    } else {
        
        [_clearentDelegate.idTechSharedInstance emv_disableAutoAuthenticateTransaction:FALSE];
        [Teleport logInfo:@"emv_startTransaction TRANSACTION_STARTED"];
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
        
        [Teleport logInfo:@"ctls_startTransaction. Tried to start transaction but disconnected"];
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        ctlsStartRt = RETURN_CODE_ERR_DISCONNECT;
    
    } else {
        
         [Teleport logInfo:@"ctls_startTransaction with vars TRANSACTION_STARTED"];
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
        
        [Teleport logInfo:@"ctls_startTransaction no vars. Tried to start transaction but disconnected"];
        
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        
        ctlsStartRt = RETURN_CODE_ERR_DISCONNECT;
        
    } else {
        
        [Teleport logInfo:@"ctls_startTransaction no vars TRANSACTION_STARTED"];
        
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
        
        [Teleport logInfo:@"emv_startTransaction. Tried to start transaction but disconnected"];
        
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        
        emvStartRt = RETURN_CODE_ERR_DISCONNECT;
        
    } else {
        
        [_clearentDelegate.idTechSharedInstance emv_disableAutoAuthenticateTransaction:FALSE];
        
        [Teleport logInfo:@"emv_startTransaction TRANSACTION_STARTED"];
        
        emvStartRt = [_clearentDelegate.idTechSharedInstance emv_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];
        
    }
    
    return emvStartRt;
    
}

-(ClearentResponse*) startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest clearentConnection:(ClearentConnection*) clearentConnection {
    
    ClearentResponse *clearentResponse;
   
    if(clearentPaymentRequest == nil || clearentConnection == nil) {
        
        clearentResponse = [self createRequiredTransactionRequestResponse];
        
    } if([self isConfigurationRequested]) {
        
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
    
    if(RETURN_CODE_OK_NEXT_COMMAND == idTechReturnCode || RETURN_CODE_DO_SUCCESS == idTechReturnCode) {
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
        
        [Teleport logInfo:@"device_startTransaction. Tried to start transaction but disconnected"];
        
        [_clearentDelegate deviceMessage:CLEARENT_DEVICE_NOT_CONNECTED];
        
        deviceStartRt = RETURN_CODE_ERR_DISCONNECT;
        
    } else {

        [NSThread sleepForTimeInterval:0.5f];
        [_clearentDelegate.idTechSharedInstance emv_disableAutoAuthenticateTransaction:FALSE];
        [_clearentDelegate setClearentPayment:clearentPaymentRequest];
        [self resetInvalidDeviceData];
        
        [self workaroundCardSeatedIssue:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];
        
        deviceStartRt = [_clearentDelegate.idTechSharedInstance device_startTransaction:clearentPaymentRequest.amount amtOther:clearentPaymentRequest.amtOther type:clearentPaymentRequest.type timeout:clearentPaymentRequest.timeout tags:clearentPaymentRequest.tags forceOnline:clearentPaymentRequest.forceOnline  fallback:clearentPaymentRequest.fallback];
        
        [self remoteLogTransactionRequest: deviceStartRt];
    }
    
    return deviceStartRt;
    
}

- (void) remoteLogTransactionRequest: (RETURN_CODE) idtechReturnCode {
    
    if([self isTransactionStarted:idtechReturnCode]) {
        
        [Teleport logInfo:@"TRANSACTION STARTED"];
        
    } else if([self isTransactionInvalid:idtechReturnCode]) {
        
        [Teleport logInfo:@"TRANSACTION FAILED. bad parameters"];
        
    } else if(RETURN_CODE_MONO_AUDIO_ == idtechReturnCode) {
        
        [Teleport logInfo:@"TRANSACTION FAILED. Possible unrecoverable error. Use reader reset button"];
        
    } else if([self isPreviousTransactionInProgress:idtechReturnCode]) {
        
        [Teleport logInfo:@"TRANSACTION FAILED. Existing transaction."];
        
    } else if([self isDisconnected:idtechReturnCode]) {
        
        [Teleport logInfo:@"TRANSACTION FAILED. Disconnected"];
        
    } else if([self isConnectionError:idtechReturnCode]) {
        
        [Teleport logInfo:@"TRANSACTION FAILED. possible state - If the reader if OFF, but SDK thinks it still is connected."];
        
    } else {
        
        NSString *errorResponse = [_clearentDelegate.idTechSharedInstance device_getResponseCodeString:idtechReturnCode];
        
        [Teleport logInfo:[NSString stringWithFormat:@"remoteLogTransactionRequest: TRANSACTION FAILED. Error: ", errorResponse]];
        
    }
}

//It appears the idtech firmware has a flag that indicates a card is seated in the reader. This breaks idtech's device_startTransaction which is meant to support
//contactless, dip, and swipe. If we don't attempt to get the cardSeated changed to false the contactless feature is disabled.
//IdTech has fixed this issue with new firmware but we need to keep this in place until everyone is upgraded
- (void) workaroundCardSeatedIssue:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback {
    
       NSString *firmwareVersion = [_clearentDelegate getFirmwareVersion];
       if(firmwareVersion != nil && ([firmwareVersion isEqualToString:@"VP3300 Bluetooth NEO v1.01.090"]
          || [firmwareVersion isEqualToString:@"VP3300 Audio Jack NEO v1.01.055"]
          || [firmwareVersion isEqualToString:@"VP3300 Audio Jack NEO v1.01.064"])) {
           [Teleport logInfo:[NSString stringWithFormat:@"workaroundCardSeatedIssue:Performing card seated workaround for firmware version - %@", firmwareVersion]];
       } else {
            [Teleport logInfo:[NSString stringWithFormat:@"workaroundCardSeatedIssue: Skip card seated workaround for firmware version - %@", firmwareVersion]];
            return;
       }
       ICCReaderStatus* response;
       RETURN_CODE icc_getICCReaderStatusRt = [_clearentDelegate.idTechSharedInstance icc_getICCReaderStatus:&response];
       if(RETURN_CODE_DO_SUCCESS != icc_getICCReaderStatusRt) {
           [Teleport logInfo:@"workaroundCardSeatedIssue:Failed to retrieve the icc reader status"];
           if(response == nil) {
               [Teleport logInfo:@"workaroundCardSeatedIssue:No icc reader status response"];
               return;
           }
       }
       if(response->cardPresent) {
          [Teleport logInfo:@"workaroundCardSeatedIssue:Skip the workaround for the contactless card seated issue. icc reader status is cardPresent"];
           return;
       }
       if(response->cardSeated) {
           [Teleport logInfo:@"workaroundCardSeatedIssue:Card is Seated. Start the device transaction and then cancel it"];
           RETURN_CODE device_startTransactionRt = [_clearentDelegate.idTechSharedInstance device_startTransaction:amount amtOther:amtOther type:type timeout:timeout tags:tags forceOnline:forceOnline  fallback:fallback];
           if(RETURN_CODE_OK_NEXT_COMMAND == device_startTransactionRt || RETURN_CODE_DO_SUCCESS == device_startTransactionRt) {
               [NSThread sleepForTimeInterval:0.2f];
               [Teleport logInfo:@"workaroundCardSeatedIssue:Cancel the transaction"];
               RETURN_CODE cancelTransactionRt = [_clearentDelegate.idTechSharedInstance device_cancelTransaction];
               if (RETURN_CODE_DO_SUCCESS == cancelTransactionRt) {
                   [Teleport logInfo:@"workaroundCardSeatedIssue:transaction cancelled"];
                   ICCReaderStatus* icc_getICCReaderStatusResponse;
                   [_clearentDelegate.idTechSharedInstance icc_getICCReaderStatus:&icc_getICCReaderStatusResponse];
                   if(icc_getICCReaderStatusResponse != nil) {
                       if(icc_getICCReaderStatusResponse->cardSeated) {
                           [Teleport logInfo:@"workaroundCardSeatedIssue:Card is still seated"];
                       } else {
                          [Teleport logInfo:@"workaroundCardSeatedIssue:Card not seated"];
                       }
                    }
               } else {
                   [Teleport logInfo:@"workaroundCardSeatedIssue:Cancel transaction failed"];
               }
           } else {
               [Teleport logInfo:@"workaroundCardSeatedIssue:Start transaction failed"];
           }
       } else {
           [Teleport logInfo:@"workaroundCardSeatedIssue: Card is unseated. No need for workaround"];
       }
}

-(RETURN_CODE) device_cancelTransaction {
    [self clearCurrentRequest];
    return [_clearentDelegate.idTechSharedInstance device_cancelTransaction];
}

- (RETURN_CODE) emv_cancelTransaction {
    [self clearCurrentRequest];
    return [_clearentDelegate.idTechSharedInstance emv_cancelTransaction];
}

- (void) clearCurrentRequest{
    [_clearentDelegate clearCurrentRequest];
}

- (void) resetInvalidDeviceData {
   [_clearentDelegate resetInvalidDeviceData];
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
    [Teleport logInfo:@"createRequiredTransactionRequestResponse. payment request and connection required "];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = CLEARENT_REQUIRED_TRANSACTION_REQUEST_RESPONSE;
    clearentResponse.idtechReturnCode = RETURN_CODE_CANNOT_START_CONTACT_EMV;
    
    return clearentResponse;
    
}

- (ClearentResponse*) createConfigurationRequestResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    [Teleport logInfo:@"createConfigurationRequestResponse. configuration is still enabled "];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = CLEARENT_DISABLE_CONFIGURATION_TO_RUN_TRANSACTION;
    clearentResponse.idtechReturnCode = RETURN_CODE_CANNOT_START_CONTACT_EMV;
    
    return clearentResponse;
    
}

- (ClearentResponse*) createStillConnectedToAudioJackResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    [Teleport logInfo:@"createStillConnectedToAudioJackResponse. Still connected to audio jack but wants to connect to bluetooth"];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = CLEARENT_UNPLUG_AUDIO_JACK_BEFORE_CONNECTING_TO_BLUETOOTH;
    
    return clearentResponse;
    
}

- (ClearentResponse*) createAudioJackNotConnectedResponse {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    [Teleport logInfo:@"createStillConnectedToAudioJackResponse. audio jack is not connected"];
    clearentResponse.responseType = RESPONSE_FAIL;
    clearentResponse.response = @"AUDIO JACK NOT CONNECTED";
    
    return clearentResponse;
    
}

- (ClearentResponse*) startTransactionByReaderInterfaceMode: (id<ClearentPaymentRequest>) clearentPaymentRequest
clearentConnection:(ClearentConnection*) clearentConnection {
    
    [_clearentDelegate setClearentPayment:clearentPaymentRequest];
    
    [Teleport logInfo:@"startTransactionByReaderInterfaceMode. Device is connected. Start transaction"];
    
    RETURN_CODE startTransactionReturnCode = [self startTransactionByReaderInterfaceMode:_clearentDelegate.clearentConnection.readerInterfaceMode];
    
    ClearentResponse *clearentResponse =  [self handleStartTransactionResult: startTransactionReturnCode];
    
    if(clearentResponse != nil && clearentResponse.responseType == RESPONSE_FAIL) {
        [_clearentDelegate deviceMessage:clearentResponse.response];
    }
    return clearentResponse;
}

- (ClearentResponse*) handleStartTransactionResult: (RETURN_CODE) startTransactionReturnCode  {
    
    ClearentResponse *clearentResponse = [[ClearentResponse alloc] init];
    
    clearentResponse.idtechReturnCode = startTransactionReturnCode;
    
    if([self isTransactionStarted:startTransactionReturnCode]) {
        
        clearentResponse.response = CLEARENT_RESPONSE_TRANSACTION_STARTED;
        clearentResponse.responseType = RESPONSE_SUCCESS;
        
        [Teleport logInfo:@"handleStartTransactionErrors: transaction started"];
        
    } else if([self isPreviousTransactionInProgress:startTransactionReturnCode] || [self isGeneralFailure:startTransactionReturnCode]) {
        
        int device_cancelTransactionRt = [_clearentDelegate.idTechSharedInstance device_cancelTransaction];
        
        if(RETURN_CODE_DO_SUCCESS == device_cancelTransactionRt) {
            startTransactionReturnCode = [self startTransactionByReaderInterfaceMode:_clearentDelegate.clearentConnection.readerInterfaceMode];
            clearentResponse.idtechReturnCode = startTransactionReturnCode;
            if([self isTransactionStarted:startTransactionReturnCode]) {
                [Teleport logInfo:@"handleStartTransactionErrors: previous transaction in progress or general failure. cancel transaction succeeded. start new transaction success"];
                clearentResponse.response = CLEARENT_RESPONSE_TRANSACTION_STARTED;
                clearentResponse.responseType = RESPONSE_SUCCESS;
            } else if(_clearentDelegate.clearentConnection != nil && _clearentDelegate.clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
                [_clearentVP3300 device_disconnectBLE];
                if(!_retriedTransactionAfterDisconnect) {
                    [Teleport logInfo:@"handleStartTransactionErrors: previous transaction in progress or general failure. retry of transaction after cancelling transaction failed. retryTransactionAfterBluetoothDisconnect"];
                    clearentResponse = [self retryTransactionAfterReconnectAttempt];
                }
            }
        } else if(_clearentDelegate.clearentConnection != nil && _clearentDelegate.clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            [_clearentVP3300 device_disconnectBLE];
            if(!_retriedTransactionAfterDisconnect) {
                [Teleport logInfo:@"handleStartTransactionErrors: previous transaction in progress or general failure. cancel transaction failed. retryTransactionAfterBluetoothDisconnect"];
                clearentResponse = [self retryTransactionAfterReconnectAttempt];
            }
        }
        
    } else if([self isDisconnected:startTransactionReturnCode]) {
        
        if(!_retriedTransactionAfterDisconnect) {
            [Teleport logInfo:@"handleStartTransactionErrors: isDisconnected. retryTransactionAfterBluetoothDisconnect"];
            clearentResponse = [self retryTransactionAfterReconnectAttempt];
        }
        
    } else if([self isConnectionError:startTransactionReturnCode]) {
        
        if(_clearentDelegate.clearentConnection != nil && _clearentDelegate.clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            [_clearentVP3300 device_disconnectBLE];
            [Teleport logInfo:@"handleStartTransactionErrors: isConnectionError. retryTransactionAfterBluetoothDisconnect"];
            clearentResponse = [self retryTransactionAfterReconnectAttempt];
        } else {
            clearentResponse.response = CLEARENT_DEVICE_NOT_CONNECTED;
            clearentResponse.responseType = RESPONSE_FAIL;
            clearentResponse.idtechReturnCode = startTransactionReturnCode;
        }
        
    } else if([self isTransactionInvalid:startTransactionReturnCode]) {
        
        clearentResponse.response = CLEARENT_RESPONSE_INVALID_TRANSACTION;
        clearentResponse.responseType = RESPONSE_FAIL;
        
    }
    
    if(clearentResponse.response == nil) {
        
        clearentResponse.responseType = RESPONSE_FAIL;
        
        NSString *errorResponse = [_clearentDelegate.idTechSharedInstance device_getResponseCodeString:startTransactionReturnCode];
        
        if(errorResponse != nil && ![errorResponse isEqualToString:@""]) {
            
            NSString *errorMessage = [NSString stringWithFormat:@"%@[%@%@", CLEARENT_RESPONSE_TRANSACTION_FAILED, errorResponse , @"]"];
            [Teleport logInfo:errorMessage];
            clearentResponse.response = errorMessage;
            
        } else {
            
            clearentResponse.responseType = RESPONSE_FAIL;
            clearentResponse.response = CLEARENT_RESPONSE_TRANSACTION_FAILED;
            
        }
        
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
    
}

- (void) startConnection: (ClearentConnection*) clearentConnection {
    
    [self promptUserToConnectSpecificReader:clearentConnection];
    
    [_clearentDelegate.clearentDeviceConnector startConnection: clearentConnection];
    
}

- (void) promptUserToConnectSpecificReader:(ClearentConnection*) clearentConnection {
    
    if(clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        if(clearentConnection.searchBluetooth) {
            [_clearentDelegate deviceMessage:CLEARENT_BLUETOOTH_SEARCH];
        } else {
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
