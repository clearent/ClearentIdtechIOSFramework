//
//  ClearentDevice.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 5/7/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "IDTech/IDTCommon.h"
#import "IDTech/APDUResponse.h"

@protocol Clearent_Device <NSObject>
/**
 *Close Device
 */
-(void) close;

/**
 * Connect To Audio Reader
 *
 Attemps to recognize and connect to an IDTech MSR device connected via the audio port.
 */
-(void) device_connectToUSB;

/**
 Cancels Transaction request (swipe or CTLS).
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPay::device_getResponseCodeString:()
 */
-(RETURN_CODE) ctls_cancelTransaction;

/**
 * Enable Transaction Request
 *
 Enables CLTS and MSR, waiting for swipe or tap to occur. If swipe captured, returns IDTMSRData instance to deviceDelegate::swipeMSRData:().  If CTLS captured, returns IDTEMVData to deviceDelegate::emvTransactionData:()
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPay::device_getResponseCodeString:()
 */
-(RETURN_CODE) ctls_startTransaction;

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
 - 0x0100 through 0xFFFF refer to IDT_UniPay::device_getResponseCodeString:()
 *
 */
-(RETURN_CODE) device_getFirmwareVersion:(NSString**)response;

/**
 * Begins searching for Bluetooth Low Energy devices in range
 - UniPayIII
 *
 * @param type When a NSUUID identifer is not provided, this will attempt to connect to the first device of this type it finds.  If a NSUUID identifer is provided, this filter will be ignored.
 * @param identifier This will only connect to a device with this calculated UUID identifier
 *
 * @return bool  If successful, polling has started
 *
 * Any of the following BLE status messages may be returned to the deviceMessage delegate:
 - This device does not support Bluetooth Low Energy.
 - This app is not authorized to use Bluetooth Low Energy.
 - Bluetooth on this device is currently powered off.
 - The BLE Manager is resetting; a state update is pending.
 - Bluetooth LE is turned on and ready for communication.
 - The state of the BLE Manager is unknown.
 *
 * Note: a Devices UUID is calculated by the iOS device using a combiniation of the iOS device UUID and the BLE device MAC address.  This value is not known until after it connects for the first time, and then every time after that, it will be the same value.  This value can be retrieved by IDT_Device::connectedBLEDevice() after the device connects.
 */
-(bool) device_enableBLEDeviceSearch:(IDT_DEVICE_Types)type identifier:(NSUUID*)identifier;

/**
 * Stops searching for Bluetooth Low Energy devices in range
 - UniPayIII
 *
 *
 * @return bool  If successful, polling was in progress and has stopped. If unsuccessful, BLE Device Search was not in progress.
 *
 * NOTE:  BLE only scans when there are no devices currently connected. After the SDK connects to any IDTech device, the scanning will pause automatically.
 */
-(bool) device_disableBLEDeviceSearch;

/**
 * Returns the UUID of the connected BLE device
 - UniPayIII
 *
 * @return NSUUID  UUID of the connected BLE device.  Returns nil if no BLE device connected.
 *
 */
-(NSUUID*) device_connectedBLEDevice;

/**
 * Is Audio Reader Connected
 *
 Returns value on device connection status when device is an audio-type connected to headphone plug.
 @return BOOL True = Connected, False = Disconnected
 */
-(BOOL) device_isAudioReaderConnected;

/**
 * Get Response Code String
 *
 Interpret a response code and return string description.
 @param errorCode Error code, range 0x0000 - 0xFFFF, example 0x0300
 * @return Verbose error description
 */
-(NSString *) device_getResponseCodeString: (int) errorCode;

/**
 Is Device Connected
 Returns the connection status of the requested device
 @param device Check connectivity of device type
 @code
 typedef enum{
 IDT_DEVICE_UNIPAYIII_IOS = 8
 IDT_DEVICE_UNIPAYIII_OSX_USB = 9
 }IDT_DEVICE_Types;
 @endcode
 */
-(bool) device_isConnected:(IDT_DEVICE_Types)device;

/**
 * Send NEO IDG Command
 Send a NEO IDG ViVOtech 2.0 command
 *
 * @param command  One byte command as per NEO IDG Reference Guide
 * @param subCommand  One byte sub-command as per NEO IDG Reference Guide
 * @param data  Command data (if applicable)
 * @param response  Returns next Command response
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniMagIII::device_getResponseCodeString:()
 *
 */
-(RETURN_CODE) device_sendIDGCommand:(unsigned char)command subCommand:(unsigned char)subCommand data:(NSData*)data response:(NSData**)response;

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
 - 0x0100 through 0xFFFF refer to IDT_UniPay::device_getResponseCodeString:()
 */
-(RETURN_CODE) device_setAudioVolume:(float)val;

/**
 * Set Pass Through
 Sets Pass-Through mode on UniPayIII
 *
 @param enablePassThrough  TRUE = Pass through enabled
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
-(RETURN_CODE) device_setPassThrough:(BOOL)enablePassThrough;

/**
 * Start Remote Key Injection
 *
 Attempts to perform a Remote Key Injection with IDTech's RKI servers.
 * @return RETURN_CODE:
 - 0x0000: Success: no error - RETURN_CODE_DO_SUCCESS
 - 0x0001: Disconnect: no response from reader - RETURN_CODE_ERR_DISCONNECT
 - 0x0002: Invalid Response: invalid response data - RETURN_CODE_ERR_CMD_RESPONSE
 - 0x0003: Timeout: time out for task or CMD - RETURN_CODE_ERR_TIMEDOUT
 - 0x0004: Invalid Parameter: wrong parameter - RETURN_CODE_ERR_INVALID_PARAMETER
 - 0x0005: MSR Busy: SDK is doing MSR or ICC task - RETURN_CODE_SDK_BUSY_MSR
 - 0x0006: PINPad Busy:  SDK is doing PINPad task - RETURN_CODE_SDK_BUSY_PINPAD
 - 0x0100 through 0xFFFF refer to IDT_Device::getResponseCodeString:()
 */
-(RETURN_CODE) device_startRKI;

/**
 * Authenticate Transaction
 Authenticates a transaction after startTransaction successfully executes.
 By default, auto authorize is ENABLED.  If auto authorize is DISABLED, this function must be called after a result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS returned to emvTransactionData delegate protocol is received after a startTransaction call.  If auto authorize is ENABLED (default), this method will automatically be executed after receiving the result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS after startTransaction.  The auto authorize can be enabled/disabled with IDT_DEVICE::disableAutoAuthenticateTransaction:()
 *
 The purpose of this step is to allow the merchant the chance to evaluate the data captured from the matching Application (if found) before the kernel authenticates the transaction data.  This would allow, for instance, the merchant to be told what card is being used, and if it is a specific type (like a store card), perform an action like reducing the amount before proceeding (as a promotion in using that card).
 @param tags Any tags to modify original tags submitted with startTransaction.  Passed as NSData.  Example, tag 9F0C with amount 0x000000000100 would be 0x9F0C06000000000100
 Tag DFEE1A can be used to specify tags to be returned in response, in addition to the default tags. Example DFEE1A049F029F03 will return tags 9F02 and 9F03 with the response
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
-(RETURN_CODE) emv_authenticateTransaction:(NSData*)tags;

/**
 * Callback Response LCD Display
 *
 Provides menu selection responses to the kernel after a callback was received lcdDisplay delegate.
 @param mode The choices are as follows
 - 0x00 Cancel
 - 0x01 Menu Display
 - 0x02 Normal Display get Function Key  supply either 0x43 ('C') for Cancel, or 0x45 ('E') for Enter/accept
 - 0x08 Language Menu Display
 @param selection Line number in hex (0x01, 0x02), or 'C'/'E' of function key
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE) emv_callbackResponseLCD:(int)mode selection:(unsigned char) selection;

/**
 * Complete EMV Transaction Online Request
 *
 Completes an online EMV transaction request by the card
 The tags will be returned in the emvTransactionData delegate protocol.
 @param isSuccess Determines if connection to host was successful:
 - TRUE: Online processing with the host (issuer) was completed
 - FALSE: Online processing could not be completed due to connection error with the host (issuer). No further data (tags) required.
 @param tags Host response tag (see below)
 \par Host response tag:
 Tag | Length | Description
 ----- | ----- | -----
 8A | 2 | Data element Authorization Response Code. Mandatory
 91 | 8-16 | Issuer Authentication Data. Optional
 71 | 0-256 | Issuer Scripts. Optional
 72 | 0-256 | Issuer Scripts. Optional
 DFEE1A | 0-256 | Tag list of additional tags to return
 Tag DFEE1A will force additional tags to be returned.  Example DFEE1A049F029F03 will return tags
 9F02 and 9F03 with the response
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
 */
-(RETURN_CODE) emv_completeOnlineEMVTransaction:(BOOL)isSuccess hostResponseTags:(NSData*)tags;

/**
 * Disable Auto Authenticate Transaction
 *
 If auto authenticate is DISABLED, authenticateTransaction must be called after a successful startEMV execution.
 @param disable  FALSE = auto authenticate ENABLED, TRUE = auto authenticate DISABLED
 */
-(void) emv_disableAutoAuthenticateTransaction:(BOOL)disable;

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
 This will REMOVE the an AID configuration file and all the tlv data associated with that AID.
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
 This will remove ALL configurable TLV data associated with the terminals Kernel configuration.
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
 Returns all the AID names on the terminal.  Populates response parameter with an Array of NSString* with AID names.  Each AID name represent a unique configuration file to be loaded/used when a matching application is found on a card during a transaction.
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
 *
 Retrieves the configuration information for a provided AID name, if that AID file exists on the terminal.
 The TLV data in that AID is returned as a NSDictionary, with the Key being the tag name as a NSString representation of the tag hex value (example "9F06"), and the Object being the Value as NSData (example 0xa0000000031010).
 The data returned will be from the range of allowable kernel EMV tags.  Please see "EMV Tag Reference" at the end of this document for the listing.
 @param AID Name of ApplicationID in ASCII, example "A0000000031020".  Must be between 5 and 16 characters
 @param responseAID  The response returned from the method as a dictionary with Key/Object to match TagValues as follows:
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
 * Retrieve Certificate Authority Public Key
 - BTPay 200
 *
 Retrieves the CAPK as specified by the RID/Index  passed as a parameter in the CAKey structure.  The CAPK will be in the response parameter
 @param rid The RID of the key to retrieve
 @param index The Index of the key to retrieve
 @param response Response returned as a NSData object with the following data:
 - 5 bytes RID
 - 1 byte Index
 - 1 byte Hash Algorithm
 - 1 byte Encryption Algorithm
 - 20 bytes HashValue
 - 4 bytes Public Key Exponent
 - 2 bytes Modulus Length
 - Variable bytes Modulus>
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
-(RETURN_CODE) emv_retrieveCAPKFile:(NSString*)rid index:(NSString*)index response:(NSData**)response;

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
 *
 Retrieves the tag values associated with the terminal configuration file.  This will be a combination of uneditable major configuration tags for the kernel configuration (example 9F33, Terminal Capabilities), and editable tags set with IDT_Device::emv_setTerminalData:()  (example DF13, Terminal Action Code - Default)
 The TLV data returned as a NSDictionary, with the Key being the tag name as a NSString representation of the tag hex value (example "DF13"), and the Object being the Value as NSData (example 0x00058003FF).
 The data returned will be from the range of allowable kernel EMV tags.  Please see "EMV Tag Reference" at the end of this document for the listing.
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
 * Retrieve Transaction Results
 *
 Retrieves the requested tag values (if they exist) from the last transaction.
 The TLV data returned as a NSDictionary, with the Key being the tag name as a NSString representation of the tag hex value (example "5A"), and the Object being the Value as NSData (example 0x41359276429372938).
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
-(RETURN_CODE) emv_retrieveTransactionResult:(NSData*)tags retrievedTags:(NSDictionary**)retrievedTags;

/**
 * Set Application Data by AID
 *
 Sets the configuration information for a provided AID name, with TLV data that populates a NSDictionary.
 The TLV data for the AID is sent as a NSDictionary, with the Key being the tag name as a NSString representation of the tag hex value (example "9F06"), and the Object being the Value as NSData (example 0xa0000000031010).
 The data for the AID configuration will will be from the range of allowable kernel EMV tags.  Please see "EMV Tag Reference" at the end of this document for the listing.
 NOTES:
 There is no minimum defined set of AID TLV data that must be provided, other than 9F06 for the AID name.
 If this AID is selected and matched during an EMV transaction, any data in this AID will either OVERRIDE the same data in the terminal configuration file, or PROVIDE the data if it is non-existant in the terminal configuration file.
 AID configuration information is provided during L3 certification.  Dummy/stub AID data can be used pre-certification to test EMV transaction as long as at least tag 9F06 is defined that makes up the AID configuration locator.
 There are convenience utilities to turn a TLV NSData object into a NSDictionary, and a NSDictionary into a NSData object in IDTUtility:
 @code
 +(NSDictionary*) TLVtoDICT:(NSData*)param;
 +(NSData*) DICTotTLV:(NSDictionary*)tags;
 @endcode
 Also utilities to turn a HEX/ASCII string to NSDATA and back again
 @code
 + (NSData *)hexToData:(NSString*)str ;
 +(NSString*) dataToHexString:(NSData*)data;
 @endcode
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
-(RETURN_CODE) emv_setApplicationData:(NSString*)aidName configData:(NSDictionary*)data;

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
 * Set Certificate Authority Public Key
 *
 Sets the CAPK as specified by the CAKey raw format
 @param file CAKey format:
 [5 bytes RID][1 byte Index][1 byte Hash Algorithm][1 byte Encryption Algorithm][20 bytes HashValue][4 bytes Public Key Exponent][2 bytes Modulus Length][Variable bytes Modulus]
 Where:
 - Hash Algorithm: The only algorithm supported is SHA-1.The value is set to 0x01
 - Encryption Algorithm: The encryption algorithm in which this key is used. Currently support only one type: RSA. The value is set to 0x01.
 - HashValue: Which is calculated using SHA-1 over the following fields: RID & Index & Modulus & Exponent
 - Public Key Exponent: Actually, the real length of the exponent is either one byte or 3 bytes. It can have two values: 3 (Format is 0x00 00 00 03), or  65537 (Format is 0x00 01 00 01)
 - Modulus Length: LenL LenH Indicated the length of the next field.
 - Modulus: This is the modulus field of the public key. Its length is specified in the field above.
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE) emv_setCAPKFile:(NSData*)file;

/**
 * Set Certificate Revocation List
 *
 Sets the CRL list
 @param data CRLEntries as a repeating occurance of CRL: CRL1 CRL2 … CRLn.
 CRL format is
 - 5Bytes RID
 - 1Byte CA public key Index
 - 3Bytes Certificate Serial Number
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
-(RETURN_CODE) emv_setCRLEntries:(NSData*)data;

/**
 * Set Terminal Data
 *
 Sets the terminal configuration information, with TLV data that populates a NSDictionary.
 The TLV data for the terminal configuration is sent as a NSDictionary, with the Key being the tag name as a NSString representation of the tag hex value (example "DF13"), and the Object being the Value as NSData (example 0x00080039FF).
 The data for the terminal configuration will will be from the range of allowable kernel EMV tags.  Please see "EMV Tag Reference" at the end of this document for the listing.
 NOTES:
 There is an uneditable set of tags that make up the current kernel configuration major parameters.  Any attempt to set those will return an error.
 If an AID is selected and matched during an EMV transaction, any data in that AID will either OVERRIDE the same data in the terminal configuration file, or PROVIDE the data if it is non-existant in the terminal configuration file.
 There are convenience utilities to turn a TLV NSData object into a NSDictionary, and a NSDictionary into a NSData object in IDTUtility:
 @code
 +(NSDictionary*) TLVtoDICT:(NSData*)param;
 +(NSData*) DICTotTLV:(NSDictionary*)tags;
 @endcode
 Also utilities to turn a HEX/ASCII string to NSDATA and back again
 @code
 + (NSData *)hexToData:(NSString*)str ;
 +(NSString*) dataToHexString:(NSData*)data;
 @endcode
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
-(RETURN_CODE) emv_setTerminalData:(NSDictionary*)data;

/**
 * Start EMV Transaction Request
 *
 Authorizes the EMV transaction  for an ICC card
 The tags will be returned in the emvTransactionData delegate protocol.
 By default, auto authorize is ENABLED.  If auto authorize is DISABLED, this function will complete with a return of EMV_RESULT_CODE_START_TRANSACTION_SUCCESS to emvTransactionData delegate protocol, and then IDT_UniPayIII::emv_authenticateTransaction() must be executed.  If auto authorize is ENABLED (default), IDT_UniPayIII::emv_authenticateTransaction() will automatically be executed after receiving the result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS.  The auto authorize can be enabled/disabled with IDT_UniPayIII::emv_disableAutoAuthenticateTransaction:()
 @param amount Transaction amount value  (tag value 9F02)
 @param amtOther Other amount value, if any  (tag value 9F03)
 @param type Transaction type (tag value 9C).
 @param timeout Timeout value in seconds.
 @param tags Any other tags to be included in the request.  Passed as NSData.  Example, tag 9F0C with amount 0x000000000100 would be 0x9F0C06000000000100
 If tags 9F02 (amount),9F03 (other amount), or 9C (transaction type) are included, they will take priority over these values supplied as individual parameters to this method.
 Tag DFEE1A can be used to specify tags to be returned in response, in addition to the default tags. Example DFEE1A049F029F03 will return tags 9F02 and 9F03 with the response
 @param forceOnline TRUE = do not allow offline approval,  FALSE = allow ICC to approve offline if terminal capable
 @param fallback Indicate if it supports fallback to MSR
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE) emv_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline fallback:(BOOL)fallback;

/**
 * Polls device for Serial Number
 *
 * @param response  Returns Serial Number
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPay::device_getResponseCodeString:()
 *
 */
-(RETURN_CODE) config_getSerialNumber:(NSString**)response;

/**
 * Exchange APDU (unencrypted)
 *
 * Sends an APDU packet to the ICC.  If successful, response is returned in APDUResult class instance in response parameter.
 @param dataAPDU  APDU data packet
 @param response Unencrypted/encrypted parsed APDU response
 *
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPayIII::device_getResponseCodeString:()
 */

-(RETURN_CODE) icc_exchangeAPDU:(NSData*)dataAPDU response:(APDUResponse**)response;
/**
 * Get Reader Status
 *
 Returns the reader status
 @param readerStatus Pointer that will return with the ICCReaderStatus results.
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPayIII::device_getResponseCodeString:()
 @code
 ICCReaderStatus* readerStatus;
 RETURN_CODE rt = [[IDT_Device sharedController] getICCReaderStatus:&readerStatus];
 if(RETURN_CODE_DO_SUCCESS != rt){
 NSLog(@"Fail");
 }
 else{
 NSString *sta;
 if(readerStatus->iccPower)
 sta =@"[ICC Powered]";
 else
 sta = @"[ICC Power not Ready]";
 if(readerStatus->cardSeated)
 sta =[NSString stringWithFormat:@"%@,[Card Seated]", sta];
 else
 sta =[NSString stringWithFormat:@"%@,[Card not Seated]", sta];
 @endcode
 */

-(RETURN_CODE) icc_getICCReaderStatus:(ICCReaderStatus**)readerStatus;

/**
 * Power On ICC
 *
 * Power up the currently selected microprocessor card in the ICC reader
 *
 * @param response Response returned. If Success, ATR String. If Failure, ASCII encoded data of error string
 *
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.
 */
-(RETURN_CODE) icc_powerOnICC:(NSData**)response;

/**
 * Power Off ICC
 *
 * Powers down the ICC
 * @param error Returns the error, if any
 *
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.
 If Success, empty
 If Failure, ASCII encoded data of error string
 */
-(RETURN_CODE) icc_powerOffICC:(NSString**)error;

/**
 * Disable MSR Swipe
 Cancels MSR swipe request.
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPay::device_getResponseCodeString:()
 */
-(RETURN_CODE) msr_cancelMSRSwipe;

/**
 * Enable MSR Swipe
 *
 Enables CLTS and MSR, waiting for swipe or tap to occur. If swipe captured, returns IDTMSRData instance to deviceDelegate::swipeMSRData:().  If CTLS captured, returns IDTEMVData to deviceDelegate::emvTransactionData:()
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_UniPay::device_getResponseCodeString:()
 */
-(RETURN_CODE) msr_startMSRSwipe;

/**
 *Check if device is connected
 */
-(bool) isConnected;

@end
