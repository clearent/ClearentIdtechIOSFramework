//
//  Clearent_VP3300.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 5/29/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//
@class Clearent_VP3300;

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import "ClearentPublicVP3300Delegate.h"
#import "ClearentPaymentRequest.h"
#import "ClearentVP3300Configuration.h"
#import <IDTech/IDT_VP3300.h>
#import "ClearentResponse.h"
#import "ClearentConnection.h"

/**
 * Interact with this object as a singleton. Provide a delegate that adheres to the Clearent_Public_IDTech_VP3300_Delegate protocol will allow the framework to send messages to you.
 * The Clearent solution wraps all of the IDTech functionality, allowing it to shield you from interacting with the credit card data. The methods that are available are well documented in the IDTech documentation.
 **/

@interface Clearent_VP3300 : NSObject
@property(nonatomic) SEL callBackSelector;

- (id) init : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentBaseUrl:(NSString*)clearentBaseUrl publicKey:(NSString*)publicKey
__deprecated_msg("use initWithConnectionHandling method instead.");

/**
 * Configuration includes capability to disable remote logging
 */
- (id) initWithConfig : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration __deprecated_msg("use initWithConnectionHandling method instead.");

/**
 * Configuration includes ability to handle bluetooth and audio jack connections.
 */
- (id) initWithConnectionHandling : (id <Clearent_Public_IDTech_VP3300_Delegate>)publicDelegate clearentVP3300Configuration:(id <ClearentVP3300Configuration>) clearentVP3300Configuration;

- (NSString*) SDK_version;

/**
 *Close Device - closes all communication channels, disconnects devices, and destroys the current instance of the SharedController.
 */

-(void) close;

/**
 * Connect To Audio Reader
 *
 Attemps to recognize and connect to an IDTech MSR device connected via the USB port.
 
 */

//-(void) device_connectToUSB;


/**
 * Disconnect from BLE -
 *
 * Will disconnect from existing BLE connection. You can now set another BLE Friendly Name to attach to another device.
 *
 */
-(void) device_disconnectBLE;


/**
 Cancels Transaction request (swipe or CTLS).
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */

-(RETURN_CODE) ctls_cancelTransaction;



/**
 Cancels Transaction request (EMV).
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */

-(RETURN_CODE) emv_cancelTransaction;



/**
 Cancels Transaction request (EMV, swipe or CTLS).
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */

-(RETURN_CODE) device_cancelTransaction;


/**
 * Get Configuration Group
 *
 Retrieves the Configuration for the specified Group. Group 0 = terminal settings.
 
 @param group Configuration Group
 @param response Group TLV returned as a dictionary
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE) ctls_getConfigurationGroup:(int)group response:(NSDictionary**)response;


/**
 Process Bypass Response.
 
 When output is being bypassed, and a command is received in the delegate redirectedOutput and sent to the device, the device rexponse must be sent to this
 method so the SDK can finishing processing the results;
 
 @param data The data received from the device that the SDK must process to complete the executing command
 */
-(void) processBypassResponse:(NSData*)data;

/**
 * Set Bypass Delegate
 *
 Sets the bypass delegate. .
 
 @param del  IDT_Device_Delegate delegate.
 
 
 */

-(void) assignBypassDelegate:(id<IDT_VP3300_Delegate>)del;




/**
 * Remove All Certificate Authority Public Key
 *
 Removes all the CAPK for CTLS
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) ctls_removeAllCAPK;

/**
 * Remove Application Data by AID
 *
 Removes the Application Data for CTLS as specified by the AID name passed as a parameter
 
 @param AID Name of ApplicationID as Hex String (example "A0000000031010") Must be between 5 and 16 bytes
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) ctls_removeApplicationData:(NSString*)AID;

/**
 * Remove Certificate Authority Public Key
 *
 Removes the CAPK for CTLS as specified by the RID/Index
 
 @param capk 6 byte CAPK =  5 bytes RID + 1 byte INDEX
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE)  ctls_removeCAPK:(NSData*)capk;

/**
 * Remove Configuration Group
 *
 Removes the Configuration as specified by the Group.  Must not by group 0
 
 @param group Configuration Group
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE)  ctls_removeConfigurationGroup:(int)group;


/**
 * Retrieve AID list
 *
 Returns all the AID names installed on the terminal for CTLS.
 
 @param response  array of AID name as NSData*
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) ctls_retrieveAIDList:(NSArray**)response;

/**
 * Retrieve Application Data by AID
 *
 Retrieves the CTLS Application Data as specified by the AID name passed as a parameter.
 
 @param AID Name of ApplicationID as Hex String (example "A0000000031010"). Must be between 5 and 16 bytes
 @param response  The TLV elements of the requested AID
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */
-(RETURN_CODE)  ctls_retrieveApplicationData:(NSString*)AID response:(NSDictionary**)response;

/**
 * Retrieve Certificate Authority Public Key
 *
 Retrieves the CAPKfor CTLS as specified by the RID/Index  passed as a parameter.
 
 @param capk 6 bytes CAPK = 5 bytes RID + 1 byte Index
 @param key Response returned as a CAKey format:
 [5 bytes RID][1 byte Index][1 byte Hash Algorithm][1 byte Encryption Algorithm][20 bytes HashValue][4 bytes Public Key Exponent][2 bytes Modulus Length][Variable bytes Modulus]
 Where:
 - Hash Algorithm: The only algorithm supported is SHA-1.The value is set to 0x01
 - Encryption Algorithm: The encryption algorithm in which this key is used. Currently support only one type: RSA. The value is set to 0x01.
 - HashValue: Which is calculated using SHA-1 over the following fields: RID & Index & Modulus & Exponent
 - Public Key Exponent: Actually, the real length of the exponent is either one byte or 3 bytes. It can have two values: 3 (Format is 0x00 00 00 03), or  65537 (Format is 0x00 01 00 01)
 - Modulus Length: LenL LenH Indicated the length of the next field.
 - Modulus: This is the modulus field of the public key. Its length is specified in the field above.
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */
-(RETURN_CODE)  ctls_retrieveCAPK:(NSData*)capk key:(NSData**)key;


/**
 * Retrieve the Certificate Authority Public Key list
 *
 Returns all the CAPK RID and Index installed on the terminal for CTLS.
 
 @param keys NSArray of NSData CAPK name  (RID + Index)
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */
-(RETURN_CODE)  ctls_retrieveCAPKList:(NSArray**)keys;

/**
 * Retrieve Terminal Data
 *
 Retrieves the Terminal Data for CTLS. This is configuration group 0 (Tag FFEE - > FFEE0100).  The terminal data
 can also be retrieved by ctls_getConfiguraitonGroup(0).
 
 @param tlv Response returned as a TLV
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 
 */
-(RETURN_CODE)  ctls_retrieveTerminalData:(NSData**)tlv;

/**
 * Set Application Data by AID
 *
 Sets the Application Data for CTLS as specified by TLV data
 
 @param tlv  Application data in TLV format
 The first tag of the TLV data must be the group number (FFE4).
 The second tag of the TLV data must be the AID (9F06)
 
 Example valid TLV, for Group #2, AID a0000000035010:
 "ffe401029f0607a0000000051010ffe10101ffe50110ffe30114ffe20106"
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE)  ctls_setApplicationData:(NSData*)tlv;

/**
 * Set Certificate Authority Public Key
 *
 Sets the CAPK for CTLS as specified by the CAKey structure
 
 @param key CAKey format:
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
-(RETURN_CODE)  ctls_setCAPK:(NSData*)key;


/**
 * Set Configuration Group
 *
 Sets the Configuration Group for CTLS as specified by the TLV data
 
 @param tlv  Configuration Group Data in TLV format
 The first tag of the TLV data must be the group number (FFE4).
 A second tag must exist
 
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) ctls_setConfigurationGroup:(NSData*)tlv;


/**
 * Set Terminal Data
 *
 Sets the Terminal Data for CTLS as specified by the TLV.  The first TLV must be Configuration Group Number (Tag FFE4).  The terminal global data
 is group 0, so the first TLV would be FFE40100.  Other groups can be defined using this method (1 or greater), and those can be
 retrieved with ctls_getConfigurationGroup(int group), and deleted with ctls_removeConfigurationGroup(int group).  You cannot
 delete group 0.
 
 @param tlv TerminalData configuration data
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 */
-(RETURN_CODE) ctls_setTerminalData:(NSData*)tlv;




/**
 * Start a CTLS Transaction Request
 *
 Authorizes the CTLS transaction for an CTLS card
 
 The tags will be returned in the callback routine.
 
 @param amount Transaction amount value  (tag value 9F02)
 @param type Transaction type (tag value 9C).
 @param timeout Timeout value in seconds.
 @param tags Any other tags to be included in the request.
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 *
 * NOTE ON APPLEPAY VAS:
 * To enable ApplePay VAS, first a merchant record must be defined in one of the six available index positions (1-6) using device_setMerchantRecord, then container tag FFEE06
 * must be sent as part of the additional tags parameter of ctls_startTransaction.  Tag FFEE06 must contain tag 9F26 and 9F22, and can optionanally contain tags 9F2B and DFO1.
 * Example FFEE06189F220201009F2604000000009F2B050100000000DF010101
 * 9F22 = two bytes = ApplePay Terminal Applicaiton Version Number.  Hard defined as 0100 for now. (required)
 * 9F26 = four bytes = ApplePay Terminal Capabilities Information (required)
 *  - Byte 1 = RFU
 *  - Byte 2 = Terminal Type
 *  - - Bit 8 = VAS Support  (1=on, 0 = off)
 *  - - Bit 7 = Touch ID Required  (1=on, 0 = off)
 *  - - Bit 6 = RFU
 *  - - Bit 5 = RFU
 *  - - Bit 1,2,3,4
 *  - - - 0 = Payment Terminal
 *  - - - 1 = Transit Terminal
 *  - - - 2 = Access Terminal
 *  - - - 3 = Wireless Handoff Terminal
 *  - - - 4 = App Handoff Terminal
 *  - - - 15 = Other Terminal
 *  - Byte 3 = RFU
 *  - Byte 4 = Terminal Mode
 *  - - 0 = ApplePay VAS OR ApplePay
 *  - - 1 = ApplePay VAS AND ApplePay
 *  - - 2 = ApplePay VAS ONLY
 *  - - 3 = ApplePay ONLY
 *  9F2B = 5 bytes = ApplePay VAS Filter.  Each byte filters for that specific merchant index  (optional)
 *  DF01 = 1 byte = ApplePay VAS Protocol.  (optional)
 *  - - Bit 1 : 1 = URL VAS, 0 = Full VAS
 *  - - Bit 2 : 1 = VAS Beeps, 0 = No VAS Beeps
 *  - - Bit 3 : 1 = Silent Comm Error, 2 = EMEA Comm Error
 *  - - Bit 4-8 : RFU
 *
 */
-(RETURN_CODE) ctls_startTransaction:(double)amount type:(int)type timeout:(int)timeout tags:(NSMutableDictionary *)tags;



/**
 * Enable Transaction Request
 
 *
 Enables CLTS and MSR, waiting for swipe or tap to occur. Returns IDTEMVData to deviceDelegate::emvTransactionData:()
 
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 
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
 - VP3300
 *
 * @param identifier This will only connect to a device with this calculated UUID identifier.  If nil is passed, it will connect to the first devices with the default friendly name (IDT_VP3300::device_getBLEFriendlyName / IDT_VP3300::device_setBLEFriendlyName)
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
-(bool) device_enableBLEDeviceSearch:(NSUUID*)identifier;



/**
 * Get BLE Friendly Name
 *
 *
 * @return NSString  Returns the default friendly name to be used when discovering any BLE devices
 *
 */
-(NSString*) device_getBLEFriendlyName;


/**
 * Set BLE Friendly Name
 *
 *
 * @param friendlyName  Sets the default friendly name to be used when discovering any BLE devices
 *
 */
-(void) device_setBLEFriendlyName:(NSString*)friendlyName;


/**
 * Stops searching for Bluetooth Low Energy devices in range
 - VP3300
 *
 *
 * @return bool  If successful, polling was in progress and has stopped. If unsuccessful, BLE Device Search was not in progress.
 *
 * NOTE:  BLE only scans when there are no devices currently connected. After the SDK connects to any IDTech device, the scanning will pause automatically.
 */
-(bool) device_disableBLEDeviceSearch;

/**
 * Returns the UUID of the connected BLE device
 - VP3300
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
 * Get Transaction Results
 Gets the transaction results when the reader is functioning in "Auto Poll" mode
 *
 * @param result The transaction results
 *
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString().  When no data is available, return code = RETURN_CODE_NO_DATA_AVAILABLE
 *
 */
-(RETURN_CODE)  device_getAutoPollTransactionResults:(IDTEMVData**)result;

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
 IDT_DEVICE_VP3300_IOS = 8
 IDT_DEVICE_VP3300_OSX_USB = 9
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
 
 Sets Pass-Through mode on VP3300
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
 * Send Burst Mode
 *
 * Sets the burst mode forthe device.
 *
 * @param mode 0 = OFF, 1 = Always On, 2 = Auto Exit
 
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE)  device_setBurstMode:(int) mode;


/**
 * Send Poll Mode
 *
 * Sets the poll mode forthe device. Auto Poll keeps reader active, Poll On Demand only polls when requested by terminal
 *
 * @param mode 0 = Auto Poll, 1 = Poll On Demand
 
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE) device_setPollMode:(int) mode;


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
 * Callback Response PIN Request
 *
 Provides PIN data  to the kernel after a callback was received pinRequest delegate.
 
 @param mode PIN Mode:
 - EMV_PIN_MODE_CANCEL = 0X00,
 - EMV_PIN_MODE_ONLINE_PIN_DUKPT = 0X01,
 - EMV_PIN_MODE_ONLINE_PIN_MKSK = 0X02,
 - EMV_PIN_MODE_OFFLINE_PIN = 0X03
 @param KSN  Key Serial Number. If no pairing and PIN is plaintext, value is nil
 @param PIN PIN data, encrypted.  If no pairing, PIN will be sent plaintext
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 
 */
-(RETURN_CODE) emv_callbackResponsePIN:(EMV_PIN_MODE_Types)mode KSN:(NSData*)KSN PIN:(NSData*)PIN;

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
 Sets the terminal major configuration in ICS .
 @param configuration A configuration value, range 1-5
 - 1 = 1C
 - 2 = 2C
 - 3 = 3C
 - 4 = 4C
 - 5 = 5C
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE) emv_setTerminalMajorConfiguration:(int)configuration;

/**
 Gets the terminal major configuration in ICS .
 @param configuration A configuration value, range 1-5
 - 1 = 1C
 - 2 = 2C
 - 3 = 3C
 - 4 = 4C
 - 5 = 5C
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 */
-(RETURN_CODE) emv_getTerminalMajorConfiguration:(NSUInteger**)configuration;


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
 
 
 By default, auto authorize is ENABLED.  If auto authorize is DISABLED, this function will complete with a return of EMV_RESULT_CODE_START_TRANSACTION_SUCCESS to emvTransactionData delegate protocol, and then IDT_VP3300::emv_authenticateTransaction() must be executed.  If auto authorize is ENABLED (default), IDT_VP3300::emv_authenticateTransaction() will automatically be executed after receiving the result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS.  The auto authorize can be enabled/disabled with IDT_VP3300::emv_disableAutoAuthenticateTransaction:()
 
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
* Start EMV (dip and swipe interface only) Transaction Request 
*
@see emv_startTransaction for more details
@param clearentPaymentRequest Transaction amount value  (tag value 9F02)

* @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()

*/
-(RETURN_CODE) emv_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest;

/**
 * Polls device for Serial Number
 
 *
 * @param response  Returns Serial Number
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
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
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 
 */

-(RETURN_CODE) icc_exchangeAPDU:(NSData*)dataAPDU response:(APDUResponse**)response;
/**
 * Get Reader Status
 *
 Returns the reader status
 
 @param readerStatus Pointer that will return with the ICCReaderStatus results.
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
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
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 */

-(RETURN_CODE) msr_cancelMSRSwipe;

/**
 * Enable MSR Swipe
 
 *
 Enables CLTS and MSR, waiting for swipe or tap to occur. Returns IDTEMVData to deviceDelegate::emvTransactionData:()
 
 
 * @return RETURN_CODE:  Return codes listed as typedef enum in IDTCommon:RETURN_CODE.  Values can be parsed with IDT_VP3300::device_getResponseCodeString:()
 
 
 */

-(RETURN_CODE) msr_startMSRSwipe;

/**
 *Check if device is connected
 */
-(bool) isConnected;



/**
 * Start A Transaction Request
 *
 Authorizes the EMV, CTLS, or MSR transaction
 
 
 For a contact ICC EMV transaction, by default auto authorize is ENABLED.  If auto authorize is DISABLED, this function will complete with a return of EMV_RESULT_CODE_START_TRANSACTION_SUCCESS to emvTransactionData delegate protocol, and then IDT_UniPayII::emv_authenticateTransaction() must be executed.  If auto authorize is ENABLED (default), IDT_UniPayII::emv_authenticateTransaction() will automatically be executed after receiving the result EMV_RESULT_CODE_START_TRANSACTION_SUCCESS.  The auto authorize can be enabled/disabled with IDT_VP3300::emv_disableAutoAuthenticateTransaction:()
 
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
-(RETURN_CODE) device_startTransaction:(double)amount amtOther:(double)amtOther type:(int)type timeout:(int)timeout tags:(NSData*)tags forceOnline:(BOOL)forceOnline  fallback:(BOOL)fallback;


/**
 The reader has an emv configuration applied each time connects. After a successful configuration the device serial number and a flag denoting the reader was configured is stored using NSUserDefaults. If there is a need to clear out this information, maybe to support a configuration change/future updates, call this method to clear out the cache.
 */
- (void) clearConfigurationCache;

/**
 Enable/disable Clearent's emv configuration. (true or false)
 */
- (void) setAutoConfiguration:(BOOL)enable;

/**
 Enable/disable Clearent's contactless. default is false
 */
- (void) setContactless:(BOOL)enable;

/**
 Enable/disable Clearent's contactless configuration. (true or false)
 */
- (void) setContactlessAutoConfiguration:(BOOL)enable;

/**
 * Start A Transaction Request by passing in a payment request
 *
 Works just like the other device_startTransaction method except a protocol was introduced to stop the telescoping of the variables. This includes an optional email address that can be used
 in the event of an offline decline to send a receipt (an emv certification requirement).
 
 When this method is used the idtech framework will always turn on contactless first. if it identifies contactless it tries to process in that mode. If you instead insert the card it will process as a dip. if you swipe with a card with a chip the transaction will terminate and you will get an error saying to try chip first. if chip fails you will get indication to perform a
 fallback swipe.
 
 If you have an issue with processing a contactless card, and you are using this method, you can get around the contactless check by first inserting the chip card. The idtech framework will
 ignore contactless and try to process the chip.
 
 * @return RETURN_CODE:  Values can be parsed with errorCode.getErrorString()
 
 */
-(RETURN_CODE) device_startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest;


/**
* Start A Transaction by passing in a payment request.
*
Works just like the deprecated device_startTransaction method except now you can provide a connection object instructing the framework to connect to a bluetooth device or an audio jack reader. This includes an optional email address that can be used in the event of an offline decline to send a receipt (an emv certification requirement).
 
* @return ClearentResponse:  Contains details about starting transaction. Feedback will also be echoed back to user thru the feedback delegate method.

*/
-(ClearentResponse*) startTransaction:(id<ClearentPaymentRequest>) clearentPaymentRequest clearentConnection:(ClearentConnection*) clearentConnection;

/**
 The reader has a contactless configuration applied each time connects. After a successful configuration the device serial number and a flag denoting the reader was configured for contactless is stored using NSUserDefaults. If there is a need to clear out this information, maybe to support a configuration change/future updates, call this method to clear out the cache.
 */
- (void) clearContactlessConfigurationCache;

/**
 Set BLE Service Scan Filter.
 
 When searching for BLE devices, this will limit the service search to the provided service ID's
 
 Example data format:
 NSArray<CBUUID *> *filter = [[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:@"1820"], nil];
 
 @param filter The array of services to filter for
 */
-(void) setServiceScanFilter:(NSArray<CBUUID *> *) filter;

/**
Set BLE Service Scan Filter.
Filter out all service ids except for 1820, which is what IDTech readers use.
*/
- (void) setServiceScanFilterWithService1820;

/**
Set BLE Service Scan Filter.
Filter out all service uuids except for those supported (VP3300,VP3350)
*/
- (void) setSupportedServiceScanFilters;
/**
If you did not instruct the framework to do any configuration when you initialized the vp3300 object, you can use the set methods to pick which configuration you want applied, then call this method to apply the configuration. The emv/contact configuration usually takes up to a minute and the contactless takes about 45 seconds.
    */

-(void) applyClearentConfiguration;


/**
 Inspects the reader configuration to determine if contactless configuration has been applied. Must be connected to reader.
 If you get RETURN_CODE_DO_SUCCESS back then contactless has been configured. RETURN_CODE_ERR_DISCONNECT means the reader is not connected. RETURN_CODE_NO_DATA_AVAILABLE_ is returned when not configured
 */
-(RETURN_CODE) isContactlessConfigured;

/**
 Inspects the reader configuration to determine if the reader has been preconfigured. Must be connected to reader.
 If you get RETURN_CODE_DO_SUCCESS back then reader has been preconfigured. RETURN_CODE_ERR_DISCONNECT means the reader is not connected. RETURN_CODE_NO_DATA_AVAILABLE_ is returned when not configured
 */
-(RETURN_CODE) isReaderPreconfigured;


/**
 * The Clearent solution includes remote logging to aid in support calls. If you want to contribute to these logs pass us
 * some identification, preferably the name and version of your solution, and a brief log message.
 */
- (void) addRemoteLogRequest:(NSString*) clientSoftwareVersion message:(NSString*) message;


/**
* This method is most useful when its called internally from the startPayment method. But, if there is a reason to attempt a connection prior to running the card you can use this method.
* One reason might be to get back a list of bluetooth devices (from the public delegate) so you can present a list of devices to the user.
*/
-(void) startConnection:(ClearentConnection*) clearentConnection;

//- (void) adjustBluetoothAdvertisingInterval;



/**
 * When using the startTransaction method that allows you to pass in a ClearentConnection, the framework will save off the bluetooth device id of the last device it connected with. With each subsequent call to the startTransaction
 * the framework is aware the connection request could change and will clear out the stored bluetooth device id when appropriate. But, in case it does not, here is a method you can use to clear it out.
 */
- (void) clearBluetoothDeviceCache;

/**
 *  Remote logs are delayed. if you want to send them immediately call this.
 */
- (void) sendRemoteLogs;

/**
 *  If you've created a Clearent_VP3300 object and just want to change the publicKey for a given Merchant you set the public key
 */
- (void) setPublicKey:(NSString*)publicKey;

/**
 *  If you've created a Clearent_VP3300 object and just want to change the offline mode on or off
 */
- (void)setOfflineMode:(BOOL)offlineMode;

- (void)fetchTransactionToken:(NSData*)postData completion:(void (^_Nullable)(ClearentTransactionToken* _Nullable))completion;

@end


