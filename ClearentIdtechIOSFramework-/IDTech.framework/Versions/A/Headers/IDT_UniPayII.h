//
//  IDT_UniPayII.h
//  IDTech
//
//  Created by Randy Palermo on 7/2/14.
//  Copyright (c) 2014 IDTech Products. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDTMSRData.h"
#import "APDUResponse.h"
#import "IDT_Device.h"




/** Protocol methods established for IDT_UniPayII class  **/
@protocol IDT_UniPayII_Delegate <NSObject>

@optional
-(void) deviceConnected; //!<Fires when device connects.  If a connection is established before the delegate is established (no delegate to send initial connection notification to), this method will fire upon establishing the delegate.
-(void) deviceDisconnected; //!<Fires when device disconnects.
- (void) plugStatusChange:(BOOL)deviceInserted; //!<Monitors the headphone jack for device insertion/removal.
//!< @param deviceInserted TRUE = device inserted, FALSE = device removed
- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming; //!<All incoming/outgoing data going to the device can be monitored through this delegate.
//!< @param data The serial data represented as a NSData object
//!< @param isIncoming The direction of the data
//!<- <c>TRUE</c> specifies data being received from the device,
//!<- <c>FALSE</c> indicates data being sent to the device.

- (void) swipeMSRData:(IDTMSRData*)cardData;//!<Receives card data from MSR swipe.
//!< @param cardData Captured card data from MSR swipe
- (void) deviceMessage:(NSString*)message;//!<Receives messages from the framework
//!< @param message String message transmitted by framework


/**
 UniPay ICC Event
 This function will be called when an ICC is attached or detached from reader. Applies to UniPay/UniPayII only
 
 @param nICC_Attached Can be one of the following values:
 - 0x01: ICC Card Inserted while reader is idle
 - 0x00: ICC Card Removed while reader is idle
 - 0x11: ICC Card Inserted while reader is in MSR mode
 - 0x10: ICC Card Removed while reader is in MSR Mode
 
 @code
 -(void) eventFunctionICC: (Byte) nICC_Attached
 {
 switch (nICC_Attached) {
 case 0x01:
 case 0x11:
 {
 LOGI(@"ICC event: ICC Card Inserted.");
 }
 break;
 
 case 0x00:
 case 0x10:
 {
 LOGI(@"ICC event: ICC Card Removed.");
 }
 break;
 }
 }
 @endcode
 */
-(void) eventFunctionICC: (Byte) nICC_Attached;

/**
 EMV Transaction Data
 
 This protocol will receive results from IDT_Device::startEMVTransaction:otherAmount:timeout:cashback:additionalTags:()
 
 
 @param emvData EMV Results Data.  Result code, card type, encryption type, masked tags, encrypted tags, unencrypted tags and KSN
 
 @param error The error code as defined in the errors.h file
 
 
 */
- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error;

/**
 Pinpad data delegate protocol
 
 Receives data from pinpad methods
 
 @param value encrypted data returned from IDT_Device::getEncryptedData:minLength:maxLength:messageID:language:(), or encrypted account number returned from IDT_Device::getCardAccount:max:line1:line2:(). String value returned from IDT_Device::getAmount:maxLength:messageID:language:() or IDT_Device::getNumeric:minLength:maxLength:messageID:language:(). PINblock returned from IDT_Device::getEncryptedPIN:keyType:line1:line2:line3:()
 @param KSN Key Serial Number returned from IDT_Device::getEncryptedPIN:keyType:line1:line2:line3:(), IDT_Device::getCardAccount:max:line1:line2:() or IDT_Device::getEncryptedData:minLength:maxLength:messageID:language:()
 @param event EVENT_PINPAD_Types PINpad event that solicited the data capture
 
 @code
 typedef enum{
 EVENT_PINPAD_UNKNOWN = 11,
 EVENT_PINPAD_ENCRYPTED_PIN,
 EVENT_PINPAD_NUMERIC,
 EVENT_PINPAD_AMOUNT,
 EVENT_PINPAD_ACCOUNT,
 EVENT_PINPAD_ENCRYPTED_DATA,
 EVENT_PINPAD_CANCEL,
 EVENT_PINPAD_TIMEOUT,
 EVENT_PINPAD_FUNCTION_KEY,
 EVENT_PINPAD_DATA_ERROR
 }EVENT_PINPAD_Types;
 @endcode
 */
- (void) pinpadData:(NSData*)value keySN:(NSData*)KSN event:(EVENT_PINPAD_Types)event;
@end


/**
 Class to drive the IDT_UniPayII device
 */
@interface IDT_UniPayII : NSObject<IDT_Device_Delegate>{
    id<IDT_UniPayII_Delegate> delegate;
}

@property(strong) id<IDT_UniPayII_Delegate> delegate;  //!<- Reference to IDT_UniPayII_Delegate.




/**
 * SDK Version
 - All Devices
 *
 Returns the current version of IDTech.framework
 
 @return  Framework version
 */
+(NSString*) SDK_version;

/**
 * Singleton Instance
 - All Devices
 *
 Establishes an singleton instance of IDT_UniPayII class.
 
 @return  Instance of IDT_UniPayII
 */
+(IDT_UniPayII*) sharedController;


/**
 * Get Mask Character
 *
 Gets the PAN Mask Character
 
 @param response  Single character NSString with the mask character.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_getASCIIMaskData:(NSString**)mask;

/**
 * Get BCD Mask Data
 *
 Gets the BCD Mask Data.  Valid values are 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
 
 @param response Mask Value
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_getBCDMaskData:(NSUInteger**)response;


/**
 * Polls device for current Date/Time
 *
 * @param response Response returned as ASCII Data of Date  YYMMDDhhmmss. Example 140215171628 = Feb. 15, 2014, 28 seconds into 5:16pm.
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 
 @code
 NSString* response;
 RETURN_CODE rt = [[IDT_UniPayII sharedController] config_getDateTime:&response];
 if (RETURN_CODE_DO_SUCCESS == rt)
 {
 LOGI* (@"Date Time (YYMMDDhhmmss) = %@",response);
 }
 @endcode
 *
 */
-(RETURN_CODE) config_getDateTime:(NSString**)response;

/**
 * Get Account DUKPT Key Variant
 - UniPayII
 
 *
 Gets the DUKPT Key encryption and decryption modes
 
 @param response Current Encryption/Decryption Mode
 TDES: 00
 AES: 01
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_getDUKPTKeyEncryption:(NSUInteger**)response;


/**
 * Get Account DUKPT Key Variant
 
 *
 Gets the Key Variant for DUKPT
 
 @param response Key Variant
 DUKPT Data Key: 00
 DUKPT PIN Key: 01
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_getDUKPTKeyVariant:(NSUInteger**)response;

/**
 * Get ICC Connector
 
 *
 Gets the ICC Connector
 
 @param response ICC Connector
 00: User Card Connector
 01: SAM Connector
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_getICCConnector:(NSUInteger**)response;

/**
 * Polls device for Model Number
 
 *
 * @param response  Returns Model Number
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 *
 */
-(RETURN_CODE) config_getModelNumber:(NSString**)response;

/**
 * Get Pre/Post PAN Ctrl Data Length
 *
 Gets the length of the PAN Pre and Post Ctrl Data
 
 @param pre  Return amount of digits Pre Ctrl Data
 @param post  Return amount of digits Post Ctrl Data
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_getPrePostPANCtrlData:(Byte**)pre post:(Byte**)post;

/**
 * Polls device for Serial Number
 
 *
 * @param response  Returns Serial Number
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 *
 */
-(RETURN_CODE) config_getSerialNumber:(NSString**)response;

/**
 * Set Mask Character
 *
 Sets the PAN Mask Character
 
 @param mask  Single character NSString with the mask character.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setASCIIMaskData:(NSString*)mask;


/**
 * Set BCD Mask Data
 *
 Sets the BCD Mask Data.  Valid values are 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
 
 @param mask  Mask value, valid values are 10 - 15  (0x0A - 0x0F)
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setBCDMaskData:(int)mask;

/**
 * Command Acknowledgement Timout
 *
 * Sets the amount of seconds to for an {ACK} to a command before a timeout.  Responses should normally be received under one second.  Default is 3 seconds.
 *
 * @param nSecond  Timout value.  Valid range .1 - 60 seconds
 
 * @return Success flag.  Determines if value was set and in range.
 */
-(BOOL) config_setCmdTimeOutDuration: (float) nSecond;


/**
 * Set device device Date/Time
 *
 Set device's date/time
 *
 @param date Device date represented by a YYMMDDhhmmss.  Example March 12, 2014, 6:30pm (and 12 seconds) = 140312183012
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setDateTime:(NSString*)date;

/**
 * Set Default ICC Group Settings
 *
 Restores ICC Group Settings to defaults;
 
 Function Name | Default Value
 -------- | --------
 ICC Connector | User Card Connector (main module)
 PrePANCtlDataLen | 4
 PostPANCtlDataLen | 4
 AsciiMaskData | 0x2A
 BCDMaskData | 0x0C
 
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setDefaultICCGroupSettings;

/**
 * Set Account DUKPT Key Encryption/Decryption mode
 
 *
 Sets the DUKPT Key encryption and decryption modes
 
 @param type Encryption/Decryption Mode
 TDES: 00
 AES: 01
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setDUKPTKeyEncryption:(int)type;

/**
 * Set Account DUKPT Key Variant
 
 *
 Sets the response Key Variant
 
 @param type Key Variant
 DUKPT Data Key: 00
 DUKPT PIN Key: 01
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setDUKPTKeyVariant:(int)type;

/**
 * Set ICC Connector
 
 *
 Sets the ICC Connector
 
 @param connector ICC Connector
 00: user Car Connector (main module)
 01: SAM Connector
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setICCConnector:(int)connector;

/**
 * Set Pre/Post PAN Ctrl Data Length
 *
 Sets the length of the PAN Pre and Post Ctrl Data
 
 @param pre  Amount of digits Pre Ctrl Data
 @param post  Amount of digits Post Ctrl Data
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) config_setPrePostPANCtrlData:(Byte)pre post:(Byte)post;

/**
 * Cancel Connect To Audio Reader
 * @return RETURN_CODE
 *
 Cancels a connection attempt to an IDTech MSR device connected via the audio port.
 
 */

-(RETURN_CODE) device_cancelConnectToAudioReader;
/**
 * Connect To Audio Reader
 * @return RETURN_CODE
 *
 Attemps to recognize and connect to an IDTech MSR device connected via the audio port.
 
 */

-(RETURN_CODE) device_connectToAudioReader;


/**
 * Polls device for Firmware Version
 
 *
 * @param response Response returned of Firmware Version
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 *
 */
-(RETURN_CODE) device_getFirmwareVersion:(NSString**)response;

/**
 * Get Level and Baude
 *
 @param response  The Baud Rate and Audio Level.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_getLevelAndBaud:(NSString**)response;

/**
 * Polls device for status of the keys
 - UniPay II
 *
 * @param response  Returns Key Status.  NSData byte stream following following format:
 PIN DUKPT Status + PIN Master Key Status + PIN Session Key Status + Account DUKPT Key Status + AccountDUKPT Key Status + Admin DUKPT Key
 PIN DUKPT Key:
 - 0: None.
 - 1: Exist
 - 0xFF: STOP
 
 PIN Master Key:
 - 0: None
 - 1: At least Exist a Master Key
 
 PIN Session Key:
 - 0: None.
 - 1: Exist
 
 Account DUKPT Key:
 - 0: None.
 - 1: Exist
 - 0xFF: STOP
 
 Account DUKPT Key:
 - 0: None.
 - 1: Exist
 - 0xFF: STOP
 
 Admin DUKPT Key:
 - 0: None.
 - 1: Exist
 - 0xFF: STOP
 
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 *
 */
-(RETURN_CODE) device_getKeyStatus:(NSData**)response;
/**
 * Get Mask and Encryption
 
 *
 Retrieves the MSR Mask and Encryption settings
 
 @param data Pointer that will return location of MaskAndEncryption structure.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_getMaskAndEncryption:(MaskAndEncryption**)data;
/**
 * Get Response Code String
 *
 Interpret a IDT_UniPayII response code and return string description.
 
 @param errorCode Error code, range 0x0000 - 0xFFFF, example 0x0300
 
 
 * @return Verbose error description
 
 HEX VALUE | Description
 ------- | -------
 0x0000 | No error, beginning task
 0x0001 | No response from reader
 0x0002 | Invalid response data
 0x0003 | Time out for task or CMD
 0x0004 | Wrong parameter
 0x0005 | SDK is doing MSR or ICC task
 0x0006 | SDK is doing PINPad task
 0x0007 | SDK is doing Other task
 0x0300 | Key Type(TDES) of Session Key is not same as the related Master Key.
 0x0400 | Related Key was not loaded.
 0x0500 | Key Same.
 0x0501 | Key is all zero.
 0x0502 | TR31 format error.
 0x0702 | PAN is Error Key.
 0x0705 | No internal MSR PAN (or internal MSR PAN is erased timeout).
 0x0D00 | This Key had been loaded.
 0x0E00 | Base Time was loaded.
 0x0F00 | Encryption or decryption failed.
 0x1000 | Battery low warning(is high priority response while battery is low).
 0x1800 | Send “Cancel Command” after send “Get Encrypted PIN” &”Get Numeric “& “Get Amount”
 0x1900 | Press “Cancel” key after send “Get Encrypted PIN” &”Get Numeric “& “Get Amount”
 0x2C02 | No microprocessor ICC seated.
 0x30FF | Security Chip is not connect
 0x3000 | Security Chip is deactivation & Device is In Removal Legally State.
 0x3101 | Security Chip is activation &  Device is In Removal Legally State.
 0x5500 | No Admin DUKPT Key.
 0x5501 | Admin  DUKPT Key STOP.
 0x5502 | Admin DUKPT Key KSN is Error.
 0x5503 | Get Authentication Code1 Failed.
 0x5504 | Validate Authentication Code Error.
 0x5505 | Encrypt or Decrypt data failed.
 0x5506 | Not Support the New Key Type.
 0x5507 | New Key Index is Error.
 0x5508 | Step Error.
 0x5509 | Remote key injection timeout (Latest command is timeout).
 0x550A | MAC error.
 0x550B | Key usage error.
 0x550C | Mode of use error.
 0x550F | Other Error.
 0x6000 | Save or Config Failed / Or Read Config Error.
 0x6200 | No Serial Number.
 0x6900 | Invalid Command - Protocol is right, but task ID is invalid.
 0x6A00 | Unsupported Command - Protocol and task ID are right, but command is invalid.
 0x6A01 | Unsupported command - protocol and task ID are right, but command is invalid - in this state.
 0x6B00 | Unknown parameter in command - Protocol task ID and command are right, but parameter is invalid.
 0x6C00 | Unknown length in command - protocol and task ID are right, but length is out of the requirement.
 0x7200 | Device is suspend (MKSK suspend or press password suspend).
 0x7300 | PIN DUKPT is STOP (21 bit 1).
 0x7400 | Device is Busy.
 0x8300 | No card data.
 0x8400 | TriMagII no response.
 0xE100 | Can not enter sleep mode.
 0xE200 | File has existed.
 0xE300 | File has not existed.
 0xE313 | IO line low - card error after session start.
 0xE400 | Open File Error.
 0xE500 | SmartCard Error.
 0xE600 | Get MSR Card data is error.
 0xE700 | Command time out.
 0xE800 | File read or write is error.
 0xE900 | Active 1850 error!
 0xEA00 | Load bootloader error.
 0xEF00 | Protocol Error- STX or ETX or check error.
 0xEB00 | Picture is not exist.
 0x2C06 | no card seated to request ATR
 0x2D01 | Card Not Supported,
 0x2D03 | Card Not Supported, wants CRC
 0x690D | Command not supported on reader without ICC support
 0x8100 | ICC error time out on power-up
 0x8200 | invalid TS character received
 0x8500 | pps confirmation error
 0x8600 | Unsupported F, D, or combination of F and D
 0x8700 | protocol not supported EMV TD1 out of range
 0x8800 | power not at proper level
 0x8900 | ATR length too long
 0x8B01 | EMV invalid TA1 byte value
 0x8B02 | EMV TB1 required
 0x8B03 | EMV Unsupported TB1 only 00 allowed
 0x8B04 | EMV Card Error, invalid BWI or CWI
 0x8B06 | EMV TB2 not allowed in ATR
 0x8B07 | EMV TC2 out of range
 0x8B08 | EMV TC2 out of range
 0x8B09 | per EMV96 TA3 must be > 0xF
 0x8B10 | ICC error on power-up
 0x8B11 | EMV T=1 then TB3 required
 0x8B12 | Card Error, invalid BWI or CWI
 0x8B13 | Card Error, invalid BWI or CWI
 0x8B17 | EMV TC1/TB3 conflict*
 0x8B20 | EMV TD2 out of range must be T=1
 0x8C00 | TCK error
 0xA304 | connector has no voltage setting
 0xA305 | ICC error on power-up invalid (SBLK(IFSD) exchange
 0xF002 | ICC communication timeout.
 0xF003 | ICC communication erro.
 0xF00F | ICC card seated and highest priority, disable MSR work request.
 0xF200 | AID list / application data is not exist.
 0xF201 | Terminal data is not exist.
 0xF202 | TLV format error.
 0xF203 | AID list is full.
 0xF204 | Any CAKey is not exist.
 0xF205 | CAKey RID is not exist.
 0xF206 | CAKey index is not exist.
 0xF207 | CAKey is full.
 0xF208 | CAKey hash value error.
 0xF209 | Transaction form at error.
 0xF20A | The command will not processing.
 0xF20B | CRL is not exist.
 0xF20C | CRL number exceed max number.
 0xF20D | Amount, Other Amount, Transaction type are missing.
 0xF20E | The identification of algorithm is mistake.
 0xF20F | No financial card.
 0xF210 | In encrypt result state, TLV total length is greater then max length.
 0xE301 | ICC error after session star
 0xFF00 | EMV: Request to go online
 0xFF01 | EMV: Accept the offline transaction
 0xFF02 | EMV: Decline the offline transaction
 0xFF03 | EMV: Accept the online transaction
 0xFF04 | EMV: Decline the online transaction
 0xFF05 | EMV: Application may fallback to magstripe technology
 0xFF06 | EMV: ICC detected that the conditions of use are not satisfied
 0xFF07 | EMV: ICC didn't accept transaction
 0xFF08 | EMV: Transaction was cancelled
 0xFF09 | EMV: Application was not selected by kernel or ICC format error or ICC missing data error
 0xFF0A | EMV: Transaction is terminated
 0xFF0B | EMV: Other EMV Error
 
 */
-(NSString *) device_getResponseCodeString: (int) errorCode;


/**
 * Is Audio Reader Connected
 
 *
 Returns value on device connection status when device is an audio-type connected to headphone plug.
 
 @return BOOL True = Connected, False = Disconnected
 
 */

-(BOOL) device_isAudioReaderConnected;



/**
 Is Device Connected
 
 Returns the connection status of the requested device
 
 @param device Check connectivity of device type
 
 @code
 typedef enum{
 IDT_DEVICE_UniPay_IOS = 3,
 IDT_DEVICE_UniPay_OSX_USB = 4
 }IDT_DEVICE_Types;
 
 @endcode
 */
-(bool) device_isConnected:(IDT_DEVICE_Types)device;



/**
 * Reboot Device
 
 
 *
 Executes a command to restart the device.
 *
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */

-(RETURN_CODE) device_rebootDevice;

/**
 * Restore Mask and Encryption default settings
 - BTPay
 
 *
 Restores the default values for MSR Mask and Encryption settings
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_restoreMaskAndEncryptionDefaults;
/**
 * Send a NSData object to device
 *
 * Sends a command represented by the provide NSData object to the device through the accessory protocol.
 *
 * @param cmd NSData representation of command to execute
 * @param lrc If <c>TRUE</c>, this will wrap command with start/length/lrc/sum/end:  '{STX}{Len_Low}{Len_High} data {CheckLRC} {CheckSUM} {ETX}'
 @param response Response data
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 */
-(RETURN_CODE) device_sendDataCommand:(NSData*)cmd calcLRC:(BOOL)lrc response:(NSData**)response;
/**
 * Set Volume To Audio Reader
 
 *
 Set the iPhone’s volume for command communication with audio-based readers. The the range of iPhone’s volume is from 0.1 to 1.0.
 
 @param val Volume level from 0.1 to 1.0
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setAudioVolume:(float)val;






/**
 * Sets the Beep Value
 
 *
 Sets a beep value on the UniPayII.
 *
 @param frequency Frequence of the beep.  Valid range 1000-20000.
 @param duration Duration in milliseconds.  Valid range 16-65535.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_sendBeep:(int)frequency duration:(int)duration;
/**
 * Set Base Key Type
 
 *
 Sets the base key type
 
 @param maskOption Mask Option
 Bit0: T1 mask allowed
 Bit1: T2 mask allowed
 Bit2: T3 mask allowed
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setMaskingOption:(char)maskOption;

/**
 * Set Encryption Key Type
 
 *
 Sets the encryption key type
 
 @param encOption Encryption Option
 Bit 0 : T1 force encrypt
 Bit 1 : T2 force encrypt
 Bit 2 : T3 force encrypt
 Bit 3 : T3 force encrypt when card type is 0
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setEncryptionOption:(char)encOption;


/**
 * Set Expiration Date masking
 
 *
 Sets the flag to enable Expiratin Date masking
 
 @param mask TRUE = mask expiration date.  FALSE = display expiration date in cleartext
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setExpMasking:(BOOL)mask;





/**
 * Set PAN masking character
 
 *
 Sets the character for PAN masking
 
 @param maskChar Masking character.  Default value '*';
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setPANMaskingCharacter:(char)maskChar;
/**
 * Set PostPAN Clear Digits
 
 *
 Sets the number of digits to show in clear text at the ending of PAN
 
 @param clearDigits Amount of characters to display cleartext at end of PAN. Valid range 0-4.  Default value 4.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setPostPANClearDigits:(int)clearDigits;

/**
 * Set PrePAN Clear Digits
 
 *
 Sets the number of digits to show in clear text at the beginning of PAN
 
 @param clearDigits Amount of characters to display cleartext at beginning of PAN. Valid range 0-6.  Default value 4.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) device_setPrePANClearDigits:(int)clearDigits;


/**
 * Authenticate Transaction
 
 Authenticated a transaction after startTransaction successfully executes.
 
 By default, auto authorize is ENABLED.  If auto authorize is DISABLED, this function must be called after a result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS returned to emvTransactionData delegate protocol is received after a startTransaction call.  If auto authorize is ENABLED (default), this method will automatically be executed after receiving the result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS after startTransaction.  The auto authorize can be enabled/disabled with IDT_DEVICE::disableAutoAuthenticateTransaction:()
 *
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_authenticateTransaction;

/**
 * Complete EMV Transaction Online Request
 *
 Completes an online EMV transaction request by the card
 
 The tags will be returned in the emvTransactionData delegate protocol.
 
 @param isSuccess Determines if connection to host was successful:
 - TRUE: Online processing with the host (issuer) was completed
 - FALSE: Online processing could not be completed due to connection error with the host (issuer). No further data (tags) required.
 @param tags Host response tag:
 
 Tag | Length | Description
 ----- | ----- | -----
 8A | 2 | Data element Authorization Response Code. Mandatory
 91 | 8-16 | Issuer Authentication Data. Optional
 71 | 0-256 | Issuer Scripts. Optional
 72 | 0-256 | Issuer Scripts. Optional
 
 
 
 
 *  @return RETURN_CODE:
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0xFE00: Authorization Accepted - RETURN_CODE_EMV_AUTHORIZATION_ACCEPTED
 - 0xFE01: Online Failure - RETURN_CODE_EMV_AUTHORIZATION_UNABLE_TO_GO_ONLINE
 - 0xFE02: Technical Issue - RETURN_CODE_EMV_AUTHORIZATION_TECHNICAL_ISSUE
 - 0xFE03: Declined - RETURN_CODE_EMV_AUTHORIZATION_DECLINED
 - 0xFE04: Issuer Referral - RETURN_CODE_EMV_AUTHORIZATION_ISSUER_REFERRAL
 
 
 
 
 \par Converting TLV to NSMutableDictionary
 
 EMV data is  received in TLV (Tag, Length, value) format:
 `950500000080009B02E8009F2701018A025A339F26080C552B9364D55CE5`
 
 This data contains the following EMV tags/values:
 
 Tag | Length | Value
 ----- | ----- | -----
 95 | 05 | 0000008000
 9B | 02 | E800
 9F27 | 01 | 01
 8A | 02 | 5A33
 9F26 | 08 | 0C552B9364D55CE5
 
 An example how to create an NSMutableDictionary with these values follows.
 
 @code
 -(NSMutableDictionary*) createTLVDict{
 
 NSMutableDictionary *emvTags = [[NSMutableDictionary alloc] initWithCapacity:0];
 
 [emvTags setObject:@"0000008000" forKey:@"95"];
 [emvTags setObject:@"E800" forKey:@"9B"];
 [emvTags setObject:@"01" forKey:@"9F27"];
 [emvTags setObject:@"5A33" forKey:@"8A"];
 [emvTags setObject:@"0C552B9364D55CE5" forKey:@"9F26"];
 
 return emvTags;
 
 }
 @endcode
 
 */
-(RETURN_CODE) emv_completeOnlineEMVTransaction:(BOOL)isSuccess hostResponseTags:(NSMutableDictionary *)tags;



/**
 * Disable Auto Authenticate Transaction
 *
 If auto authenticate is DISABLED, authenticateTransaction must be called after a successful startEMV execution.
 
 @param disable  FALSE = auto authenticate ENABLED, TRUE = auto authenticate DISABLED
 
 */
-(void) emv_disableAutoAuthenticateTransaction:(BOOL)disable;



/**
 * Polls device for EMV L1 Version
 *
 * @param response Response returned of Level 1 Version
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 *
 */
-(RETURN_CODE) emv_getEMVL1Version:(NSString**)response;


/**
 * Polls device for EMV L2 Version
 *
 * @param response Response returned of Level 2 Version
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 *
 */
-(RETURN_CODE) emv_getEMVL2Version:(NSString**)response;

/**
 * Remove Application Data by AID
 *
 Removes the Application Data as specified by the AID name passed as a parameter
 
 @param AID Name of ApplicationID in ASCII, example "A0000000031020".  Must be between 5 and 16 characters
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to BTPay::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_removeApplicationData:(NSString*)AID;

/**
 * Remove Certificate Authority Public Key
 *
 Removes the CAPK as specified by the RID/Index passed as a parameter in the CAKey structure
 
 @param rid RID of the key to remove
 @param index Index of the key to remove
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_removeCAPK:(NSString*)rid index:(NSString*)index ;




/**
 * Remove Certificate Revocation List
 *
 Removes all CRLEntry entries
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_removeCRLList;


/**
 * Remove Terminal Data
 *
 Removes the Terminal Data
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_removeTerminalData;

/**
 * Retrieve AID list
 *
 Returns all the AID name/length on the inserted ICC.  Populates response parameter with an dictionary with Keys of AID Names (NSData*), and values of AID Lengths (NSData*)
 
 @param response Returns a NSArray of NSString of AID Names
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to BTPay::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_retrieveAIDList:(NSArray**)response;


/**
 * Retrieve Application Data by AID
 - UniPay II
 *
 Retrieves the Application Data as specified by the AID name passed as a parameter.  The AID will be in the response parameter responseAID
 
 @param AID Name of ApplicationID in ASCII, example "A0000000031020".  Must be between 5 and 16 characters
 @param responseAID  The response returned from the method as a dictionary with Key/Object to match TagValues as follows:
 
 Tag | Description
 ===== | =====
 5F57 | Account Type
 9F01 | Acquirer Identifier
 9F09 | Terminal application version number
 5F36 | Transaction Currency Exponent
 9F1B | Terminal Floor Limit
 9F49 | Dynamic Data Authentication Data Object List(DDOL)
 97 | Transaction Certificate Data Object List(TDOL)
 9F39 | POS Entry Mode
 9F3C | Transaction Reference Currency Code
 9F3D | Transaction Reference Currency Exponent
 99 | PIN Block
 DF10 | LANGUAGE
 DF11 | Use Trans Log
 DF13 | TAC-Default
 DF14 | TAC-Denial
 DF15 | TAC-Online
 DF17 | Threshold Value for Biased Random Selection
 DF18 | Target Percentage For Random Transaction Selection
 DF19 | Maximum Target Percentage For Random Transaction Selection
 DF20 | Trace
 DF22 | Merchant Forced Transaction Online
 DF25 | Default DDOL
 DF26 | Use Revocation list
 DF27 | Use Exception  list
 DF28 | TDOL
 DF30 | Online DOL
 DF62 | Application Selection Flag
 DF63 | Transaction Reference Currency Conversion
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 
 
 
 */
-(RETURN_CODE) emv_retrieveApplicationData:(NSString*)AID response:(NSDictionary**)responseAID;

/**
 * Retrieve Certificate Authority Public Key
 *
 Retrieves the CAPK as specified by the RID/Index  passed as a parameter in the CAKey structure.  The CAPK will be in the response parameter
 
 @param rid The RID of the key to retrieve
 @param index The Index of the key to retrieve
 @param response Response returned as a CAKey
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE) emv_retrieveCAPK:(NSString*)rid index:(NSString*)index response:(CAKey**)response;




/**
 * Retrieve the Certificate Authority Public Key list
 *
 Returns all the CAPK RID and Index.  Populates response parameter with an array of NSString items, 12 characters each, characters 1-10 RID, characters 11-12 index.
 
 @param response Response returned contains an NSArray of NSString items, 12 characters each, characters 1-10 RID, characters 11-12 index.  Example "a00000000357" = RID a00000003, Index 57
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_retrieveCAPKList:(NSArray**)response;



/**
 * Retrieve the Certificate Revocation List

 *
 Returns all the RID in the CRL.
 @param response Response returned as an NSArray of NSData objects 9-bytes each:
 - 5-bytes RID, 1-byte Index, 3-byte Serial Number
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 */
-(RETURN_CODE) emv_retrieveCRLList:(NSMutableArray**)response;





/**
 * Retrieve Terminal Data
 - UniPay II
 *
 Retrieves the Terminal Data .  The Terminal Data will be in the response parameter responseData
 
 @param responseData  The response returned from the method as a dictionary with Key/Object to match TagValues as follows:
 
 9F1A | Terminal Country Code
 9F35 | Terminal Type
 9F33 | Terminal Capability
 9F40 | Additional Terminal Capability
 9F1E | IFD Serial Number
 9F15 | Merchant Category Code
 9F16 | Merchant Identifier
 9F1C | Terminal Identification
 9F4E | Merchant Name and Location
 DF10 | LANGUAGE
 DF11 | Use Trans Log
 DF13 | TAC-Default
 DF14 | TAC-Denial
 DF15 | TAC-Online
 DF17 | Threshold Value for Biased Random Selection
 DF18 | Target Percentage For Random Transaction Selection
 DF19 | Maximum Target Percentage For Random Transaction Selection
 DF20 | Trace
 DF22 | Merchant Forced Transaction Online
 DF25 | Default DDOL
 DF26 | Use Revocation list
 DF27 | Use Exception  list
 DF28 | TDOL
 DF30 | Online DOL
 DF62 | Application Selection Flag
 DF63 | Transaction Reference Currency
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 
 
 
 */
-(RETURN_CODE) emv_retrieveTerminalData:(NSDictionary**)responseData;











/**
 * Set Application Data by AID
 *
 Sets the Application Data as specified by the dictionary containing Tags (dictionary keys) and Values (dictionary objects) according to the following table
 
 Tag | Description
 ===== | =====
 5F57 | Account Type
 9F01 | Acquirer Identifier
 9F09 | Terminal application version number
 5F36 | Transaction Currency Exponent
 9F1B | Terminal Floor Limit
 9F49 | Dynamic Data Authentication Data Object List(DDOL)
 97 | Transaction Certificate Data Object List(TDOL)
 9F39 | POS Entry Mode
 9F3C | Transaction Reference Currency Code
 9F3D | Transaction Reference Currency Exponent
 99 | PIN Block
 DF10 | LANGUAGE
 DF11 | Use Trans Log
 DF13 | TAC-Default
 DF14 | TAC-Denial
 DF15 | TAC-Online
 DF17 | Threshold Value for Biased Random Selection
 DF18 | Target Percentage For Random Transaction Selection
 DF19 | Maximum Target Percentage For Random Transaction Selection
 DF20 | Trace
 DF22 | Merchant Forced Transaction Online
 DF25 | Default DDOL
 DF26 | Use Revocation list
 DF27 | Use Exception  list
 DF28 | TDOL
 DF30 | Online DOL
 DF62 | Application Selection Flag
 DF63 | Transaction Reference Currency Conversion
 
 @param aidName aidName AID name.  Example "a0000000031010"
 @param data NSDictionary with Tags/Values for the AID configuration file
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_setApplicationData:(NSString*)aidName configData:(NSMutableDictionary*)data;

/**
 * Set Certificate Authority Public Key
 *
 Sets the CAPK as specified by the CAKey structure
 
 @param key CAKey containing the RID, Index, and key data to set
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_setCAPK:(CAKey)key;

/**
 * Set Certificate Revocation List Entry
 *
 Sets the CRL entry as specified by the CRLEntry structure
 
 @param key CRLEntry containing the RID, Index, and serial number to set
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_setCRL:(CRLEntry)key;




/**
 * Set Terminal Data
 - UniPay II
 *
 Sets the Terminal Data as specified by the dictionary containing Tags (dictionary keys) and Values (dictionary objects) according to the following table
 
 Tag | Description
 ===== | =====
 9F1A | Terminal Country Code
 9F35 | Terminal Type
 9F33 | Terminal Capability
 9F40 | Additional Terminal Capability
 9F1E | IFD Serial Number
 9F15 | Merchant Category Code
 9F16 | Merchant Identifier
 9F1C | Terminal Identification
 9F4E | Merchant Name and Location
 DF10 | LANGUAGE
 DF11 | Use Trans Log
 DF13 | TAC-Default
 DF14 | TAC-Denial
 DF15 | TAC-Online
 DF17 | Threshold Value for Biased Random Selection
 DF18 | Target Percentage For Random Transaction Selection
 DF19 | Maximum Target Percentage For Random Transaction Selection
 DF20 | Trace
 DF22 | Merchant Forced Transaction Online
 DF25 | Default DDOL
 DF26 | Use Revocation list
 DF27 | Use Exception  list
 DF28 | TDOL
 DF30 | Online DOL
 DF62 | Application Selection Flag
 DF63 | Transaction Reference Currency
 Conversion

 
 @param data NSDictionary with Tags/Values for the Terminal configuration file
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) emv_setTerminalData:(NSMutableDictionary*)data;


/**
 * Start  Transaction Request
 *
 - UniPayII
 Authorizes the EMV transaction  for an ICC card
 
 The tags will be returned in the emvTransactionData delegate protocol.
 
 
  By default, auto authorize is ENABLED.  If auto authorize is DISABLED, this function will complete with a return of EMV_RESULT_CODE_START_TRANSACTION_SUCCESS to emvTransactionData delegate protocol, and then IDT_UniPayII::emv_authenticateTransaction() must be executed.  If auto authorize is ENABLED (default), IDT_UniPayII::emv_authenticateTransaction() will automatically be executed after receiving the result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS.  The auto authorize can be enabled/disabled with IDT_UniPayII::emv_disableAutoAuthenticateTransaction:()
 
 
 @param tags Transaction Tags
 @param fallback TRUE = support fallback
 @param timeout Timeout value in seconds.
 @param forceOnline Forces the transaction online
 
 Tags for transaction data
 Tag | Description
 ===== | =====
 9F02 | Amount, Authorised(Numeric)
 9C | Transaction Type
 5F2A | Transaction Currency Code
 9A | Transaction Date
 9F21 | Transaction Time
 9F03 | Amount, Other(Numeric)
 
 
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0xFF00: Accept the online transaction RETURN_CODE_EMV_APPROVED
 - 0xFF01: Decline the online transaction RETURN_CODE_EMV_DECLINED
 - 0xFF02: Request to go online RETURN_CODE_EMV_GO_ONLINE
 - 0xFF03: Transaction is terminated RETURN_CODE_EMV_FAILED
 - 0xFF05: ICC format error or ICC missing data error RETURN_CODE_EMV_SYSTEM_ERROR
 - 0xFF07: ICC didn't accept transaction RETURN_CODE_EMV_NOT_ACCEPTED
 - 0xFF0A: Application may fallback to magstripe technology RETURN_CODE_EMV_FALLBACK
 - 0xFF0C: Transaction was cancelled RETURN_CODE_EMV_CANCEL
 - 0xFF0D: Timeout RETURN_CODE_EMV_TIMEOUT
 - 0xFF0F: Other EMV Error RETURN_CODE_EMV_OTHER_ERROR
 - 0xFF10: Accept the offline transaction RETURN_CODE_EMV_OFFLINE_APPROVED
 - 0xFF11: Decline the offline transaction RETURN_CODE_EMV_OFFLINE_DECLINED
 
 
 
 \par Converting TLV to NSMutableDictionary
 
 EMV data is  received in TLV (Tag, Length, value) format:
 `950500000080009B02E8009F2701018A025A339F26080C552B9364D55CE5`
 
 This data contains the following EMV tags/values:
 
 Tag | Length | Value
 ----- | ----- | -----
 95 | 05 | 0000008000
 9B | 02 | E800
 9F27 | 01 | 01
 8A | 02 | 5A33
 9F26 | 08 | 0C552B9364D55CE5
 
 An example how to create an NSMutableDictionary with these values follows.
 
 @code
 -(NSMutableDictionary*) createTLVDict{
 
 NSMutableDictionary *emvTags = [[NSMutableDictionary alloc] initWithCapacity:0];
 
 [emvTags setObject:@"0000008000" forKey:@"95"];
 [emvTags setObject:@"E800" forKey:@"9B"];
 [emvTags setObject:@"01" forKey:@"9F27"];
 [emvTags setObject:@"5A33" forKey:@"8A"];
 [emvTags setObject:@"0C552B9364D55CE5" forKey:@"9F26"];
 
 return emvTags;
 
 }
 @endcode
 
 */

-(RETURN_CODE) emv_startTransaction:(NSMutableDictionary *)tags allowFallback:(BOOL)fallback timeout:(int)timeout forceOnline:(BOOL)forceOnline;






/**
 * Exchange APDU (unencrypted)
 
 *
 * Sends an APDU packet to the ICC.  If successful, response is returned in APDUResult class instance in response parameter.
 
 @param dataAPDU  APDU data packet
 @param response Unencrypted/encrypted parsed APDU response
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */

-(RETURN_CODE) icc_exchangeAPDU:(NSData*)dataAPDU response:(APDUResponse**)response;

/**
 * Exchange Encrypted APDU
 
 *
 * Sends an Encrypted APDU packet to the ICC.  If successful, response is returned in APDUResult class instance in response parameter.
 
 @param dataAPDU  APDU data packet
 @param ksn  KSN Value
 @param response Unencrypted/encrypted parsed APDU response
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */

-(RETURN_CODE) icc_exchangeEncryptedAPDU:(NSData*)dataAPDU ksn:(NSData*)ksn response:(APDUResponse**)response;

/**
 * Get APDU KSN
 
 *
 * Retrieves the KSN used in ICC Encypted APDU usage
 
 * @param ksn Returns the encrypted APDU packet KSN
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) icc_getAPDU_KSN:(NSData**)ksn;

/**
 * Get Reader Status
 
 *
 Returns the reader status
 
 @param readerStatus Pointer that will return with the ICCReaderStatus results.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 @code
 ICCReaderStatus readerStatus;
 RETURN_CODE rt = [[IDT_UniPayII sharedController] icc_getICCReaderStatus:&readerStatus];
 if(RETURN_CODE_DO_SUCCESS != rt){
 LOGI(@"Fail");
 }
 else{
 NSString *sta;
 if(readerStatus.iccPower)
 sta =@"[ICC Powered]";
 else
 sta = @"[ICC Power not Ready]";
 if(readerStatus.cardSeated)
 sta =[NSString stringWithFormat:@"%@,[Card Seated]", sta];
 else
 sta =[NSString stringWithFormat:@"%@,[Card not Seated]", sta];
 
 LOGI(@"Card Status = %@",sta);
 }
 @endcode
 */

-(RETURN_CODE) icc_getICCReaderStatus:(ICCReaderStatus**)readerStatus;




/**
 * Power Off ICC
 
 
 *
 * Powers down the ICC
 
 * @param error Returns the error, if any
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 If Success, empty
 If Failure, ASCII encoded data of error string
 */
-(RETURN_CODE) icc_powerOffICC:(NSString**)error;


/**
 * Power On ICC
 
 
 *
 * Power up the currently selected microprocessor card in the ICC reader
 *
 * @param response Response returned. If Success, ATR String. If Failure, ASCII encoded data of error string
 *
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 
 
 */
-(RETURN_CODE) icc_powerOnICC:(NSData**)response;




/**
 * Set ICC Notifications
 *
 Determins if card insert/remove events are captured and sent to delegate UniPay_EventFunctionICC
 
 
 @param turnON  TRUE = monitor ICC card events, FALSE = ignore ICC card events.  Default value is FALSE/OFF.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) icc_setICCNotification:(BOOL)turnON;






/**
 * Backlight Control
 
 *
 Turns on/off the backlight of the UniPay II.
 *
 
 @param turnON TRUE = Turn On, FALSE = Turn Off
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */

-(RETURN_CODE) lcd_backlightControl:(BOOL)turnON;

/**
 * Clear Display
 
 *
 Clears the display of the UniPay II.
 *
 
 @param option 0=Clear First Line, 1 = Clear Second Line, 2= Clear Both Lines
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */

-(RETURN_CODE) lcd_clearDisplay:(int)option;

/**
 Display a message on either line 1 or line 2  in the UniPayII LCD.
 
 @param message Display message, up to 16 characters
 @param line 0 = First Line, 1 = Second Line
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) lcd_DisplayMessage:(NSString*)message lineNumber:(int)line;



/**
 Display a Prompt stored in UniPay.
 
 @param prompt Prompt number, 0-9
 @param line 0 = First Line, 1 = Second Line
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) lcd_DisplayPrompt:(int)prompt lineNumber:(int)line;

/**
 * Get Backlight Status
 *
 * Returns the backlight status of the UniPayII Display
 *
 * @param response Staus = "ON" or "OFF"
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) lcd_getBacklightStatus:(NSString**)response;

/**
 Saves a prompt into UniPay memory.
 
 @param message Prompt message, up to 16 characters
 @param location Memory location 0-9
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) lcd_savePrompt:(NSString*)message location:(int)location;

/**
 * Disable MSR Swipe
 
 
 
 Cancels MSR swipe request.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 */

-(RETURN_CODE) msr_cancelMSRSwipe;



/**
 * Get Clear PAN Digits
 *
 * Returns the number of digits that begin the PAN that will be in the clear
 *
 * @param response Number of digits in clear.  Values are ASCII '0' - '6':
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) msr_getClearPANID:(NSString**)response;


/**
 * Get Expiration Masking
 *
 * Get the flag that determines if to mask the expiration date
 *
 * @param response '0' = masked, '1' = not-masked
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) msr_getExpirationMask:(NSString**)response;



/**
 * Get Swipe Data Encryption
 *
 * Gets the swipe force encryption options
 *
 * @param response A string with for flags separated by PIPE character  f1|f2|f3|f4, example "1|0|0|1" where:
 - f1 = Track 1 Force Encrypt
 - f2 = Track 2 Force Encrypt
 - f3 = Track 3 Force Encrypt
 - f4 = Track 3 Force Encrypt when card type is 0
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) msr_getSwipeForcedEncryptionOption:(NSString**)response;

/**
 * Get Swipe Mask Option
 *
 * Gets the swipe mask/clear data sending option
 *
 * @param response A string with for flags separated by PIPE character  f1|f2|f3, example "1|0|0" where:
 - f1 = Track 1 Mask Allowed
 - f2 = Track 2 Mask Allowed
 - f3 = Track 3 Mask Allowed
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) msr_getSwipeMaskOption:(NSString**)response;




/**
 * Set Clear PAN Digits
 *
 * Sets the amount of digits shown in the clear (not masked) at the beginning of the returned PAN value
 *
 @param digits Number of digits to show in clear.  Range 0-6.
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE) msr_setClearPANID:(int)digits;



/**
 * Set Expiration Masking
 *
 * Sets the flag to mask the expiration date
 *
 @param masked TRUE = mask expiration
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE) msr_setExpirationMask:(BOOL)masked;





/**
 * Set Swipe Force Encryption
 *
 * Sets the swipe force encryption options
 *
 @param track1 Force encrypt track 1
 @param track2 Force encrypt track 2
 @param track3 Force encrypt track 3
 @param track3card0 Force encrypt track 3 when card type is 0
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE) msr_setSwipeForcedEncryptionOption:(BOOL)track1 track2:(BOOL)track2 track3:(BOOL)track3 track3card0:(BOOL)track3card0;



/**
 * Set Swipe Mask Option
 *
 * Sets the swipe mask/clear data sending option
 *
 @param track1 Mask track 1 allowed
 @param track2 Mask track 2 allowed
 @param track3 Mask track 3 allowed
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE) msr_setSwipeMaskOption:(BOOL)track1 track2:(BOOL)track2 track3:(BOOL)track3;


/**
 * Enable MSR Swipe
 
 *
 Enables MSR, waiting for swipe to occur. Allows track selection. Returns IDTMSRData instance to deviceDelegate::swipeMSRData:()
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 
 */

-(RETURN_CODE) msr_startMSRSwipe;

/**
 * Cancel PIN Command
 *
 
 This command can cancel IDT_UniPayII:pin_getEncryptedPIN:keyType:message:() and IDT_UniPayII::pin_getNumeric:minLength:maxLength:messageID:language:() and IDT_UniPayII::pin_getAmount:maxLength:messageID:language:() and IDT_UniPayII::pin_getCardAccount:max:line1:line2:() and 
     IDT_UniPayII::pin_getFunctionKey() and
     IDT_UniPayII::pin_getEncryptedData:minLength:maxLength:messageID:language:() */
-(RETURN_CODE) pin_cancelPin;


/**
 * Display Message and Get Amount
 
 *
 Decrypt and display message on LCD. Requires secure message data. Returns value in inputValue of deviceDelegate::pinpadData:keySN:event:() with event EVENT_PINPAD_AMOUNT
 
 @param minLength Minimum account number length - not less than 1
 @param maxLength Maximum account number length - not more than 15
 @param mID Message ID from approved message list.
 @param lang Language file to use for message
 @code
 typedef enum{
 LANGUAGE_TYPE_ENGLISH,
 LANGUAGE_TYPE_PORTUGUESE,
 LANGUAGE_TYPE_SPANISH,
 LANGUAGE_TYPE_FRENCH
 }LANGUAGE_TYPE;
 @endcode
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 \par Notes
 - If there is no any enter in 3 minutes, this command will time out.
 - If there is no any enter in 20 seconds, the entered namount key will be cleared.
 - When press Enter key , it will end this Command and response package with NGA  format .
 - When press Cancel key, the entered amount key will be cleared and if press Cancel key again, this command terminated.
 - Cancel Command can terminate this command.
 
 \par Secure Messages
 Secure messages to be used with General Prompts commands
 
 Msg Id |English Prompt | Portuguese Prompt | Spanish Prompt | French Prompt
 ---------- | ---------- | ----------  | ---------- | ----------
 1 | ENTER | ENTER | INGRESE | ENTREZ
 2 | REENTER | RE-INTRODUZIR | REINGRESE | RE-ENTREZ
 3 | ENTER YOUR | INTRODUZIR O SEU | INGRESE SU | ENTREZ VOTRE
 4 | REENTER YOUR | RE-INTRODUZIR O SEU | REINGRESE SU | RE-ENTREZ VOTRE
 5 | PLEASE ENTER | POR FAVOR DIGITE | POR FAVOR INGRESE | SVP ENTREZ
 6 | PLEASE REENTER | POR FAVO REENTRAR | POR FAVO REINGRESE | SVP RE-ENTREZ
 7 | PO NUMBER | NÚMERO PO | NUMERO PO | No COMMANDE
 8 | DRIVER ID | LICENÇA | LICENCIA | ID CONDUCTEUR
 9 | ODOMETER | ODOMETER | ODOMETRO | ODOMETRE
 10 | ID NUMBER | NÚMERO ID | NUMERO ID | No IDENT
 11 | EQUIP CODE | EQUIP CODE | CODIGO EQUIP | CODE EQUIPEMENT
 12 | DRIVERS ID | DRIVER ID | ID CONDUCTOR | ID CONDUCTEUR
 13 | JOB NUMBER | EMP NÚMERO | NUMERO EMP | No TRAVAIL
 14 | WORK ORDER | TRABALHO ORDEM | ORDEN TRABAJO | FICHE TRAVAIL
 15 | VEHICLE ID | ID VEÍCULO | ID VEHICULO | ID VEHICULE
 16 | ENTER DRIVER | ENTER DRIVER | INGRESE CONDUCTOR | ENTR CONDUCTEUR
 17 | ENTER DEPT | ENTER DEPT | INGRESE DEPT | ENTR DEPARTEMNT
 18 | ENTER PHONE | ADICIONAR PHONE | INGRESE TELEFONO | ENTR No TELEPH
 19 | ENTER ROUTE | ROUTE ADD | INGRESE RUTA | ENTREZ ROUTE
 20 | ENTER FLEET | ENTER FROTA | INGRESE FLOTA | ENTREZ PARC AUTO
 21 | ENTER JOB ID | ENTER JOB ID | INGRESE ID TRABAJO | ENTR ID TRAVAIL
 22 | ROUTE NUMBER | NÚMERO PATH | RUTA NUMERO | No ROUTE
 23 | ENTER USER ID | ENTER USER ID | INGRESE ID USUARIO | ID UTILISATEUR
 24 | FLEET NUMBER | NÚMERO DE FROTA | FLOTA NUMERO | No PARC AUTO
 25 | ENTER PRODUCT | ADICIONAR PRODUTO | INGRESE PRODUCTO | ENTREZ PRODUIT
 26 | DRIVER NUMBER | NÚMERO DRIVER | CONDUCTOR NUMERO | No CONDUCTEUR
 27 | ENTER LICENSE | ENTER LICENÇA | INGRESE LICENCIA | ENTREZ PERMIS
 28 | ENTER FLEET NO | ENTER NRO FROTA | INGRESE NRO FLOTA | ENT No PARC AUTO
 29 | ENTER CAR WASH | WASH ENTER | INGRESE LAVADO | ENTREZ LAVE-AUTO
 30 | ENTER VEHICLE | ENTER VEÍCULO | INGRESE VEHICULO | ENTREZ VEHICULE
 31 | ENTER TRAILER | TRAILER ENTER | INGRESE TRAILER | ENTREZ REMORQUE
 32 | ENTER ODOMETER | ENTER ODOMETER | INGRESE ODOMETRO | ENTREZ ODOMETRE
 33 | DRIVER LICENSE | CARTEIRA DE MOTORISTA | LICENCIA CONDUCTOR | PERMIS CONDUIRE
 34 | ENTER CUSTOMER | ENTER CLIENTE | INGRESE CLIENTE | ENTREZ CLIENT
 35 | VEHICLE NUMBER | NÚMERO DO VEÍCULO | VEHICULO NUMERO | No VEHICULE
 36 | ENTER CUST DATA | ENTER CLIENTE INFO | INGRESE INFO CLIENTE | INFO CLIENT
 37 | REENTER DRIVID | REENTRAR DRIVER ID | REINGRESE ID CHOFER | RE-ENTR ID COND
 38 | ENTER USER DATA | ENTER INFO USUÁRIO | INGRESE INFO USUARIO | INFO UTILISATEUR
 39 | ENTER CUST CODE | ENTER CODE. CLIENTE | INGRESE COD. CLIENTE | ENTR CODE CLIENT
 40 | ENTER EMPLOYEE | ENTER FUNCIONÁRIO | INGRESE EMPLEADO | ENTREZ EMPLOYE
 41 | ENTER ID NUMBER | ENTER NÚMERO ID | INGRESE NUMERO ID | ENTREZ No ID
 42 | ENTER DRIVER ID | ENTER ID DRIVER | INGRESE ID CONDUCTOR | No CONDUCTEUR
 43 | ENTER FLEET PIN | ENTER PIN FROTA | INGRESE PIN DE FLOTA | NIP PARC AUTO
 44 | ODOMETER NUMBER | NÚMERO ODOMETER | ODOMETRO NUMERO | No ODOMETRE
 45 | ENTER DRIVER LIC | ENTER DRIVER LIC | INGRESE LIC CONDUCTOR | PERMIS CONDUIRE
 46 | ENTER TRAILER NO | NRO TRAILER ENTER | INGRESE NRO TRAILER | ENT No REMORQUE
 47 | REENTER VEHICLE | REENTRAR VEÍCULO | REINGRESE VEHICULO | RE-ENTR VEHICULE
 48 | ENTER VEHICLE ID | ENTER VEÍCULO ID | INGRESE ID VEHICULO | ENTR ID VEHICULE
 49 | ENTER BIRTH DATE | INSERIR DATA NAC | INGRESE FECHA NAC | ENT DT NAISSANCE
 50 | ENTER DOB MMDDYY | ENTER FDN MMDDYY | INGRESE FDN MMDDAA | NAISSANCE MMJJAA
 51 | ENTER FLEET DATA | ENTER FROTA INFO | INGRESE INFO DE FLOTA | INFO PARC AUTO
 52 | ENTER REFERENCE | ENTER REFERÊNCIA | INGRESE REFERENCIA | ENTREZ REFERENCE
 53 | ENTER AUTH NUMBR | ENTER NÚMERO AUT | INGRESE NUMERO AUT | No AUTORISATION
 54 | ENTER HUB NUMBER | ENTER HUB NRO | INGRESE NRO HUB | ENTREZ No NOYAU
 55 | ENTER HUBOMETER | MEDIDA PARA ENTRAR HUB | INGRESE MEDIDO DE HUB | COMPTEUR NOYAU
 56 | ENTER TRAILER ID | TRAILER ENTER ID | INGRESE ID TRAILER | ENT ID REMORQUE
 57 | ODOMETER READING | QUILOMETRAGEM | LECTURA ODOMETRO | LECTURE ODOMETRE
 58 | REENTER ODOMETER | REENTRAR ODOMETER | REINGRESE ODOMETRO | RE-ENT ODOMETRE
 59 | REENTER DRIV. ID | REENTRAR DRIVER ID | REINGRESE ID CHOFER | RE-ENT ID CONDUC
 60 | ENTER CUSTOMER ID | ENTER CLIENTE ID | INGRESE ID CLIENTE | ENTREZ ID CLIENT
 61 | ENTER CUST. ID | ENTER CLIENTE ID | INGRESE ID CLIENTE | ENTREZ ID CLIENT
 62 | ENTER ROUTE NUM | ENTER NUM ROUTE | INGRESE NUM RUTA | ENT No ROUTE
 63 | ENTER FLEET NUM | FROTA ENTER NUM | INGRESE NUM FLOTA | ENT No PARC AUTO
 64 | FLEET PIN | FROTA PIN | PIN DE FLOTA | NIP PARC AUTO
 65 | DRIVER # | DRIVER # | CONDUCTOR # | CONDUCTEUR
 66 | ENTER DRIVER # | ENTER DRIVER # | INGRESE CONDUCTOR # | ENT # CONDUCTEUR
 67 | VEHICLE # | VEÍCULO # | VEHICULO # | # VEHICULE
 68 | ENTER VEHICLE # | ENTER VEÍCULO # | INGRESE VEHICULO # | ENT # VEHICULE
 69 | JOB # | TRABALHO # | TRABAJO # | # TRAVAIL
 70 | ENTER JOB # | ENTER JOB # | INGRESE TRABAJO # | ENTREZ # TRAVAIL
 71 | DEPT NUMBER | NÚMERO DEPT | NUMERO DEPTO | No DEPARTEMENT
 72 | DEPARTMENT # | DEPARTAMENTO # | DEPARTAMENTO # | DEPARTEMENT
 73 | ENTER DEPT # | ENTER DEPT # | INGRESE DEPTO # | ENT# DEPARTEMENT
 74 | LICENSE NUMBER | NÚMERO DE LICENÇA | NUMERO LICENCIA | No PERMIS
 75 | LICENSE # | LICENÇA # | LICENCIA # | # PERMIS
 76 | ENTER LICENSE # | ENTER LICENÇA # | INGRESE LICENCIA # | ENTREZ # PERMIS
 77 | DATA | INFO | INFO | INFO
 78 | ENTER DATA | ENTER INFO | INGRESE INFO | ENTREZ INFO
 79 | CUSTOMER DATA | CLIENTE INFO | INFO CLIENTE | INFO CLIENT
 80 | ID # | ID # | ID # | # ID
 81 | ENTER ID # | ENTER ID # | INGRESE ID # | ENTREZ # ID
 82 | USER ID | USER ID | ID USUARIO | ID UTILISATEUR
 83 | ROUTE # | ROUTE # | RUTA # | # ROUTE
 84 | ENTER ROUTE # | ADD ROUTE # | INGRESE RUTA # | ENTREZ # ROUTE
 85 | ENTER CARD NUM | ENTER NÚMERO DE CARTÃO | INGRESE NUM TARJETA | ENTREZ NO CARTE
 86 | EXP DATE(YYMM) | VALIDADE VAL (AAMM) | FECHA EXP (AAMM) | DATE EXPIR(AAMM)
 87 | PHONE NUMBER | TELEFONE | NUMERO TELEFONO | NO TEL
 88 | CVV START DATE | CVV DATA DE INÍCIO | CVV FECHA INICIO | CVV DATE DE DEBUT
 89 | ISSUE NUMBER | NÚMERO DE EMISSÃO | NUMERO DE EMISION | NO DEMISSION
 90 | START DATE (MMYY) | DATA DE INÍCIO (AAMM) | FECHA INICIO (AAMM) | DATE DE DEBUT-AAMM
 */
-(RETURN_CODE) pin_getAmount:(int)minLength maxLength:(int)maxLength messageID:(int)mID language:(LANGUAGE_TYPE)lang;


/**
 * Display Message and Get Card Account
 
 *
 Show message on LCD and get card account number from keypad, then return encrypted card account number. Returns encryptedData of entered account in deviceDelegate::pinpadData:keySN:event:() with event EVENT_PINPAD_ACCOUNT
 
 @param minLength Minimum account number length - not less than 12
 @param maxLength Maximum account number length - not more than 20
 @param message Display message, up to 16 characters
 -
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 \par Notes
 - If  there is no any enter in 3 minutes, this command time out.
 - If  there is no any enter in 20 seconds, the entered account numbers will be cleared.
 - When press Enter key, it will end this command and respond package with NGA format.
 - When press Cancel key, the entered account numbers will be cleared and if press Cancel key again, this command terminated.
 - Cancel command can terminate this command.
 */
-(RETURN_CODE) pin_getCardAccount:(int)minLength max:(int)maxLength message:(NSString*)message;


/**
 * Get Function Key
 *
 @param response Returns the key pressed mapped to ASCII according to the following table:
 - "C": Cancel Key
 - "B": Backspace Key
 - "E": Enter Key
 - "F1": F1 Key
 - "F2": F2 Key
 
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 \par Notes
 - If there is no any entry in 3 minutes, this command will time out.
 - Cancel Command can terminate this command.
 
 */
-(RETURN_CODE) pin_getFunctionKey:(NSString**)response;

/**
 Get Numeric Length
 
 * Returns Numeric Length
 *
 @param response Returned Value of Minimum/Maximum Numeric length:
 - response[0] = minimum length
 - response[1] = maximum length
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 @code
 NSData* res;
 RETURN_CODE rt = [[IDT_UniPayII sharedController] pin_getNumericLength:&res];
 uint8_t b[res.length];
 [data getBytes:b];
 if(RETURN_CODE_DO_SUCCESS == rt && res.length>1){
 LOGI(@"GetNumericLength: min=%d max=%d", b[0], b[1]);
 }
 @endcode
 */
-(RETURN_CODE) pin_getNumericLength:(NSData**)response;

/**
 Get PIN Length
 
 * Returns encrypted PIN Length
 *
 @param response Returned Value of Minimum/Maximum PIN length:
 - response[0] = minimum length
 - response[1] = maximum length
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 @code
 NSData* res;
 RETURN_CODE rt = [[IDT_UniPayII sharedController] pin_getPinLength:&res];
 uint8_t b[res.length];
 [data getBytes:b];
 if(RETURN_CODE_DO_SUCCESS == rt && res.length>1){
 LOGI(@"GetPinLength: min=%d max=%d", b[0], b[1]);
 }
 @endcode
 */
-(RETURN_CODE) pin_getPinLength:(NSData**)response;






/**
 * Display Message and Get Encrypted Data
 
 *
 Decrypt and display message on LCD. Prompts the user with up to 2 lines of text. Returns value of encrypted data (using MSR DUKPT key) and KSN to deviceDelegate::pinpadData:keySN:event:() with event EVENT_PINPAD_ENCRYPTED_DATA
 
 @param lastPackage Last package flag
 @param minLength Minimum account number length - not less than 1
 @param maxLength Maximum account number length - not more than 16
 @param mID Message ID from approved message list.
 @param lang Language file to use for message
 @code
 typedef enum{
 LANGUAGE_TYPE_ENGLISH,
 LANGUAGE_TYPE_PORTUGUESE,
 LANGUAGE_TYPE_SPANISH,
 LANGUAGE_TYPE_FRENCH
 }LANGUAGE_TYPE;
 @endcode
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 \par Notes
 
 -  If  there is no any enter in 3 minutes, this command time out.
 -  If  there is no any enter in 20 seconds, the entered account numbers will be cleared.
 -  When press Enter key, it will end this command and respond package with NGA format.
 -  When press Cancel key, the entered account numbers will be cleared and if press Cancel key again, this command terminated.
 -  Cancel command can terminate this command.
 -  Maximum pattern number allowed is 10. If any error or invalid command is sent, input data patterns will be cleared and command fail.
 
 \par Secure Messages
 Secure messages to be used with General Prompts commands
 
 Msg Id |English Prompt | Portuguese Prompt | Spanish Prompt | French Prompt
 ---------- | ---------- | ----------  | ---------- | ----------
 1 | ENTER | ENTER | INGRESE | ENTREZ
 2 | REENTER | RE-INTRODUZIR | REINGRESE | RE-ENTREZ
 3 | ENTER YOUR | INTRODUZIR O SEU | INGRESE SU | ENTREZ VOTRE
 4 | REENTER YOUR | RE-INTRODUZIR O SEU | REINGRESE SU | RE-ENTREZ VOTRE
 5 | PLEASE ENTER | POR FAVOR DIGITE | POR FAVOR INGRESE | SVP ENTREZ
 6 | PLEASE REENTER | POR FAVO REENTRAR | POR FAVO REINGRESE | SVP RE-ENTREZ
 7 | PO NUMBER | NÚMERO PO | NUMERO PO | No COMMANDE
 8 | DRIVER ID | LICENÇA | LICENCIA | ID CONDUCTEUR
 9 | ODOMETER | ODOMETER | ODOMETRO | ODOMETRE
 10 | ID NUMBER | NÚMERO ID | NUMERO ID | No IDENT
 11 | EQUIP CODE | EQUIP CODE | CODIGO EQUIP | CODE EQUIPEMENT
 12 | DRIVERS ID | DRIVER ID | ID CONDUCTOR | ID CONDUCTEUR
 13 | JOB NUMBER | EMP NÚMERO | NUMERO EMP | No TRAVAIL
 14 | WORK ORDER | TRABALHO ORDEM | ORDEN TRABAJO | FICHE TRAVAIL
 15 | VEHICLE ID | ID VEÍCULO | ID VEHICULO | ID VEHICULE
 16 | ENTER DRIVER | ENTER DRIVER | INGRESE CONDUCTOR | ENTR CONDUCTEUR
 17 | ENTER DEPT | ENTER DEPT | INGRESE DEPT | ENTR DEPARTEMNT
 18 | ENTER PHONE | ADICIONAR PHONE | INGRESE TELEFONO | ENTR No TELEPH
 19 | ENTER ROUTE | ROUTE ADD | INGRESE RUTA | ENTREZ ROUTE
 20 | ENTER FLEET | ENTER FROTA | INGRESE FLOTA | ENTREZ PARC AUTO
 21 | ENTER JOB ID | ENTER JOB ID | INGRESE ID TRABAJO | ENTR ID TRAVAIL
 22 | ROUTE NUMBER | NÚMERO PATH | RUTA NUMERO | No ROUTE
 23 | ENTER USER ID | ENTER USER ID | INGRESE ID USUARIO | ID UTILISATEUR
 24 | FLEET NUMBER | NÚMERO DE FROTA | FLOTA NUMERO | No PARC AUTO
 25 | ENTER PRODUCT | ADICIONAR PRODUTO | INGRESE PRODUCTO | ENTREZ PRODUIT
 26 | DRIVER NUMBER | NÚMERO DRIVER | CONDUCTOR NUMERO | No CONDUCTEUR
 27 | ENTER LICENSE | ENTER LICENÇA | INGRESE LICENCIA | ENTREZ PERMIS
 28 | ENTER FLEET NO | ENTER NRO FROTA | INGRESE NRO FLOTA | ENT No PARC AUTO
 29 | ENTER CAR WASH | WASH ENTER | INGRESE LAVADO | ENTREZ LAVE-AUTO
 30 | ENTER VEHICLE | ENTER VEÍCULO | INGRESE VEHICULO | ENTREZ VEHICULE
 31 | ENTER TRAILER | TRAILER ENTER | INGRESE TRAILER | ENTREZ REMORQUE
 32 | ENTER ODOMETER | ENTER ODOMETER | INGRESE ODOMETRO | ENTREZ ODOMETRE
 33 | DRIVER LICENSE | CARTEIRA DE MOTORISTA | LICENCIA CONDUCTOR | PERMIS CONDUIRE
 34 | ENTER CUSTOMER | ENTER CLIENTE | INGRESE CLIENTE | ENTREZ CLIENT
 35 | VEHICLE NUMBER | NÚMERO DO VEÍCULO | VEHICULO NUMERO | No VEHICULE
 36 | ENTER CUST DATA | ENTER CLIENTE INFO | INGRESE INFO CLIENTE | INFO CLIENT
 37 | REENTER DRIVID | REENTRAR DRIVER ID | REINGRESE ID CHOFER | RE-ENTR ID COND
 38 | ENTER USER DATA | ENTER INFO USUÁRIO | INGRESE INFO USUARIO | INFO UTILISATEUR
 39 | ENTER CUST CODE | ENTER CODE. CLIENTE | INGRESE COD. CLIENTE | ENTR CODE CLIENT
 40 | ENTER EMPLOYEE | ENTER FUNCIONÁRIO | INGRESE EMPLEADO | ENTREZ EMPLOYE
 41 | ENTER ID NUMBER | ENTER NÚMERO ID | INGRESE NUMERO ID | ENTREZ No ID
 42 | ENTER DRIVER ID | ENTER ID DRIVER | INGRESE ID CONDUCTOR | No CONDUCTEUR
 43 | ENTER FLEET PIN | ENTER PIN FROTA | INGRESE PIN DE FLOTA | NIP PARC AUTO
 44 | ODOMETER NUMBER | NÚMERO ODOMETER | ODOMETRO NUMERO | No ODOMETRE
 45 | ENTER DRIVER LIC | ENTER DRIVER LIC | INGRESE LIC CONDUCTOR | PERMIS CONDUIRE
 46 | ENTER TRAILER NO | NRO TRAILER ENTER | INGRESE NRO TRAILER | ENT No REMORQUE
 47 | REENTER VEHICLE | REENTRAR VEÍCULO | REINGRESE VEHICULO | RE-ENTR VEHICULE
 48 | ENTER VEHICLE ID | ENTER VEÍCULO ID | INGRESE ID VEHICULO | ENTR ID VEHICULE
 49 | ENTER BIRTH DATE | INSERIR DATA NAC | INGRESE FECHA NAC | ENT DT NAISSANCE
 50 | ENTER DOB MMDDYY | ENTER FDN MMDDYY | INGRESE FDN MMDDAA | NAISSANCE MMJJAA
 51 | ENTER FLEET DATA | ENTER FROTA INFO | INGRESE INFO DE FLOTA | INFO PARC AUTO
 52 | ENTER REFERENCE | ENTER REFERÊNCIA | INGRESE REFERENCIA | ENTREZ REFERENCE
 53 | ENTER AUTH NUMBR | ENTER NÚMERO AUT | INGRESE NUMERO AUT | No AUTORISATION
 54 | ENTER HUB NUMBER | ENTER HUB NRO | INGRESE NRO HUB | ENTREZ No NOYAU
 55 | ENTER HUBOMETER | MEDIDA PARA ENTRAR HUB | INGRESE MEDIDO DE HUB | COMPTEUR NOYAU
 56 | ENTER TRAILER ID | TRAILER ENTER ID | INGRESE ID TRAILER | ENT ID REMORQUE
 57 | ODOMETER READING | QUILOMETRAGEM | LECTURA ODOMETRO | LECTURE ODOMETRE
 58 | REENTER ODOMETER | REENTRAR ODOMETER | REINGRESE ODOMETRO | RE-ENT ODOMETRE
 59 | REENTER DRIV. ID | REENTRAR DRIVER ID | REINGRESE ID CHOFER | RE-ENT ID CONDUC
 60 | ENTER CUSTOMER ID | ENTER CLIENTE ID | INGRESE ID CLIENTE | ENTREZ ID CLIENT
 61 | ENTER CUST. ID | ENTER CLIENTE ID | INGRESE ID CLIENTE | ENTREZ ID CLIENT
 62 | ENTER ROUTE NUM | ENTER NUM ROUTE | INGRESE NUM RUTA | ENT No ROUTE
 63 | ENTER FLEET NUM | FROTA ENTER NUM | INGRESE NUM FLOTA | ENT No PARC AUTO
 64 | FLEET PIN | FROTA PIN | PIN DE FLOTA | NIP PARC AUTO
 65 | DRIVER # | DRIVER # | CONDUCTOR # | CONDUCTEUR
 66 | ENTER DRIVER # | ENTER DRIVER # | INGRESE CONDUCTOR # | ENT # CONDUCTEUR
 67 | VEHICLE # | VEÍCULO # | VEHICULO # | # VEHICULE
 68 | ENTER VEHICLE # | ENTER VEÍCULO # | INGRESE VEHICULO # | ENT # VEHICULE
 69 | JOB # | TRABALHO # | TRABAJO # | # TRAVAIL
 70 | ENTER JOB # | ENTER JOB # | INGRESE TRABAJO # | ENTREZ # TRAVAIL
 71 | DEPT NUMBER | NÚMERO DEPT | NUMERO DEPTO | No DEPARTEMENT
 72 | DEPARTMENT # | DEPARTAMENTO # | DEPARTAMENTO # | DEPARTEMENT
 73 | ENTER DEPT # | ENTER DEPT # | INGRESE DEPTO # | ENT# DEPARTEMENT
 74 | LICENSE NUMBER | NÚMERO DE LICENÇA | NUMERO LICENCIA | No PERMIS
 75 | LICENSE # | LICENÇA # | LICENCIA # | # PERMIS
 76 | ENTER LICENSE # | ENTER LICENÇA # | INGRESE LICENCIA # | ENTREZ # PERMIS
 77 | DATA | INFO | INFO | INFO
 78 | ENTER DATA | ENTER INFO | INGRESE INFO | ENTREZ INFO
 79 | CUSTOMER DATA | CLIENTE INFO | INFO CLIENTE | INFO CLIENT
 80 | ID # | ID # | ID # | # ID
 81 | ENTER ID # | ENTER ID # | INGRESE ID # | ENTREZ # ID
 82 | USER ID | USER ID | ID USUARIO | ID UTILISATEUR
 83 | ROUTE # | ROUTE # | RUTA # | # ROUTE
 84 | ENTER ROUTE # | ADD ROUTE # | INGRESE RUTA # | ENTREZ # ROUTE
 85 | ENTER CARD NUM | ENTER NÚMERO DE CARTÃO | INGRESE NUM TARJETA | ENTREZ NO CARTE
 86 | EXP DATE(YYMM) | VALIDADE VAL (AAMM) | FECHA EXP (AAMM) | DATE EXPIR(AAMM)
 87 | PHONE NUMBER | TELEFONE | NUMERO TELEFONO | NO TEL
 88 | CVV START DATE | CVV DATA DE INÍCIO | CVV FECHA INICIO | CVV DATE DE DEBUT
 89 | ISSUE NUMBER | NÚMERO DE EMISSÃO | NUMERO DE EMISION | NO DEMISSION
 90 | START DATE (MMYY) | DATA DE INÍCIO (AAMM) | FECHA INICIO (AAMM) | DATE DE DEBUT-AAMM
 */
-(RETURN_CODE) pin_getEncryptedData:(BOOL)lastPackage minLength:(int)minLength maxLength:(int)maxLength messageID:(int)mID language:(LANGUAGE_TYPE)lang;

/**
 * Display Message and Get Encrypted PIN online
 *
 Prompts the user with up to 3 lines of text. Returns pinblock/ksn of entered PIN value in deviceDelegate::pinpadData:keySN:event:() with event MessageID_PINEntry
 
 @param account Card account number
 @param type Encryption Key Type:
 - 0x00: External Account Key Plain Text PIN_KEY_TDES_MKSK_extp
 - 0x01: External Account Key Plain Text PIN_KEY_TDES_DUKPT_extp
 - 0x20: Internal Account Key PIN_KEY_TDES_MKSK2_intl
 - 0x21: Internal Account Key PIN_KEY_TDES_DUKPT2_intl
 @param message Display message up to 16 characters
 
 
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 \par Notes
 - If there is no any enter in 3 minutes, this command will time out.
 - If there is no any enter in 20 seconds, the entered PIN key will be cleared.
 - When press Enter key , it will end this Command and response package with NGA format .
 - When press Cancel key, the entered PIN  key will be cleared and if press Cancel key again, this command terminated.
 - Cancel Command can terminate this command.
 
 */
-(RETURN_CODE) pin_getEncryptedPIN:(NSString*)account keyType:(PIN_KEY_Types)type message:(NSString*)message;

/**
 * Display Message and Get Numeric Key(s)
 
 *
 Decrypt and display message on LCD. Requires secure message data. Returns value in inputValue of deviceDelegate::pinpadData:keySN:event:() with event EVENT_PINPAD_NUMERIC
 
 @param maskInput If true, all entered data will be masked with asterik (*)
 @param minLength Minimum account number length - not less than 1
 @param maxLength Maximum account number length - not more than 16
 @param mID Message ID from approved message list.
 @param lang Language file to use for message
 @code
 typedef enum{
 LANGUAGE_TYPE_ENGLISH,
 LANGUAGE_TYPE_PORTUGUESE,
 LANGUAGE_TYPE_SPANISH,
 LANGUAGE_TYPE_FRENCH
 }LANGUAGE_TYPE;
 @endcode
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 \par Notes
 - If there is no any enter in 3 minutes, this command will time out.
 - If there is no any enter in 20 seconds, the entered numeric key will be cleared.
 - When press Enter key , it will end this Command and response package with NGA  format .
 - When press Cancel key, the entered numeric key will be cleared and if press Cancel key again, this command terminated.
 - Cancel Command can terminate this command.
 
 \par Secure Messages
 Secure messages to be used with General Prompts commands
 
 Msg Id |English Prompt | Portuguese Prompt | Spanish Prompt | French Prompt
 ---------- | ---------- | ----------  | ---------- | ----------
 1 | ENTER | ENTER | INGRESE | ENTREZ
 2 | REENTER | RE-INTRODUZIR | REINGRESE | RE-ENTREZ
 3 | ENTER YOUR | INTRODUZIR O SEU | INGRESE SU | ENTREZ VOTRE
 4 | REENTER YOUR | RE-INTRODUZIR O SEU | REINGRESE SU | RE-ENTREZ VOTRE
 5 | PLEASE ENTER | POR FAVOR DIGITE | POR FAVOR INGRESE | SVP ENTREZ
 6 | PLEASE REENTER | POR FAVO REENTRAR | POR FAVO REINGRESE | SVP RE-ENTREZ
 7 | PO NUMBER | NÚMERO PO | NUMERO PO | No COMMANDE
 8 | DRIVER ID | LICENÇA | LICENCIA | ID CONDUCTEUR
 9 | ODOMETER | ODOMETER | ODOMETRO | ODOMETRE
 10 | ID NUMBER | NÚMERO ID | NUMERO ID | No IDENT
 11 | EQUIP CODE | EQUIP CODE | CODIGO EQUIP | CODE EQUIPEMENT
 12 | DRIVERS ID | DRIVER ID | ID CONDUCTOR | ID CONDUCTEUR
 13 | JOB NUMBER | EMP NÚMERO | NUMERO EMP | No TRAVAIL
 14 | WORK ORDER | TRABALHO ORDEM | ORDEN TRABAJO | FICHE TRAVAIL
 15 | VEHICLE ID | ID VEÍCULO | ID VEHICULO | ID VEHICULE
 16 | ENTER DRIVER | ENTER DRIVER | INGRESE CONDUCTOR | ENTR CONDUCTEUR
 17 | ENTER DEPT | ENTER DEPT | INGRESE DEPT | ENTR DEPARTEMNT
 18 | ENTER PHONE | ADICIONAR PHONE | INGRESE TELEFONO | ENTR No TELEPH
 19 | ENTER ROUTE | ROUTE ADD | INGRESE RUTA | ENTREZ ROUTE
 20 | ENTER FLEET | ENTER FROTA | INGRESE FLOTA | ENTREZ PARC AUTO
 21 | ENTER JOB ID | ENTER JOB ID | INGRESE ID TRABAJO | ENTR ID TRAVAIL
 22 | ROUTE NUMBER | NÚMERO PATH | RUTA NUMERO | No ROUTE
 23 | ENTER USER ID | ENTER USER ID | INGRESE ID USUARIO | ID UTILISATEUR
 24 | FLEET NUMBER | NÚMERO DE FROTA | FLOTA NUMERO | No PARC AUTO
 25 | ENTER PRODUCT | ADICIONAR PRODUTO | INGRESE PRODUCTO | ENTREZ PRODUIT
 26 | DRIVER NUMBER | NÚMERO DRIVER | CONDUCTOR NUMERO | No CONDUCTEUR
 27 | ENTER LICENSE | ENTER LICENÇA | INGRESE LICENCIA | ENTREZ PERMIS
 28 | ENTER FLEET NO | ENTER NRO FROTA | INGRESE NRO FLOTA | ENT No PARC AUTO
 29 | ENTER CAR WASH | WASH ENTER | INGRESE LAVADO | ENTREZ LAVE-AUTO
 30 | ENTER VEHICLE | ENTER VEÍCULO | INGRESE VEHICULO | ENTREZ VEHICULE
 31 | ENTER TRAILER | TRAILER ENTER | INGRESE TRAILER | ENTREZ REMORQUE
 32 | ENTER ODOMETER | ENTER ODOMETER | INGRESE ODOMETRO | ENTREZ ODOMETRE
 33 | DRIVER LICENSE | CARTEIRA DE MOTORISTA | LICENCIA CONDUCTOR | PERMIS CONDUIRE
 34 | ENTER CUSTOMER | ENTER CLIENTE | INGRESE CLIENTE | ENTREZ CLIENT
 35 | VEHICLE NUMBER | NÚMERO DO VEÍCULO | VEHICULO NUMERO | No VEHICULE
 36 | ENTER CUST DATA | ENTER CLIENTE INFO | INGRESE INFO CLIENTE | INFO CLIENT
 37 | REENTER DRIVID | REENTRAR DRIVER ID | REINGRESE ID CHOFER | RE-ENTR ID COND
 38 | ENTER USER DATA | ENTER INFO USUÁRIO | INGRESE INFO USUARIO | INFO UTILISATEUR
 39 | ENTER CUST CODE | ENTER CODE. CLIENTE | INGRESE COD. CLIENTE | ENTR CODE CLIENT
 40 | ENTER EMPLOYEE | ENTER FUNCIONÁRIO | INGRESE EMPLEADO | ENTREZ EMPLOYE
 41 | ENTER ID NUMBER | ENTER NÚMERO ID | INGRESE NUMERO ID | ENTREZ No ID
 42 | ENTER DRIVER ID | ENTER ID DRIVER | INGRESE ID CONDUCTOR | No CONDUCTEUR
 43 | ENTER FLEET PIN | ENTER PIN FROTA | INGRESE PIN DE FLOTA | NIP PARC AUTO
 44 | ODOMETER NUMBER | NÚMERO ODOMETER | ODOMETRO NUMERO | No ODOMETRE
 45 | ENTER DRIVER LIC | ENTER DRIVER LIC | INGRESE LIC CONDUCTOR | PERMIS CONDUIRE
 46 | ENTER TRAILER NO | NRO TRAILER ENTER | INGRESE NRO TRAILER | ENT No REMORQUE
 47 | REENTER VEHICLE | REENTRAR VEÍCULO | REINGRESE VEHICULO | RE-ENTR VEHICULE
 48 | ENTER VEHICLE ID | ENTER VEÍCULO ID | INGRESE ID VEHICULO | ENTR ID VEHICULE
 49 | ENTER BIRTH DATE | INSERIR DATA NAC | INGRESE FECHA NAC | ENT DT NAISSANCE
 50 | ENTER DOB MMDDYY | ENTER FDN MMDDYY | INGRESE FDN MMDDAA | NAISSANCE MMJJAA
 51 | ENTER FLEET DATA | ENTER FROTA INFO | INGRESE INFO DE FLOTA | INFO PARC AUTO
 52 | ENTER REFERENCE | ENTER REFERÊNCIA | INGRESE REFERENCIA | ENTREZ REFERENCE
 53 | ENTER AUTH NUMBR | ENTER NÚMERO AUT | INGRESE NUMERO AUT | No AUTORISATION
 54 | ENTER HUB NUMBER | ENTER HUB NRO | INGRESE NRO HUB | ENTREZ No NOYAU
 55 | ENTER HUBOMETER | MEDIDA PARA ENTRAR HUB | INGRESE MEDIDO DE HUB | COMPTEUR NOYAU
 56 | ENTER TRAILER ID | TRAILER ENTER ID | INGRESE ID TRAILER | ENT ID REMORQUE
 57 | ODOMETER READING | QUILOMETRAGEM | LECTURA ODOMETRO | LECTURE ODOMETRE
 58 | REENTER ODOMETER | REENTRAR ODOMETER | REINGRESE ODOMETRO | RE-ENT ODOMETRE
 59 | REENTER DRIV. ID | REENTRAR DRIVER ID | REINGRESE ID CHOFER | RE-ENT ID CONDUC
 60 | ENTER CUSTOMER ID | ENTER CLIENTE ID | INGRESE ID CLIENTE | ENTREZ ID CLIENT
 61 | ENTER CUST. ID | ENTER CLIENTE ID | INGRESE ID CLIENTE | ENTREZ ID CLIENT
 62 | ENTER ROUTE NUM | ENTER NUM ROUTE | INGRESE NUM RUTA | ENT No ROUTE
 63 | ENTER FLEET NUM | FROTA ENTER NUM | INGRESE NUM FLOTA | ENT No PARC AUTO
 64 | FLEET PIN | FROTA PIN | PIN DE FLOTA | NIP PARC AUTO
 65 | DRIVER # | DRIVER # | CONDUCTOR # | CONDUCTEUR
 66 | ENTER DRIVER # | ENTER DRIVER # | INGRESE CONDUCTOR # | ENT # CONDUCTEUR
 67 | VEHICLE # | VEÍCULO # | VEHICULO # | # VEHICULE
 68 | ENTER VEHICLE # | ENTER VEÍCULO # | INGRESE VEHICULO # | ENT # VEHICULE
 69 | JOB # | TRABALHO # | TRABAJO # | # TRAVAIL
 70 | ENTER JOB # | ENTER JOB # | INGRESE TRABAJO # | ENTREZ # TRAVAIL
 71 | DEPT NUMBER | NÚMERO DEPT | NUMERO DEPTO | No DEPARTEMENT
 72 | DEPARTMENT # | DEPARTAMENTO # | DEPARTAMENTO # | DEPARTEMENT
 73 | ENTER DEPT # | ENTER DEPT # | INGRESE DEPTO # | ENT# DEPARTEMENT
 74 | LICENSE NUMBER | NÚMERO DE LICENÇA | NUMERO LICENCIA | No PERMIS
 75 | LICENSE # | LICENÇA # | LICENCIA # | # PERMIS
 76 | ENTER LICENSE # | ENTER LICENÇA # | INGRESE LICENCIA # | ENTREZ # PERMIS
 77 | DATA | INFO | INFO | INFO
 78 | ENTER DATA | ENTER INFO | INGRESE INFO | ENTREZ INFO
 79 | CUSTOMER DATA | CLIENTE INFO | INFO CLIENTE | INFO CLIENT
 80 | ID # | ID # | ID # | # ID
 81 | ENTER ID # | ENTER ID # | INGRESE ID # | ENTREZ # ID
 82 | USER ID | USER ID | ID USUARIO | ID UTILISATEUR
 83 | ROUTE # | ROUTE # | RUTA # | # ROUTE
 84 | ENTER ROUTE # | ADD ROUTE # | INGRESE RUTA # | ENTREZ # ROUTE
 85 | ENTER CARD NUM | ENTER NÚMERO DE CARTÃO | INGRESE NUM TARJETA | ENTREZ NO CARTE
 86 | EXP DATE(YYMM) | VALIDADE VAL (AAMM) | FECHA EXP (AAMM) | DATE EXPIR(AAMM)
 87 | PHONE NUMBER | TELEFONE | NUMERO TELEFONO | NO TEL
 88 | CVV START DATE | CVV DATA DE INÍCIO | CVV FECHA INICIO | CVV DATE DE DEBUT
 89 | ISSUE NUMBER | NÚMERO DE EMISSÃO | NUMERO DE EMISION | NO DEMISSION
 90 | START DATE (MMYY) | DATA DE INÍCIO (AAMM) | FECHA INICIO (AAMM) | DATE DE DEBUT-AAMM
 */
-(RETURN_CODE) pin_getNumeric:(bool)maskInput minLength:(int)minLength maxLength:(int)maxLength messageID:(int)mID language:(LANGUAGE_TYPE)lang;

/**
 * Restore Default PINpad Settings

 
 *
 Executes a command to restore default PINpad settings.  PIN Length 4-12, Numeric Len 1-16;
 *
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 
 */
-(RETURN_CODE) pin_restoreDefaults;


/**
 * Set Numeric Length
 *
 Sets the Numeric length.
 
 @param minLength Minimum Numeric length at least 1
 @param maxLength Maximum Numeric length not to exceed 16
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) pin_setNumericLength:(int)minLength maxLength:(int)maxLength;


/**
 * Set PIN Length
 *
 Sets the encrypted PIN length.
 
 @param minLength Minimum PIN length at least 4
 @param maxLength Maximum PIN length not to exceed 12
 
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0007: Unknown:  Unknown error - RETURN_CODE_ERR_OTHER
 - 0x0100 through 0xFFFF refer to IDT_UniPayII::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) pin_setPinLength:(int)minLength maxLength:(int)maxLength;

/**
 *Close Device
 */

-(void) close;

/**
 Device Connected
 
 @return isConnected  Boolean indicated if BTPay is connected
 
 */

-(bool) isConnected;

/**
 * Attempt connection
 *
 Requests a connection attempt
 */
-(void) attemptConnect;


@end
