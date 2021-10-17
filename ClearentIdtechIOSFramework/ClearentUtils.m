//
//  ClearentUtils.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/29/19.
//  Copyright © 2019 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentUtils.h"
#import <sys/utsname.h>
#import "ClearentLumberjack.h"

static NSString *const DEVICESERIALNUMBER_STANDIN = @"9999999999";
static NSString *const SDK_VERSION = @"2.1.0";
static NSString *const DATE_FORMAT = @"yyyy-MM-dd-HH-mm-ss-SSS-zzz";
static NSString *const PLATFORM = @"IOS";
static NSString *const DEFAULT_EMBEDDED_VALUE = @"LOG";

@implementation ClearentUtils

+ (NSString *) createExchangeChainId:(NSString*) embeddedValue {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:DATE_FORMAT];
    NSDate *now = [[NSDate alloc] init];
    NSString *dateTime = [dateFormat stringFromDate:now];
    if(embeddedValue == nil) {
        return [NSString stringWithFormat:@"%@-%@-%@", PLATFORM, DEFAULT_EMBEDDED_VALUE, dateTime];
    } else {
        return [NSString stringWithFormat:@"%@-%@-%@", PLATFORM, embeddedValue, dateTime];
    }
}

+ (NSString*) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine
                                              encoding:NSUTF8StringEncoding];
    if(deviceName == nil) {
        deviceName = @"unknown";
    }
    return deviceName;
}

+ (NSString*) osVersion {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSString *osVersion = [processInfo operatingSystemVersionString];
    if(osVersion == nil) {
        osVersion = @"unknown";
    }
    return osVersion;
}

+ (NSString*) sdkVersion {
    return SDK_VERSION;
}

+ (NSDictionary*) hostProfileData {
    return  @{@"platform":@"Apple",@"os-version":[ClearentUtils osVersion],@"sdk-version":[ClearentUtils sdkVersion],@"model":[ClearentUtils deviceName]};
}

+ (NSString*) getIDtechErrorMessage:(int)code {
        {
            switch ((int)code)
            {

                case 0: return @"no error, beginning task";
                case 1: return @"no response from reader";
                case 2:return @"invalid response data";
                case 3: return @"time out for task or CMD";
                case 4:return @"wrong parameter";
                case 5: return @"SDK is doing MSR or ICC task";
                case 6: return @"SDK is doing PINPad task";
                case 7:return @"SDK is doing CTLS task";
                case 8:return @"Firmware return timeout value";
                case 9: return @"SDK is doing Other task";
                case 10:return @"err response or data";
                case 11: return @"no reader attached";
                case 12:return @"mono audio is enabled";
                case 13:return @"did connection";
                case 14:return @"audio volume is too low";
                case 15:return @"task or CMD be canceled";
                case 16: return @"UF wrong string format";
                case 17:return @"UF file not found";
                case 18:return @"UF wrong file format";
                case 19:return @"Attempt to contact online host failed";
                case 20: return @"Attempt to perform RKI failed";
                case 21: return @"Missing DLL.  Cannot access device.";
                case 22: return @"Firmware Block Transfer Successful";
                case 23: return @"SDK is doing Firmware Update task";
                case 24: return @"Applying the firmware update downloaded to memory";
                case 25: return @"No Data Available";
                case 26: return @"SDK Busy doing file transfer task";
                case 27: return @"Applying the file transfer";
                case 28: return @"File Transfer Successful";
                case 29: return @"Not enough space available on drive";
                case 30: return @"Entering Bootload Mode";
                case 31: return @"Starting Firmware Update";
                case 32: return @"PCI File Mismatch";
                case 33: return @"Incorrect FW File Block Size";
                case 34:
                    return @"Device is busy finalizing transaction.";
                case 35:
                    return @"The SDK Busy doing RKI update";
                case 36:
                    return @"Bad MSR Swipe";
                case 37:
                    return @"Financial card not allowed";
                case 38:
                    return @"SDK Busy waiting for input event";
                case 39:
                    return @"Unsupported Command";
                case 40:
                    return @"Erasing SPI VP8800";
                case 41:
                    return @"SDK is doing EMV task";
                case 42:
                    return @"SDK is doing Camera task";
                case 43:
                    return @"SDK is doing ViVO Config task";
                case 44:
                    return @"SDK is starting VIVO Config task";
                case 45:
                    return @"SDK is finishing ViVO Config task";
                case 46:
                    return @"ViVO Config task failed";
                case 47:
                    return @"ViVO Config Message";
                case 48:
                    return @"Failed to change ViVO Config mode";
                case 49:
                    return @"VivoConfig updated was cancelled";
                case 50:
                    return @"ViVO Config Verify Success";
                case 51:
                    return @"ViVO Vonfig Verify failure";
                case 0x100: return @"Log is full";
                case 0x300: return @"Key Type(TDES) of Session Key is not same as the related Master Key.";
                case 0x400: return @"Related Key was not loaded.";
                case 0x410: return @"Non-SRED Device need Load Manufacture Key and Firmware Key.";
                case 0x500: return @"Key Same.";
                case 0x501: return @"Key is all zero";
                case 0x502: return @"TR-31 format error";
                case 0x700: return @"No BDK of Pairing MSR Key.";
                case 0x701: return @"Have BDK of Pairing MSR Key, Not Pairing with MSR (No PAN Encryption Key)";
                case 0x702: return @"PAN is Error Key.";
                case 0x703: return @"Pairing Failed";
                case 0x704: return @"MSR Pairing Key Other Error";
                case 0x705: return @"No Internal MSR PAN (or Internal MSR PAN is erased timeout)";


                case 0X0800: return @"Invalid Pinpad Data Received";
                case 0X0801: return @"Key Pad Cancel";
                case 0X0802: return @"External Command Cancel";
                case 0X0803: return @"Invalid Input Parameters";
                case 0X0804: return @"PAN Error";
                case 0X0805: return @"PIN DUKPT Key is absent";
                case 0X0806: return @"PIN DUKPT Key is exhausted";
                case 0X0807: return @"Display Error Message";
                case 0X080C: return @"Not Allowed";



                case 0X0C01: return @"Incorrect Frame Tag";
                case 0X0C02: return @"Incorrect Frame Type";
                case 0X0C03: return @"Unknown Frame Type";
                case 0X0C04: return @"Unknown Command";
                case 0X0C05: return @"Unknown Sub-Command";
                case 0X0C06: return @"CRC Error";
                case 0X0C07: return @"Failed";
                case 0X0C08: return @"Timeout";
                case 0X0C0A: return @"Incorrect Parameter";
                case 0X0C0B: return @"Command Not Supported";
                case 0X0C0C: return @"Sub-Command Not Supported";
                case 0X0C0D: return @"Parameter Not Supported / Status Abort Command";
                case 0X0C0F: return @"Sub-Command Not Allowed";
                case 0X0C57: return @"No Payment Occurred (VAS transaction)";
                case 0X0D01: return @"Incorrect Header Tag";
                case 0X0D02: return @"Unknown Command";
                case 0X0D03: return @"Unknown Sub-Command";
                case 0X0D04: return @"CRC Error in Frame";
                case 0X0D05: return @"Incorrect Parameter";
                case 0X0D06: return @"Parameter Not Supported";
                case 0X0D07: return @"Mal-formatted Data";
                case 0X0D08: return @"Timeout";
                case 0X0D0A: return @"Failed / NACK";
                case 0X0D0B: return @"Command not Allowed (Passthough Mode May Be On)";
                case 0X0D0C: return @"Sub-Command not Allowed";
                case 0X0D0D: return @"Buffer Overflow (Data Length too large for reader buffer)";
                case 0X0D0E: return @"User Interface Event";
                case 0X0D0F: return @"Decryption Error";
                case 0X0D11: return @"Communication type not supported, VT-1, burst, etc.";
                case 0X0D12: return @"Secure interface is not functional or is in an intermediate state.";
                case 0X0D13: return @"Data field is not mod 8";
                case 0X0D14: return @"Pad 0x80 not found where expected";
                case 0X0D15: return @"Specified key type is invalid";
                case 0X0D16: return @"Busy - device, resource or system is busy";
                case 0X0D17: return @"Hash code problem";
                case 0X0D18: return @"Could not store the key into the SAM(InstallKey)";
                case 0X0D19: return @"Frame is too large";
                case 0X0D1A: return @"Unit powered up in authentication state but POS must resend the InitSecureComm command";
                case 0X0D1B: return @"The EEPROM may not be initialized because SecCommInterface does not make sense";
                case 0X0D1C: return @"Problem encoding APDU";
                case 0X0D20: return @"Unsupported Index(ILM) SAM Transceiver error – problem communicating with the SAM(Key Mgr)";
                case 0X0D21: return @"Unexpected Sequence Counter in multiple frames for single bitmap(ILM) Length error in data returned from the SAM(Key Mgr)";
                case 0X0D22: return @"Improper bit map(ILM)";
                case 0X0D23: return @"Request Online Authorization (Contactless Only)";
                case 0X0D24: return @"ViVOCard3 raw data read successful";
                case 0X0D25: return @"Message index not available(ILM) ViVOcomm activate transaction card type(ViVOcomm)";
                case 0X0D26: return @"Version Information Mismatch(ILM)";
                case 0X0D27: return @"Not sending commands in correct index message index(ILM)";
                case 0X0D28: return @"Time out or next expected message not received(ILM)";
                case 0X0D29: return @"ILM languages not available for viewing(ILM)";
                case 0X0D2A:  return @"Other language not supported(ILM)";
                case 0X0D2B: return @"Device Not Ready";
                case 0X0D2C: return @"The 8341 operation was exited by the Cancel Transaction command";
                case 0X0D2D: return @"The 8341 operation was exited by the user pressing the cancel key";
                case 0X0D30: return @"Request Online Authorization (Contact Only)";
                case 0X0D31: return @"Request Online PIN (for Cardholder Verification Method -CVM)";
                case 0X0D32: return @"Request Signature (for Cardholder Verification Method - CVM)";
                case 0X0D33: return @"Advice Required";
                case 0X0D34: return @"Reversal Required";
                case 0X0D35: return @"Advice and Reversal Required";
                case 0X0D36: return @"No Advice or Reversal Required (Declined)";
                case 0X0D39: return @"Reserved";
                case 0X0D3A: return @"Fallback from Contact (ICC) to Magstripe";
                case 0X0D3B: return @"Fallback from Contactless to Contact";
                case 0X0D3C: return @"Fallback from Contactless to Magstripe";
                case 0X0D3D: return @"Fallback from Contactless to Other Interface";
                case 0X0D41: return @"Unknown Error from SAM";
                case 0X0D42: return @"Invalid data detected by SAM";
                case 0X0D43: return @"Incomplete data detected by SAM";
                case 0X0D44: return @"Reserved";
                case 0X0D45: return @"Invalid key hash algorithm";
                case 0X0D46: return @"Invalid key encryption algorithm";
                case 0X0D47: return @"Invalid modulus length";
                case 0X0D48: return @"Invalid exponent";
                case 0X0D49: return @"Key already exists";
                case 0X0D4A: return @"No space for new RID";
                case 0X0D4B: return @"Key not found";
                case 0X0D4C: return @"Crypto not responding";
                case 0X0D4D: return @"Crypto communication error";
                case 0X0D4E: return @"Module-specific error for Key Manager";
                case 0X0D4F: return @"All key slots are full (maximum number of keys has been installed)";
                case 0X0D50: return @"Key data is bad or corrupt";
                case 0X0D51: return @"Keys out of sync between contactless and contact interfaces (use this command on one interface at a time)";
                case 0X0D55: return @"Illegal duplicate data set";
                case 0X0D56: return @"Indication to fail the transaction to Pass Through Mode";
                case 0X0D57: return @"No payment transaction occurred. The response is loyalty only.";
                case 0X0D59: return @"Start Transaction successful. Perform Authentication..";
                case 0X0D60: return @"Data does not exist";
                case 0X0D61: return @"Data Full";
                case 0X0D62: return @"Write Flash Error";
                case 0X0D63: return @"OK and Have Next Command";
                case 0X0D64: return @"One Kernel was or some Kernels were disabled for absent or self-test error";
                case 0X0D70: return @"Antenna Error";
                case 0X0D80: return @"Use another card";
                case 0X0D81: return @"Insert or swipe card";
                case 0X0D90: return @"Data encryption Key does not exist";
                case 0X0D91: return @"Account DUKPT Key KSN exausted";
                case 0X0D92: return @"MAC DUKPT Key does not exist (if enable MAC verification)";
                case 0X0D93: return @"MAC DUKPT Key KSN exhausted (if enable MAC verification)";
                case 0X0D94: return @"No DEK / Desjardins Data Key / TransArmor RSA Cert";
                case 0X0D95: return @"Encryption Switch is Off";
                case 0X0DA3: return @"Error code for card insertion";
                case 0X0DA1: return @"The SD card does NOT exist";
                case 0X0DA0: return @"The screen or object already exists";
                case 0X0DA2: return @"Error decoding QR code";
                case 0X0DA4: return @"Error code for card insertion before sending a transaction command (for products with motors)";
                case 0X0DA5: return @"LCD control is rejected, due to LCD is not in working state";
                case 0x0D00: return @"This Key had been loaded.";
                case 0x0E00: return @"Base Time was loaded.";
                case 0x0F00: return @"Encryption Or Decryption Failed.";
                case 0x1000: return @"Battery Low Warning (It is High Priority Response while Battery is Low.)";
                case 0x1800: return @"Send “Cancel Command” after send “Get Encrypted PIN” &”Get Numeric “& “Get Amount”";
                case 0x1900: return @"Press “Cancel” key after send “Get Encrypted PIN” &”Get Numeric “& “Get Amount”";
                case 0x30FF: return @"Security Chip is not connect";
                case 0x3000: return @"Security Chip is deactivation & Device is In Removal Legally State.";
                //case 0x3005: return @"Removal detection not active";
                case 0x3010: return @"Master Chip was Activated.";
                //case 0x30FF: return @"Slave Chip is not connect.";
                case 0x3101: return @"Security Chip is activation &  Device is In Removal Legally State.";
                case 0x5500: return @"No Admin DUKPT Key.";
                case 0x5501: return @"Admin  DUKPT Key STOP.";
                case 0x5502: return @"Admin DUKPT Key KSN is Error.";
                case 0x5503: return @"Get Authentication Code1 Failed.";
                case 0x5504: return @"Validate Authentication Code Error.";
                case 0x5505: return @"Encrypt or Decrypt data failed.";
                case 0x5506: return @"Not Support the New Key Type.";
                case 0x5507: return @"New Key Index is Error.";
                case 0x5508: return @"Step Error.";
                case 0x5509: return @"KSN Error";
                case 0x550A: return @"MAC Error.";
                case 0x550B: return @"Key Usage Error.";
                case 0x550C: return @"Mode Of Use Error.";
                case 0x550F: return @"Other Error.";
                case 0x5530: return @"Key Number Error";
                case 0x5531: return @"Key Block length error";
                case 0x5532: return @"Key Length Error";
                case 0x5533: return @"HMAC checking error";
                case 0x6000: return @"Save or Config Failed / Or Read Config Error.";
                case 0x6200: return @"No Serial Number.";
                case 0x6900: return @"Invalid Command - Protocol is right, but task ID is invalid.";
                case 0x6A00: return @"Unsupported Command - Protocol and task ID are right, but command is invalid.";
                case 0x6A01: return @"Unsupported Command – Protocol and task ID are right, but command is invalid – In this State";
                case 0x6A02: return @"Unsupported Command - Protocol and task ID are right, but command is invalid - for disable";
                case 0x6B00: return @"Unknown parameter in command - Protocol task ID and command are right, but parameter is invalid.";
                case 0x6C00: return @"Unknown parameter in command – Protocol task ID and command are right, but length is out of the requirement.";
                case 0x6D00: return @"Beeper Control Error.";
                case 0x6D01: return @"LED Control Error.";
                case 0x6D10: return @"ICC Reading Function Disabled (Do Not Support ICC related reading characteristics commands).";
                case 0x6D11: return @"MSR Reading Function Disabled (Do Not Support MSR related reading characteristics commands)";
                case 0x7200: return @"Device is suspend (MKSK suspend or press password suspend).";
                case 0x7300: return @"PIN DUKPT is STOP (21 bit 1).";
                case 0x7400: return @"Device is Busy.";
                //case 0x7500: return @"Device is in diagnose mode.";
                case 0x7600: return @"Device is in Transparent Transmission mode";
                case 0xE100: return @"Can not enter sleep mode";
                case 0xE200: return @"File has existed";
                case 0xE300: return @"File has not existed";
                case 0xE313: return @"IO line low -- Card error after session start";
                case 0xE400: return @"Open File Error";
                case 0xE500: return @"SmartCard Error";
                case 0xE600: return @"Get MSR Card data is error";
                case 0xE700: return @"Command time out";
                case 0xE800: return @"File read or write is error";
                case 0xE900: return @"Active 1850 error!";
                case 0xEA00: return @"Load bootloader error";
                case 0xEF00: return @"Protocol Error- STX or ETX or check error.";
                case 0xEB00: return @"Picture is not exist";
                case 0x2C02: return @"No Microprocessor ICC seated";
                case 0x2C06: return @"no card seated to request ATR";
                case 0x2D01: return @"Card Not Supported,";
                case 0x2D03: return @"Card Not Supported, wants CRC";
                case 0x690D: return @"Command not supported on reader without ICC support";
                case 0x8100: return @"Timeout";
                case 0x8200: return @"invalid TS character received - Wrong operation step";
                case 0x8300: return @"Decode MSR Error";
                case 0x8400: return @"TriMagII no Response";
                case 0x8500: return @"No Swipe MSR Card";
                case 0x8510: return @"No Financial Card";
                case 0x8600: return @"Unsupported F, D, or combination of F and D";
                case 0x8700: return @"protocol not supported EMV TD1 out of range";
                case 0x8800: return @"power not at proper level";
                case 0x8900: return @"ATR length too long";
                case 0x8B01: return @"EMV invalid TA1 byte value";
                case 0x8B02: return @"EMV TB1 required";
                case 0x8B03: return @"EMV Unsupported TB1 only 00 allowed";
                case 0x8B04: return @"EMV Card Error, invalid BWI or CWI";
                case 0x8B06: return @"EMV TB2 not allowed in ATR";
                case 0x8B07: return @"EMV TC2 out of range";
                case 0x8B08: return @"EMV TC2 out of range";
                case 0x8B09: return @"per EMV96 TA3 must be > 0xF";
                case 0x8B10: return @"ICC error on power-up";
                case 0x8B11: return @"EMV T=1 then TB3 required";
                case 0x8B12: return @"Card Error, invalid BWI or CWI";
                case 0x8B13: return @"Card Error, invalid BWI or CWI";
                case 0x8B17: return @"EMV TC1/TB3 conflict*";
                case 0x8B20: return @"EMV TD2 out of range must be T=1";
                case 0x8C00: return @"TCK error";
                case 0xA304: return @"connector has no voltage setting";
                case 0xA305: return @"ICC error on power-up invalid (SBLK(IFSD) exchange";
                case 0xE301: return @"ICC error after session start";
                case 0xFF00: return @"Request to go online";
                case 0xFF01: return @"EMV: Accept the offline transaction";
                case 0xFF02: return @"EMV: Decline the offline transaction";
                case 0xFF03: return @"EMV: Accept the online transaction";
                case 0xFF04: return @"EMV: Decline the online transaction";
                case 0xFF05: return @"EMV: Application may fallback to magstripe technology";
                case 0xFF06: return @"EMV: ICC detected tah the conditions of use are not satisfied";
                case 0xFF07: return @"EMV: ICC didn't accept transaction";
                case 0xFF08: return @"EMV: Transaction was cancelled";
                case 0xFF09: return @"EMV: Application was not selected by kernel or ICC format error or ICC missing data error";
                case 0xFF0A: return @"EMV: Transaction is terminated";
                case 0xFF0B: return @"EMV: Other EMV Error";
                case 0xFFFF: return @"NO RESPONSE";
                case 0xF002: return @"ICC communication timeout";
                case 0xF003: return @"ICC communication Error";
                case 0xF005: return @"ICC Encrypted C - APDU Data Structure Length Error Or Format Error.";
                case 0xF00F: return @"ICC Card Seated and Highest Priority, disable MSR work request";
                case 0xF20F: return @"No Financial Card";
                case 0xF210: return @"In Encrypt Result state, TLV total Length is greater than Max Length";
                case 0xF211: return @"ICC L2 is not in idle state.";
                case 0xF212: return @"Transaction Type Error.";
                case 0xF213: return @"Major Config Error for Set Terminal Data.";


                case 0x1001: return @"INVALID ARG";
                case 0x1002: return @"FILE_OPEN_FAILED";
                case 0x1003: return @"FILE OPERATION_FAILED";
                case 0x2001: return @"MEMORY_NOT_ENOUGH";
                case 0x3002: return @"SMARTCARD_FAIL";
                case 0x3003: return @"SMARTCARD_INIT_FAILED";
                case 0x3004: return @"FALLBACK_SITUATION";
                case 0x3005: return @"SMARTCARD_ABSENT";
                case 0x3006: return @"SMARTCARD_TIMEOUT";
                case 0x5001: return @"EMV_PARSING_TAGS_FAILED";
                case 0x5002: return @"EMV_DUPLICATE_CARD_DATA_ELEMENT";
                case 0x5003: return @"EMV_DATA_FORMAT_INCORRECT";
                case 0x5004: return @"EMV_NO_TERM_APP";
                case 0x5005: return @"EMV_NO_MATCHING_APP";
                case 0x5006: return @"EMV_MISSING_MANDATORY_OBJECT";
                case 0x5007: return @"EMV_APP_SELECTION_RETRY";
                case 0x5008: return @"EMV_GET_AMOUNT_ERROR";
                case 0x5009: return @"EMV_CARD_REJECTED";
                case 0x5010: return @"EMV_AIP_NOT_RECEIVED";
                case 0x5011: return @"EMV_AFL_NOT_RECEIVED";
                case 0x5012: return @"EMV_AFL_LEN_OUT_OF_RANGE";
                case 0x5013: return @"EMV_SFI_OUT_OF_RANGE";
                case 0x5014: return @"EMV_AFL_INCORRECT";
                case 0x5015: return @"EMV_EXP_DATE_INCORRECT";
                case 0x5016: return @"EMV_EFF_DATE_INCORRECT";
                case 0x5017: return @"EMV_ISS_COD_TBL_OUT_OF_RANGE";
                case 0x5018: return @"EMV_CRYPTOGRAM_TYPE_INCORRECT";
                case 0x5019: return @"EMV_PSE_NOT_SUPPORTED_BY_CARD";
                case 0x5020: return @"EMV_USER_SELECTED_LANGUAGE";
                case 0x5021: return @"EMV_SERVICE_NOT_ALLOWED";
                case 0x5022: return @"EMV_NO_TAG_FOUND";
                case 0x5023: return @"EMV_CARD_BLOCKED";
                case 0x5024: return @"EMV_LEN_INCORRECT";
                case 0x5025: return @"CARD_COM_ERROR";
                case 0x5026: return @"EMV_TSC_NOT_INCREASED";
                case 0x5027: return @"EMV_HASH_INCORRECT";
                case 0x5028: return @"EMV_NO_ARC";
                case 0x5029: return @"EMV_INVALID_ARC";
                case 0x5030: return @"If EMV transaction, terminated because no online comm. Otherwise Firmware error Timeout Workstate 1";
                case 0x5031: return @"If EMV transaction, terminated because trans type incorrect. Otherwise Firmware error Timeout Workstate 2";
                case 0x5032: return @"If EMV transaction, terminated because no app support. Otherwise Firmware Data Error";
                case 0x5034: return @"If EMV transaction, terminated because Language not selected. Otherwise Firmware error Application Version Error";
                case 0x5035: return @"If EMV transaction, terminated because Terminal Data Missing. Otherwise Firmware Flash Error";
                case 0x5036: return @"IF EMV transaction, terminated because Blocked AID encountered. Otherwise Firmware Check value error";
                case 0x5037: return @"RETURN_CODE_FW_DEVICE_NAME_ERROR";
                case 0x5038: return @"RETURN_CODE_FW_ENCRYPTION_MODE_ERROR";
                case 0x5039: return @"RETURN_CODE_FW_FIRMWARE_ADDRESS_ERROR";
                case 0x6001: return @"CVM_TYPE_UNKNOWN";
                case 0x6002: return @"CVM_AIP_NOT_SUPPORTED";
                case 0x6003: return @"CVM_TAG_8E_MISSING";
                case 0x6004: return @"CVM_TAG_8E_FORMAT_ERROR";
                case 0x6005: return @"CVM_CODE_IS_NOT_SUPPORTED";
                case 0x6006: return @"CVM_COND_CODE_IS_NOT_SUPPORTED";
                case 0x6007: return @"NO_MORE_CVM";
                case 0x6008: return @"PIN_BYPASSED_BEFORE";
                case 0x7001: return @"PK_BUFFER_SIZE_TOO_BIG";
                case 0x7002: return @"PK_FILE_WRITE_ERROR";
                case 0x7003: return @"PK_HASH_ERROR";
                //TTK SELF-CHECK
                case 0x7500: return @"FW Self-Test Failed(De - active Device)";
                case 0x7501: return @"TTK Self -Test – No MTK Key or No Key";
                case 0x7502: return @"TTK Self -Test – MTK Key Stop or Key Stop";
                case 0x7503: return @"TTK Self -Test – No EMV L2 Configuration Data";
                case 0x7504: return @"TTK Self -Test – EMV L2 Configuration Check Value Failed (De - active Device)";
                case 0x7505: return @"TTK Self -Test – Future Key Check Value Failed(De - active Device)";
                case 0x7506: return @"TTK Self -Test – MTK Key Update Error";
                case 0x7510: return @"TTK Self-Test – MTK Key manage error";
                case 0x7511: return @"TTK Self-Test – No EMV L2 Configuration Data – Terminal Data";
                case 0x7512: return @"TTK Self-Test – No EMV L2 Configuration Data – Application Data";
                case 0x7513: return @"TTK Self-Test – No EMV L2 Configuration Data – CA Public Key";
                case 0x7514: return @"TTK Self-Test – No EMV L2 Configuration Data – CRL";
                case 0x7515: return @"TTK Self-Test – Error EMV L2 Configuration Data";
                case 0x7516: return @"TTK Self-Test – Future Key Check Value Failed(De - active Device)";

                case 0x7FF0: return @"Server returned a HTTP error condition on Authorize";
                case 0x7FF1: return @"Server returned a HTTP error condition on Step 1";
                case 0x7FF2: return @"Server returned a HTTP error condition on Step 2";
                case 0x7FF3: return @"Server returned a HTTP error condition on Step 3";
                case 0x8001: return @"Authorization: Cannot initialize RKI; no customer/ key information found";
                case 0x8101: return @"Step 1: No key injection established";
                case 0x8102: return @"Step 1: Failed to encrypt challenge";
                case 0x8103: return @"Step 1: challenge length is incorrect";
                case 0x8104: return @"Step 1: Incorrect challenge data";
                case 0x8105: return @"Step 1: Response length incorrect";
                case 0x8106: return @"Step 1: Firmware responded NAK for Step 1";
                case 0x8107: return @"Step 1: Admin key not found fdor Step 1";
                case 0x8201: return @"Step 2: Customer key id could not be found in the DB";
                case 0x8202: return @"Step 2: Key Slot does not exist";
                case 0x8203: return @"Step 2: Could not get the future KSI from the server";
                case 0x8204: return @"Step 2: Could not get TR31 data block";
                case 0x8205: return @"Step 2: TR31 block length is incorrect";
                case 0x8206: return @"Step 2: Incorrect challenge data";
                case 0x8207: return @"Step 2: Firmware responded NAK for Step 2";
                case 0x8301: return @"Step 3: No key injection record found";
                case 0x8302: return @"Step 3: Remote Key Injection failed(NAK)";
                case 0x8303: return @"Step 3: Incorrect response form";
                case 0x8304: return @"Step 3: Firmware responded NAK for Step 3";

                case 0x8002: return @"GET_ONLINE_PIN";
                case 0xD000: return @"Data not exist";
                case 0xD001: return @"Data access error";
                case 0xD100: return @"RID not exist";
                case 0xD101: return @"RID existed";
                case 0xD102: return @"Index not exist";
                case 0xD200: return @"Maximum exceeded";
                case 0xD201: return @"Hash error";
                case 0xD205: return @"System Busy";
                case 0x0E01: return @"Unable to go online";
                case 0x0E02: return @"Technical Issue";
                case 0x0E03: return @"Declined";
                case 0x0E04: return @"Issuer Referral transaction";
                case 0x0F01: return @"Decline the online transaction";
                case 0x0F02: return @"Request to go online";
                case 0x0F03: return @"Transaction is terminated";
                case 0x0F05: return @"Application was not selected by kernel or ICC format error or ICC missing data error";
                case 0x0F07: return @"ICC didn't accept transaction";
                case 0x0F0A: return @"Application may fallback to magstripe technology";
                case 0x0F0C: return @"Transaction was cancelled";
                case 0x0F0D: return @"Timeout";
                case 0x0F0F: return @"Other EMV Error";
                case 0x0F10: return @"Accept the offline transaction";
                case 0x0F11: return @"Decline the offline transaction";
                case 0x0F21: return @"ICC detected tah the conditions of use are not satisfied";
                case 0x0F22: return @"No app were found on card matching terminal configuration";
                case 0x0F23: return @"Terminal file does not exist";
                case 0x0F24: return @"CAPK file does not exist";
                case 0x0F25: return @"CRL Entry does not exist";
                case 0x0FFE: return @"Return code when blocking is disabled";
                case 0x0FFF: return @"Return code when command is not applicable on the selected device";
                case 0xBBE0: return @"CM100 Success";
                case 0xBBE1: return @"CM100 Parameter Error";
                case 0xBBE2: return @"CM100 Low Output Buffer";
                case 0xBBE3: return @"CM100 Card Not Found";
                case 0xBBE4: return @"CM100 Collision Card Exists";
                case 0xBBE5: return @"CM100 Too Many Cards Exist";
                case 0xBBE6: return @"CM100 Saved Data Does Not Exist";
                case 0xBBE8: return @"CM100 No Data Available";
                case 0xBBE9: return @"CM100 Invalid CID Returned";
                case 0xBBEA: return @"CM100 Invalid Card Exists";
                case 0xBBEC: return @"CM100 Command Unsupported";
                case 0xBBED: return @"CM100 Error In Command Process";
                case 0xBBEE: return @"CM100 Invalid Command";

                case 0X9031: return @"Unknown command";
                case 0X9032: return @"Wrong parameter (such as the length of the command is incorrect)";

                case 0X9038: return @"Wait (the command couldn’t be finished in BWT)";
                case 0X9039: return @"Busy (a previously command has not been finished)";
                case 0X903A: return @"Number of retries over limit";

                case 0X9040: return @"Invalid Manufacturing system data";
                case 0X9041: return @"Not authenticated";
                case 0X9042: return @"Invalid Master DUKPT Key";
                case 0X9043: return @"Invalid MAC Key";
                case 0X9044: return @"Reserved for future use";
                case 0X9045: return @"Reserved for future use";
                case 0X9046: return @"Invalid DATA DUKPT Key";
                case 0X9047: return @"Invalid PIN Pairing DUKPT Key";
                case 0X9048: return @"Invalid DATA Pairing DUKPT Key";
                case 0X9049: return @"No nonce generated";
                case 0X9949: return @"No GUID available.  Perform getVersion first.";
                case 0X9950: return @"MAC Calculation unsuccessful. Check BDK value.";

                case 0X904A: return @"Not ready";
                case 0X904B: return @"not MAC Data";

                case 0X9050: return @"Invalid Certificate";
                case 0X9051: return @"Duplicate key detected";
                case 0X9052: return @"AT checks failed";
                case 0X9053: return @"TR34 checks failed";
                case 0X9054: return @"TR31 checks failed";
                case 0X9055: return @"MAC checks failed";
                case 0X9056: return @"Firmware download failed";
                case 0X9057: return @"LCL - KEK exists";
                case 0X9060: return @"Log is full";
                case 0X9061: return @"Removal sensor unengaged";
                case 0X9062: return @"Any hardware problems";

                case 0X9070: return @"ICC communication timeout";
                case 0X9071: return @"ICC data error (such check sum error)";
                case 0X9072: return @"Smart Card not powered up";

                case 0xF200: return @"No AID or No Application Data";
                case 0xF201: return @"No Terminal Data";
                case 0xF202: return @"Wrong TLV format";
                case 0xF203: return @"AID list is full, maxim is 16";
                case 0xF204: return @"No any CA Key";
                case 0xF205: return @"No CA Key  RID";
                case 0xF206: return @"No CA Key  Index";
                case 0xF207: return @"CA Key  list is full, maxim is 96";
                case 0xF208: return @"Wrong CA Key hash";
                case 0xF209: return @"Wrong Transaction Command Format";
                case 0xF20A: return @"Unexpected Command";
                case 0xF20B: return @"No CRL";
                case 0xF20C: return @"CRL list is full, maxim is 30";
                case 0xF20D: return @"No amount, other amount and transaction type in Transaction Command";
                case 0xF20E: return @"Wrong CA Hash and Encryption algorithm";
                case 0X1C01: return @"RKI could not retrieve device serial number";
                case 0X1C02: return @"RKI could not retrieve device firmware version";
                case 0X1C03: return @"RKI failed on Step 1: Authenticate a RKI with Server";
                case 0X1C04: return @"RKI failed on Step 2: Initiate  RKI with Server";
                case 0X1C05: return @"RKI failed on Step 3: Request Key Pair";

                case 0x2400: return @"Cannot retrieve device serial number in RKI update";
                case 0x2401:
                    return @"Cannot retrieve device certificates in RKI update";
                case 0x2402:
                    return @"Starting RKI Update Process";
                case 0x2403:
                    return @"Cannot retrieve key device group in RKI update";
                case 0x2404:
                    return @"PEDI Command failed in RKI Update";
                case 0x2405:
                    return @"Invalid RSA Signature in RKI Update";
                case 0x2406:
                    return @"PEDK Command failed in RKI Update";
                case 0x2407:
                    return @"PEDK Command failed setting keys in RKI Update";
                case 0x2408:
                    return @"PEDV Command failed in RKI Update";
                case 0x2409:
                    return @"PEDV Command failed verifying keys in RKI Update";
                case 0x240A:
                    return @"Completed RKI Update Process";
                case 0x240B:
                    return @"Completed RKI Update Process. More keys available.";
                case 0x240C:
                    return @"Error ending secure task.";
                case 0x240D:
                    return @"Unknown Failure.";
                case 0x240E:
                    return @"Failed on device key request, symmetric RKI.";
                case 0x240F:
                    return @"Failed to get keys from the server, symmetric RKI.";
                case 0x2410:
                    return @"Failed on device to set key, symmetric RKI.";
                case 0x2411:
                    return @"Failed to validate key with server, symmetric RKI.";
                case 0x2412:
                    return @"Error starting secure task.";



            }
            return @"";
        }

    }


@end
