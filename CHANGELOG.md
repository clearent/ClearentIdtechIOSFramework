# iOS SDK Changelog

## 1.1.166.019
### 4/21/22
Restored btServices service filter
Added method setServiceUUID
Added method setBLEDeviceTypeVP3300

## 1.1.166.018
### 3/28/22
Changed mapping of status byte + 0xee00 to parser level instead of api level

## 1.1.166.017
### 3/14/22
Changed deviceMessage to return on main thread without waiting to finish

## 1.1.166.016
### 3/3/22
Check if centralmanager is power on state before attempting to scan

## 1.1.166.015
### 12/22/21
Added fix to allow methods to execute properly within device connected callback

## 1.1.166.014
### 12/3/21
Reset centralManager to nil for enableBLEDeviceSearch to correctly re-init second attempt

## 1.1.166.013
### 12/2/21
Updated enableBLEDeviceSearch to reset central manager upon execution

## 1.1.166.012
### 11/29/21
Updated BLE Device Auto-Reconnect

## 1.1.166.011
### 11/12/21
Updated device_enableBLEDeviceSearch to reset UUID


## 1.1.166.010
### 9/17/21
Restored write without response

## 1.1.166.009
### 9/17/21
Added a 1 second connection start delay on BLE to overcome VP3600 reconnect issues

## 1.1.166.008
### 8/11/21
Added/Updated the following error codes:
EMV_RESULT_CODE_V2_SWIPE_NON_ICC = 0x0011,  (renamed from EMV_RESULT_CODE_V2_MSR_SUCCESS)
EMV_RESULT_CODE_V2_TRANSACTION_CANCELLED = 0x0012,
EMV_RESULT_CODE_CTLS_TWO_CARDS = 0x7A,
EMV_RESULT_CODE_CTLS_TERMINATE = 0x7E,
EMV_RESULT_CODE_CTLS_TERMINATE_TRY_ANOTHER = 0x7D,
EMV_RESULT_CODE_MSR_SWIPE_CAPTURED = 0x80,
EMV_RESULT_CODE_REQUEST_ONLINE_PIN = 0x81,
EMV_RESULT_CODE_REQUEST_SIGNATURE = 0x82,
EMV_RESULT_CODE_FALLBACK_TO_CONTACT = 0x83,
EMV_RESULT_CODE_FALLBACK_TO_OTHER = 0x84,
EMV_RESULT_CODE_REVERSAL_REQUIRED = 0x85,
EMV_RESULT_CODE_ADVISE_REQUIRED = 0x86,
EMV_RESULT_CODE_ADVISE_REVERSAL_REQUIRED = 0x87,
EMV_RESULT_CODE_NO_ADVISE_REVERSAL_REQUIRED = 0x88,
EMV_RESULT_CODE_UNABLE_TO_REACH_HOST = 0xFF,
EMV_RESULT_CODE_V2_MSR_CARD_READ_ERROR = 0x3012,

## 1.1.166.007
### 8/10/21
added device_setTerminalData:(NSData*)tags
added  device_retrieveTerminalData:(NSData**)responseData
added device_addTLVToTerminalData:(NSData*)tlv

## 1.1.166.006
### 8/09/21
Fixed IDT_Device , IDT_Neo2-> device_getSpecialFunctionOrFeature

## 1.1.166.005
### 8/05/21
added IDT_Device , IDT_Neo2-> device_setSpecialFunctionOrFeature
added IDT_Device , IDT_Neo2-> device_getSpecialFunctionOrFeature

## 1.1.166.004
### 8/04/21
added IDT_Device -> antennaControl
added IDT_NEO2 -> device_antennaControl
added IDT_Device -> exchangeContactlessData
added IDT_NEO2 -> device_exchangeContactlessData

## 1.1.166.003
### 7/13/21
removed disconnect if set device type is current device type

## 1.1.166.001
### 7/09/21
Added PROTOCOL_STRING_NEO = @"com.idtechproducts.neo"
Added + (NSString*) externalAccessoryProtocol
Added + (void) setExternalAccessoryProtocol:(NSString*)newValue

## 1.1.165.004
### 6/11/21
Added felica_SendCommand

## 1.1.165.003
### 5/26/21
Updated connecting to BLE

## 1.1.165.002
### 1/3/21
Fixed transaction timeout issue when running ctls_startTransaction

## 1.1.165.001
### 1/2/21
Added support for VP6800 BLE

## 1.1.164.005
### 1/29/21
Automatically disconnect from previous ble scan session when starting new session 

## 1.1.164.004
### 1/25/21
Fixed time sync from Hour/Month to Hour/Second 

## 1.1.164.003
### 1/22/21
Added device_syncTime for VP3300 
Added VP3300 time syncing upon start transaction SUIIS-36

## 1.1.164.002
### 1/15/21
Added device_syncClock for VP3300 
Added VP3300 clock syncing upon device connect SUIIS-36


## 1.1.164.001
### 1/08/21
Added device_pollForToken (command 2c-02) to NEOII class

## 1.1.163.016
### 9/02/20
Moved dispatch queues for BLE and Audio from Main to Unque

## 1.1.163.015
### 8/04/20
Remove Tag Queue (combining TLV dictionaries)

## 1.1.163.014
### 8/02/20
Added activateTransaction to NEO2/VP3300 class

## 1.1.163.013
### 7/23/20
Added method resetSingleton to IDT_Device class
Fixed createFastEMV DFEE23 tag size
Fixed createFastEVM to add DFEE25SPS_SERVICE_3600

## 1.1.163.012
### 7/21/20
Updated createFastEMV to fix 9F1E data issue
Added UniMag Pro class 
Added additional UniMag Support

## 1.1.163.011
### 7/20/20
Updated createFastEMV to fix DFEE23 length issue

## 1.1.163.010
### 7/17/20
Updated VP3600 TX Characteristic from 49535343-1E4D-4BD9-BA61-23C647249616 to 49535343-4c8a-39b3-2f49-511cff0773b7e CS-3429


## 1.1.163.009
### 6/29/20
Remove compilier warnings duplicate methods/symbols CS-3396
Added VP3350 Support

## 1.1.163.008
### 6/17/20
Incorporated UniMag legacy library 7.21 and re-enabled UniMag support
Added getDeviceType to IDT_Device class

## 1.1.163.007
### 6/17/20
Added BLE support for VP3350

## 1.1.163.006
### 6/10/20
Updated SDK to recognize msr result code change from 0x11 to 0x07

## 1.1.163.005
### 5/27/20
Added parseEnhancedMSRFormat to IDTUtility
Parse DFEE23 to card data object when returning EMV data callback

## 1.1.163.004
### 4/30/20
Fixed crash when DFEE23 has no card data
Fixed swipe delegate to execute on swipe of non-icc card

## 1.1.163.003
### 4/30/20
Fixed SDK incorrectly activating ICC Present EMV transaction when a
bad swipe event returns DFEE23 with no card data.

## 1.1.163.002
### 4/28/20
Removed setting emv card data to nil immedately after sending to delegate
Added sending emv card data to msr swipe callback if msr data and callback exists
Update BLE routines to separate combined ble message when ctls active 01-05x1905

## 1.1.163.001
### 4/27/20
Updated CTLS message processing 01-05x1905
Removed duplicate activate transaction when no response

## 1.1.162.002
### 4/7/20
Updated createFastEMVData to convert emvData to FastEMV KB String

## 1.1.162.001
### 4/2/20
Added createFastEMVData to convert emvData to FastEMV KB String

## 1.1.161.002
### 3/13/20
Added rejecting MSR card swipe on device_startTransaction -> request insert instead if chip present  CS-3124

## 1.1.161.001
### 3/12/20
Added auto BLE filtering when device type = VP3300
Decreased device recognition time for BLE VP3300

## 1.1.160.002
### 2/14/20
Updated iMag Pro support

## 1.1.159.005
### 1/16/20
 Added +(void) keepDFEE23:(bool)keep;

## 1.1.159.004
### 1/9/20
Resolved dead lock condition when calling disconnect from audio reader on ios 13.0+

## 1.1.159.003
### 11/26/19
Added removeCommandDelay to IDT_Device class to speed up audio transactions

## 1.1.159.002
### 11/06/19
Fixed BLE connection.
Fixed BLE UI interrupt

## 1.1.159.001
### 11/06/19
Added kernel messages to SDK when IDTech.bundle is missing

## 1.1.159
### 11/05/19
Added protocol for ctlsEvent
Added retrieveCTLSMessage to IDTUtility

## 1.1.158
### 10/22/19
Changed DelayConnection from timer to  GCD dispatch_after to avoid UI blocking

## 1.1.157
### 10/14/19
Fixed audio jack drivers for iOS 13

## 1.1.156
### 9/30/19
Compatibility issue from 13.0/13.1 addressed using uppercase fix
Added swipe/tap/insert message for device_startTransaction VP3300
Added swipe/tap message for ctls_startTransactions VP3300

## 1.1.155
### 9/26/19
Compatibility issue from 13.0/13.1 addressed:  NSData Description changed formatting causing data comparison errors.

## 1.1.152
### 9/15/19
*When CTLS/MSR, and no status code available, set to NEO_REQUEST_ONLINE_AUTOHRIZATION
*Recognize LCD message during EMV tranaction as unsoliciated data and correctly process

## 1.1.151
### 8/23/19
*Added setServiceScanFilter

## 1.1.150
### 8/23/19
* Added primary service ID 180A for NEOII

## 1.1.149
### 8/23/19
* For bluetooth connections, limit scanning for only IDTech services SDKIOS-16
* Processing recieved data in some cases returned null data SDKIOS-15

## 1.1.148
### 8/22/19
* Added IDT_Device.bypassEventCheck to allow bypassing checking of SDK status on next command

## 1.1.147
### 8/9/19
* Fixed the reversal of encrypted/masked tags being returned <SDKIOS-9>

## 1.1.146
### 8/1/19
* Updated language table (both bundle resource and SDK) <SDKIOS-13>

## 1.1.145
### 7/12/19
* Updated combine tags while fixing swipe crash <TS-16974>

## 1.1.144
### 7/11/19
* Restored combining emv tags from each step into final output

## 1.1.143
### 6/27/19
* Fixed Contact cards not reporting correctly for card type

## 1.1.142
### 5/31/19
* Added device_sendGen2Command
* Added Gen2 protocol

## 1.1.141
### 4/25/19
* Added pinRequest to NEOII class
* Made all shared controllers execute on main thread

## 1.1.139
### 3/20/19
* Added BLE support for VP3320

## 1.1.137
### 12/28/18
* Will check for firmware version before reporting connected over BLE

## 1.1.136
### 12/27/18
* Resolved BLE reconnect when going to sleep and not authenticated

## 1.1.135
### 12/21/18
* Resolved filtering bad MSR swipes over BLE

## 1.1.134
### 11/31/18
* 201810310800MP: Fixed no CVM from 3F to 1F on 9F34

## 1.1.133
### 7/26/18
* Removed pingVIVO from UniPay 1.5 startTransaction

## 1.1.132
### 7/25/18
* Fixed NEO II to use tag DFEE3C when sending 02-40

## 1.1.130
### 5/30/18
* Fixed SVIS-57: retrieveTransactionResults crashing on null output

## 1.1.129
### 5/30/18
* Fixed SVIS-56: ctls_setCAPKFile does not work with old good parameters

## 1.1.127
### 5/23/18
* Added checking for Lidera BT module 300ms delay issue
* Fixed SVIS-51: long command timout for Lierda BT module

## 1.1.125
### 5/16/18
* Fixed SVIS-31: confusing response values from enableBLEDeviceSearch
* Fixed SVIS-52: aAdded Set Bluetooth Parameters

## 1.1.124
### 5/16/18
* Updated NEOII PIN methods to stop double execution
* Update enableBLE to change scanning parameters
* Added "NOUNIMAG" compiler directives to eliminate unimag from SDK
* Fixed SVIS-40: pinCapturePin not get the error status

## 1.1.118
### 4/24/18
* Fixed Apple VAS recognize code 0x57
* Fixed NEOII BLE Methods
* Fixed SVIS-46: device_startTransaction does not enter correct status

## 1.1.117
### 4/16/18
* NEOII Updates
* Fixed SVIS-22: buttons in demo app incorrectly wired
* Fixed SVIS-37: emv_setCRLEntries does not incldue MAC lenght
* Fixed SVIS-39: pinCaptureAmountInput will cause crash
* Fixed SVIS-47: write felica without MAC issue
* Fixed SVIS-48: result display issue for felica related functions
* Fixed SVIS-49: device_disconnectBLE does not clear connected status

## 1.1.116
### 4/13/18
* Mobelisk ignore 0x63 when threading

## 1.1.115
### 4/02/18
* Fixed SVIS-18: felica_nfcCommand uses wrong command
* Fixed SVIS-19: large amount not accepted in 9F02 for startTransaction
* Fixed SVIS-24: startTransaction needs to support 2 bytes
* Fixed SVIS-25: forceOnline has no effect with startTransaction
* Fixed SVIS-26: amtOther has no effect with startTransaction
* Fixed SVIS-27: timeout2 has no effect with startTransaction
* Fixed SVIS-28: fallback parameter needs to affect related TLV data with startTransaction
* Fixed SVIS-34: applicationData only support up to 8 bytes AID

## 1.1.115
### 4/02/18
* fixed ctls_retrieveAID
* fixed ble UDID reporting
* Fixed SVIS-18: felica_nfcCommand uses wrong command
* Fixed SVIS-19: large amount not accepted in 9F02 for startTransaction
* Fixed SVIS-20: unexpected value for 9F02 with some double amount
* Fixed SVIS-33: emv_removeApplicationData does not support null parameter
* Fixed SVIS-38: pin_captureNumericInput not allowed to be 0x10
* Fixed SVIS-42: felica_read block list support incorrect
* Fixed SVIS-43: felica_write block list support incorrect

## 1.1.113
### 3/15/18
* fixed ctls_retrieveAID
* fixed ble UDID reporting
* Fixed SVIS-14 response issue with ctls_retrieveApplicationData
* Fixed SVIS-16 demo app touch screen issue
* Fixed SVIS-17 no ble uuid if device is disconnected

## 1.1.112
### 3/9/18
* removed ctls_startTransaction without parameters
* removed VP3600 class
* added NEOII class
* fixed ctls_retrieveAID to now use 9F06 as identifier
* Fixed SVIS-8: ctlsStartTransaction parameter issue
* Fixed SVIS-10: wrong name device_isConnected
* Fixed SVIS-13: ctls_retrieveApplicationData does not apply AID name

## 1.1.110
### 3/5/18
* Fixed VP3600 to use new tags (ffe4->dfee2d)
* Fixed SVIS-9 ctlsStartTransaction parameter issue
* Fixed SVIS-11 crash if user press cancel key to stop Capture Numeric

## 1.1.109
### 3/2/18
* Added follow feliCA commands:
* felica_authentication
* felica_readWithMac
* felica_writeWithMac
* felica_read
* felica_write
* ctls_nfcCommand
* felica_requestService

## 1.1.108
### 2/28/18
* Added .07 second delay between packets

## 1.1.107
### 2/26/18
* Changed BLE packet length to 150

## 1.1.103
### 2/6/18
* Changed BLE packet length to 200

## 1.1.102
### 1/29/18
* Added VP3600 classes
* -added PIN cancel
* -added Capture PIN
* -added Capture Function Key
* -added Capture Numeric Input
* -added Capture Amount Input
* Changed EMV Kernel (UniPay) to report type 90 instead of 80 for non ICC EMV swipes

## 1.1.101
### 12/21/17
* Added pinRequest delegate
* added emv_callbackResponsePIN
* Added support for 61-02 PIN callbacks

## 1.1.100
### 7/28/17
* Removed VP4880
* Removed UniPayIII
* Added support for device_startTransaction (all interfaces VP3300)
* Added service code checking for unencrypted track 2 to set card.iccPresent

## 1.1.099
### 6/26/17
* Renamed class BTPayMini to VP3300

## 1.1.098
### 6/14/17
* Added VP4880 support (bypass data)
* Added methods to bypass data:
* protocol bypassData to receive data from SDK
* method to send response to sdk processBypassResponse
* method to set bypass delegate assignBypassDelegate

## 1.1.097
### 5/24/17
* Fixed ITP over BLE (for RKI)
* Fixed BLE wake on ios suspend/sleep
* Enable floor limit in TVR always TRUE
* Fixed SWBTPAYM-1: bluetooth can't communicate after standy by for a while after connectiong bluetooth
* Fixed SWBTPAYM-10: device_startRKI fail return no customer/key information found

## 1.1.096
### 5/11/17
* Updated RKI routines to use correct getFirmware command
* Added device_setBurstMode for UniPayIII/BTPayMini
* Added device_setPollMode for UniPayIII/BTPayMini
* Added device_getAutoPollTransactionResults for UniPayIII/BTPayMini

## 1.1.095
### 4/28/17
* Fixed SWBTPAYM-9: updated ctls_startTransaction to use activate transaction 

## 1.1.094
### 4/26/17
* Fixed SWBTPAYM-6:  BTPayMini BLE, EMV stopped on menu selection 
* Fixed SWBTPAYM-8: UniPayIII/BTPay Mini ctls_retrieveTerminalData 
* Fixed SWBTPAYM-7: UniPayIII/BTPay Mini ctls_removeApplicationData AID length wrong 
* Fixed SWBTPAYM-8: UniPayIII/BTPay Mini emv_setCAPK sending wrong command 

## 1.1.093
### 4/25/17
* Fixed SWBTPAYM-4:   BTPayMini BLE, UniPayIII ctls_setApplicationData

## 1.1.092
### 4/25/17
* Fixed SWBTPAYM-3:  BTPayMini BLE Retrieve CAPK

## 1.1.091
### 4/24/17
* Fixed SWBTPAYM-2: BTPayMini BLE Remove CAPK
* EMV Build 201704250800: Set 9F39 to return 05, not 07


## 1.1.090
### 4/18/17
* Added BTPayMini classes
* Added missing CTLS functions from UniPayIII/BTPayMini
* Added BTPayMini get/set Friendly Name to search for on BLE
* EMV Build 201704171200: removed ICC swipe checking when non-kernel startMSR
* no ICC service code checking on non-kernel initiated startMSR Swipe

## 1.1.088
### 3/10/17
* Fixed UniPayIII bad swipe over BLE

## 1.1.086
### 2/02/17
* Removed duplicate symbol issue reported by Vantiv

## 1.1.085
### 12/23/16
* Updated UniPay 1.5, UniPayIII CTLS reading. Needed to add delay due to timing issue
* Fixed SUIIS-27: UniPay III, ctls_startTransaction API returned error  
* Fixed SUIIS-28: UniPay III, icc_exchangeAPDU API APDUResponse* response sw1 and sw2 wrong  
* Fixed SUIIS-30: UniPay III, device_startRKI fail  


## 1.1.084
### 12/14/16
* Updated UniPay 1.5 audio support
* Updated UniPay III audio support

## 1.1.082
### 10/6/16
* Added UniPayIII BLE Support
* Added support for XCode 8
* Added bitcode support

## 1.1.080.006
### 9/22/16
* Enhanced multiple audio support detection

## 1.1.080.005
### 9/22/16
* Updated audio drivers for iPhone 7 and multiple audio ports

## 1.1.080.004
### 9/21/16
* Configured UniPay volume to 60%

## 1.1.078
### 4/28/16
* Fixed SUIIS-23: UniPay III, Do Stress Test EMV Loop Test - KSN data FFEE12 value always respnse fixed value. 
* Fixed SUIIS-24: UniPay III, msr_startMSRSwipe swipe MSR Card, but receive emvTransactionData format 

## 1.1.076
### 4/26/16
* Fixed SUIIS-21: UniPay III API emv_disableAutoAuthenticateTransaction:true issue. 
* Fixed SUIIS-22: UniPay III, device_sendIDGCommand:subCommand call 18 01 Ping command, SDK Crash. 

## 1.1.075
### 4/22/16
* Fixed SUIIS-6: UniPayIII EMVL2 Trans select language SDK always crash. 
* Fixed SUIIS-20: UniPayIII APIs ctls_startTransaction and msr_startMSRSwipe issue - finish a contactless card reading, SDK still stand in doing MSR or ICC task. 

## 1.1.074
### 4/21/16
* Fixed SUIIS-1: UnPayIII successive ctls_startTransaction and swipe Card SDK will Crash. 
* Fixed SUIIS-2: UniPayIII Lack Key Management Parameter command API to get and set Data Encryption Enable flag
* Fixed SUIIS-4: UniPayIII emv_getEMVL2Version response version data string contain protocol redundant data
* Fixed SUIIS-7: UniPayIII communication sequential issue
* Fixed SUIIS-8: UniPayIII emv_setCRLEntries:CRL issue
* Fixed SUIIS-9: UniPayIII Start EMV Trans without terminal data, SDK will stay in EMV trans logic type
* Fixed SUIIS-11: UniPayIII emv_completeOnlineEMVTransaction issue
* Fixed SUIIS-12: UniPayIII EMVL2 Trans Logic State issue
* Fixed SUIIS-13: UniPayIII emv_startTransaction set invalid parameter issue
* Fixed SUIIS-14: UniPayIII Call APIs getResponseCode issue while SDK doing MSR, CTLs or ICC Trans task
* Fixed SUIIS-15: UniPayIII emv_completeOnlineEMVTransaction set invalid parameter issue
* Fixed SUIIS-16: UniPayIII API emv_setApplicationData set wrong parameter (Name, APDUs), return RETURN_CODE_DO_SUCCESS
* Fixed SUIIS-17: UniPayIII API emv_removeApplicationData issue, remove name not exist, still response RETURN_CODE_DO_SUCCESS
* Fixed SUIIS-18: UniPayIII API emv_setCAPKFile set wrong CAPK file return RETURN_CODE_DO_SUCCESS 
* Fixed SUIIS-19: UniPayIII API emv_retrieveCAPKFile error parameter  

## 1.1.044
### 12/30/14
* Fixed BTPTWOHIOSSDK-56: emv_startEMVTransaction error message 
* Fixed BTPTWOHIOSSDK-57: bluetooth connection issue 

## 1.1.043
### 12/24/14
* Fixed BTPTWOHIOSSDK-45: emv_getTag:tagData error when disconnect 
* Fixed BTPTWOHIOSSDK-48: bluetooth reconnection issue 

## 1.1.042
### 12/23/14
* Fixed BTPTWOHIOSSDK-37: demo will analyze response data as card data
* Fixed BTPTWOHIOSSDK-52: msr_setEncryptMSRFormat: used the same command

## 1.1.041
### 12/22/14
* Fixed BTPTWOHIOSSDK-14: analyze response data from track2
* Fixed BTPTWOHIOSSDK-46: error table spelling mistake
* Fixed BTPTWOHIOSSDK-47: the new firmware Device serial number must be 10 characters
* Fixed BTPTWOHIOSSDK-55: change icc_exchangeAPDU response

## 1.1.037
### 11/19/14
* Fixed UPIIIOSSDK-25: Exchange APDU Encryption 72 46 63 ... command API issue
* Fixed UPIIIOSSDK-26: icc_getKeyFormatForICCDUKPT API issue : send wrong command [78 52 01 02]
* Fixed UPIIIOSSDK-27: icc_getKeyTypeForICCDUKPT send wrong command: [78 520101] 
* Fixed UPIIIOSSDK-28: UniPay II firmware ICC power on, not support PowerOnStructure paramater
* Fixed UPIIIOSSDK-29: icc_setKeyFormatForICCDUKPT:(int)encryption; API issue : send wrong command ID [7253010201 + option]

## 1.1.036
### 11/13/14
* Fixed UPIIIOSSDK-24: icc_exchangeAPDU API issue: response APDU and SW1 & SW2 wrong

## 1.1.031
### 10/29/14
* Fixed UPIIIOSSDK-1: Connect Issue
* Fixed UPIIIOSSDK-4: first time running UniPayII SDK Demo always shows view message
* Fixed UPIIIOSSDK-6: unable to receive messages from framework
* Fixed UPIIIOSSDK-8: transaction cancel on pin entry
* Fixed UPIIIOSSDK-9: visa card incorrectly approved
* Fixed UPIIIOSSDK-10: missing masked tag 57 / 5A
* Fixed UPIIIOSSDK-11: incomplete unencrypted tags
* Fixed UPIIIOSSDK-18: UniPayII not support f_GetPinPadStatus
* Fixed UPIIIOSSDK-19: cancel command to cancel get function key.
* Fixed UPIIIOSSDK-20: Get function key demo operation issue.

## 1.1.029
### 10/17/14
* Fixed BTPTWOHIOSSDK-22: message: not connect with reader after cancel pin quickly in iphone and ipad
* Fixed BTPTWOHIOSSDK-23: MAC demo crash after Get ICC Reader Status

## 1.1.028
### 10/10/14
* Fixed BTPTWOHIOSSDK-17: send hash data of CA key error

## 1.1.027
### 10/01/14
* Fixed BTPTWOHIOSSDK-9: APDU command static value
* Fixed BTPTWOHIOSSDK-10: Disable response check is INT
* Fixed BTPTWOHIOSSDK-11: getEncryptedMSRFormat error
* Fixed BTPTWOHIOSSDK-12: setEncryptedMSRFormat error


