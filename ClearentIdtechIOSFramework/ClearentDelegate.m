//
//  ClearentDelegate.m
//  ClearentPayments
//
//  Created by David Higginbotham on 1/5/18.
//  Copyright © 2018 Clearent, L.L.C. All rights reserved.
//

#import "ClearentDelegate.h"
#import "IDTech/IDTUtility.h"

static NSString *const TRACK2_DATA_EMV_TAG = @"57";
static NSString *const TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG = @"9F6B";
static NSString *const TAC_DEFAULT = @"DF13";
static NSString *const TAC_DENIAL = @"DF14";
static NSString *const TAC_ONLINE = @"DF15";

static NSString *const IDTECH_EMV_ENTRY_MODE_EMV_TAG = @"DFEE17";
static NSString *const EMV_DIP_ENTRY_MODE_TAG = @"05";
static NSString *const DEVICE_SERIAL_NUMBER_EMV_TAG = @"DF78";
static NSString *const KERNEL_VERSION_EMV_TAG = @"DF79";
static NSString *const GENERIC_CARD_READ_ERROR_RESPONSE = @"Card read error";
static NSString *const GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE = @"Create Transaction Token Failed";

@implementation ClearentDelegate

- (void) init : (id <Clearent_Public_IDTech_VP3300_Delegate>) publicDelegate {
    self.publicDelegate = publicDelegate;
    NSLog(@"ClearentDelegate initialized");
}

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines {
    [self.publicDelegate lcdDisplay:(int)mode  lines:(NSArray*)lines];
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming {
    NSLog(@"dataInOutMonitor: %@", data);
    [self.publicDelegate dataInOutMonitor:data incoming:isIncoming];
}

- (void) plugStatusChange:(BOOL)deviceInserted {
    [self.publicDelegate plugStatusChange:(BOOL)deviceInserted];
}

-(void)deviceConnected {
    [self initClock];
    [self configuration];
    [self loadCAPK];
    [self.publicDelegate deviceConnected];
}

//TODO expose this allowing the developer to configure based on region
- (void) initClock {
    [self initClockDate];
    [self initClockTime];
}

- (void) initClockDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSData *clockDate = [IDTUtility hexToData:dateString];
    NSData *result;
    RETURN_CODE dateRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x25 subCommand:0x03 data:clockDate response:&result];
    if (RETURN_CODE_DO_SUCCESS == dateRt) {
        NSLog(@"Clock Date Initialized");
    } else {
        NSString *errorResult = [[IDT_VP3300 sharedController] device_getResponseCodeString:dateRt];
        NSLog(@"Failed to configure real time clock date: %@",errorResult);
    }
}

- (void) initClockTime {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HHMM";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    NSData *timeDate = [IDTUtility hexToData:timeString];
    NSData *result;
    RETURN_CODE timeRt = [[IDT_VP3300 sharedController] device_sendIDGCommand:0x25 subCommand:0x01 data:timeDate response:&result];
    if (RETURN_CODE_DO_SUCCESS == timeRt) {
        NSLog(@"Clock Time Initialized");
    }
}
- (void) configuration {
    self.firmwareVersion= [self getFirmwareVersion];
    self.deviceSerialNumber = [self getDeviceSerialNumber];
    self.kernelVersion = [self getKernelVersion];
    NSMutableDictionary *tags;
    
    //set the 9f35 terminal type
    [[IDT_VP3300 sharedController] emv_setTerminalMajorConfiguration:5];
    
    RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_retrieveTerminalData:&tags];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        //TODO MOVE THE MAJOR AND MINOR TAGS BACK HERE ANDSEE IF EVERYTHING STILL WORKS
        //idtech custom tags should be configured upfront.
        [tags setObject:@"D0DC20D0C41E1400" forKey:@"DFEE1E"];
        //TODO expose a method the developer can pass in a json file to set application ids
        //Set emv entry mode
        [tags setObject:EMV_DIP_ENTRY_MODE_TAG forKey:IDTECH_EMV_ENTRY_MODE_EMV_TAG];
    } else{
        [self deviceMessage:@"Failed to preconfigure required EMV tags"];
    }
    [[IDT_VP3300 sharedController] emv_setTerminalData:tags];
    
    //Clear out any preexisting emv AID configurations
    
    NSArray *arrayOfPreconfiguredEmvAids;
    RETURN_CODE arrayOfPreconfiguredEmvAidsRt = [[IDT_VP3300 sharedController] emv_retrieveAIDList:&arrayOfPreconfiguredEmvAids];
    for(NSString* aidname in arrayOfPreconfiguredEmvAids) {
        // NOT NEEDED?       RETURN_CODE removeAidNameRt = [[IDT_VP3300 sharedController] emv_removeApplicationData:aidname];
        NSLog(@"preconfigured contact configuration for name: %@",aidname);
    }
    
    //jcb aid configuration
    NSDictionary* jcbAids = @{
                              @"9F15":@"5999",
                              @"9F06":@"A0000000651010",
                              @"9F1A":@"0840",
                              @"5F2A":@"0840",
                              @"5F36":@"02",
                              @"DF25":@"9F3704",
                              //df13 tac default
                              @"DF13":@"FC60242800",
                              //df14 tac denial
                              @"DF14":@"0010000000",
                              //df15 tac online
                              @"DF15":@"30E09CF800",
                              @"9F1B":@"00000000",
                              @"DF17":@"00000000",
                              @"DF19":@"99",
                              @"DF18":@"99",
                              @"DFEE15":@"01",
                              @"9F09":@"120"
                              };
    
    NSString* jcbAidName = @"a0000000651010";
    RETURN_CODE jcbAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:jcbAidName configData:jcbAids];
    if (RETURN_CODE_DO_SUCCESS == jcbAidsRt)
    {
        NSLog(@"JCB Aids configured");
    }
    else{
        NSLog(@"JCB Aids not configured");
    }
    
    
    //amex aid configuration
    NSDictionary* amexAids = @{
                               @"9F15":@"5999",
                               @"9F06":@"A00000002501",
                               @"9F1A":@"0840",
                               @"5F2A":@"0840",
                               @"5F36":@"02",
                               @"DF25":@"9F3704",
                               //df13 tac default
                               @"DF13":@"1000002000",
                               //df14 tac denial
                               @"DF14":@"0010000000",
                               //df15 tac online
                               @"DF15":@"30E09CF800",
                               @"9F1B":@"00000000",
                               @"DF17":@"00000000",
                               @"DF19":@"99",
                               @"DF18":@"99",
                               @"DFEE15":@"01",
                               @"9F09":@"0001"
                               };
    
    NSString* amexAidName = @"a00000002501";
    RETURN_CODE amexAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:amexAidName configData:amexAids];
    if (RETURN_CODE_DO_SUCCESS == amexAidsRt)
    {
        NSLog(@"Amex Aids configured");
    }
    else{
        NSLog(@"Amex Aids not configured");
    }
    
    
    //discover aid configuration
    NSDictionary* discoverAids = @{
                                   @"9F15":@"5999",
                                   @"9F06":@"A0000001523010",
                                   @"9F1A":@"0840",
                                   @"5F2A":@"0840",
                                   @"5F36":@"02",
                                   @"DF25":@"9F3704",
                                   //df13 tac default
                                   @"DF13":@"1000002000",
                                   //df14 tac denial
                                   @"DF14":@"0010000000",
                                   //df15 tac online
                                   @"DF15":@"30E09CF800",
                                   @"9F1B":@"00000000",
                                   @"DF17":@"00000000",
                                   @"DF19":@"99",
                                   @"DF18":@"99",
                                   @"DFEE15":@"01",
                                   @"9F09":@"0001"
                                   };
    
    NSString* discoverAidName = @"a0000001523010";
    RETURN_CODE discoverAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:discoverAidName configData:discoverAids];
    if (RETURN_CODE_DO_SUCCESS == discoverAidsRt)
    {
        NSLog(@"Discover Aids configured");
    }
    else{
        NSLog(@"Discover Aids not configured");
    }
    
    //mastercard aid configuration
    NSDictionary* mastercardAids = @{
                                     @"9F15":@"5999",
                                     //@"9F53":@"R",
                                     @"9F06":@"A0000000041010",
                                     @"9F1A":@"0840",
                                     @"5F2A":@"0840",
                                     @"5F36":@"02",
                                     @"DF25":@"9F3704",
                                     //df13 tac default
                                     @"DF13":@"FE50808000",
                                     //df14 tac denial
                                     @"DF14":@"0000000000",
                                     //df15 tac online
                                     @"DF15":@"FE50808000",
                                     @"9F1B":@"00000000",
                                     @"DF17":@"00000000",
                                     @"DF19":@"99",
                                     @"DF18":@"99",
                                     @"DFEE15":@"01",
                                     @"9F09":@"0002"
                                     };
    
    
    NSString* mastercardAidsName = @"a0000000041010";
    RETURN_CODE mastercardAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:mastercardAidsName configData:mastercardAids];
    if (RETURN_CODE_DO_SUCCESS == mastercardAidsRt)
    {
        NSLog(@"Mastercard Aids configured");
    }
    else{
        NSLog(@"Mastercard Aids not configured");
    }
    
    //mastercard contactless aid configuration
    //    NSDictionary* mastercardContactlessAids = @{
    //                       @"9F15":@"5999",
    //                       @"9F06":@"A0000000041010",
    //                       @"9F1A":@"0840",
    //                       @"5F2A":@"0840",
    //                       @"5F36":@"02",
    //                       @"DF25":@"9F3704",
    //                       //df13 tac default
    //                       @"DF13":@"F45084800C",
    //                       //df14 tac denial
    //                       @"DF14":@"0000000000",
    //                       //df15 tac online
    //                       @"DF15":@"F45084800C",
    //                       @"9F1B":@"00000000",
    //                       @"DF17":@"00000000",
    //                       @"DF19":@"99",
    //                       @"DF18":@"99",
    //                       @"DFEE15":@"01",
    //                       @"9F09":@"0002"
    //                       };
    //
    
    
    
    //    NSData *mastercardContactlessData = [IDTUtility DICTotTLV:mastercardContactlessAids];
    //RETURN_CODE removeMastercardContactlessAidsRt = [[IDT_VP3300 sharedController] ctls_removeApplicationData:@"A0000000041010"];
    
    //RETURN_CODE mastercardContactlessAidsRt = [[IDT_VP3300 sharedController] ctls_setApplicationData:mastercardContactlessData];
    //if (RETURN_CODE_DO_SUCCESS == mastercardContactlessAidsRt)
    //{
    //    NSLog(@"Mastercard Contactless Aids configured");
    //}
    //else{
    //    NSLog(@"Mastercard Contactless Aids not configured");
    //}
    
    //visa aid configuration
    NSDictionary* visaAids = @{
                               @"9F15":@"5999",
                               @"9F06":@"A0000000031010",
                               @"9F1A":@"0840",
                               @"5F2A":@"0840",
                               @"5F36":@"02",
                               @"DF25":@"9F3704",
                               @"DF13":@"584000A800",
                               @"DF14":@"0010000000",
                               @"DF15":@"584004F800",
                               @"9F1B":@"00000000",
                               @"DF17":@"00000000",
                               @"DF19":@"99",
                               @"DF18":@"99",
                               @"DFEE15":@"01",
                               @"9F09":@"00A0",
                               @"9F09":@"0096"
                               };
    
    NSString* visaAidsName = @"a0000000031010";
    RETURN_CODE visaAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:visaAidsName configData:visaAids];
    if (RETURN_CODE_DO_SUCCESS == visaAidsRt)
    {
        NSLog(@"Visa Aids configured");
    }
    else{
        NSLog(@"Visa Aids not configured");
    }
    
    //visa electron aid configuration
    NSDictionary* visaElectronAids = @{
                                       @"9F15":@"5999",
                                       @"9F06":@"A0000000031010",
                                       @"9F1A":@"0840",
                                       @"5F2A":@"0840",
                                       @"5F36":@"02",
                                       @"DF25":@"9F3704",
                                       @"DF13":@"584000A800",
                                       @"DF14":@"0010000000",
                                       @"DF15":@"584004F800",
                                       @"9F1B":@"00000000",
                                       @"DF17":@"00000000",
                                       @"DF19":@"99",
                                       @"DF18":@"99",
                                       @"DFEE15":@"01",
                                       @"9F09":@"00A0",
                                       @"9F09":@"0096"
                                       };
    
    NSString* visaElectronAidsName = @"a0000000032010";
    RETURN_CODE visaElectronAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:visaElectronAidsName configData:visaElectronAids];
    if (RETURN_CODE_DO_SUCCESS == visaElectronAidsRt)
    {
        NSLog(@"Visa Electron Aids configured");
    }
    else{
        NSLog(@"Visa Electron Aids not configured");
    }
    
    //union pay credit aid configuration
    NSDictionary* unionPayCreditAids = @{
                                         @"9F15":@"5999",
                                         @"9F06":@"A000000333010102",
                                         @"9F1A":@"0840",
                                         @"5F2A":@"0840",
                                         @"5F36":@"02",
                                         @"DF25":@"9F3704",
                                         //df13 tac default
                                         @"DF13":@"D84004F800",
                                         //df14 tac denial
                                         @"DF14":@"0010000000",
                                         //df15 tac online
                                         @"DF15":@"D84004F800",
                                         @"9F1B":@"00000000",
                                         @"DF17":@"00000000",
                                         @"DF19":@"99",
                                         @"DF18":@"99",
                                         @"DFEE15":@"01"
                                         };
    
    NSString* unionPayCreditAidsName = @"a000000333010102";
    RETURN_CODE unionPayCreditAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:unionPayCreditAidsName configData:unionPayCreditAids];
    if (RETURN_CODE_DO_SUCCESS == unionPayCreditAidsRt)
    {
        NSLog(@"Union Pay credit Aids configured");
    }
    else{
        NSLog(@"Union Pay credit Aids not configured");
    }
    
    //union pay quasi credit aid configuration
    NSDictionary* unionPayQuasiCreditAids = @{
                                              @"9F15":@"5999",
                                              @"9F06":@"A000000333010103",
                                              @"9F1A":@"0840",
                                              @"5F2A":@"0840",
                                              @"5F36":@"02",
                                              @"DF25":@"9F3704",
                                              //df13 tac default
                                              @"DF13":@"D84004F800",
                                              //df14 tac denial
                                              @"DF14":@"0010000000",
                                              //df15 tac online
                                              @"DF15":@"D84004F800",
                                              @"9F1B":@"00000000",
                                              @"DF17":@"00000000",
                                              @"DF19":@"99",
                                              @"DF18":@"99",
                                              @"DFEE15":@"01"
                                              };
    
    NSString* unionPayQuasiCreditAidsName = @"a000000333010103";
    RETURN_CODE unionPayQuasiCreditAidsRt = [[IDT_VP3300 sharedController] emv_setApplicationData:unionPayQuasiCreditAidsName configData:unionPayQuasiCreditAids];
    if (RETURN_CODE_DO_SUCCESS == unionPayQuasiCreditAidsRt)
    {
        NSLog(@"Union Pay Quasi Credit Aids configured");
    }
    else{
        NSLog(@"Union Pay Quasi Credit Aids not configured");
    }
    
}

- (void) loadCAPK {
    [self loadVisaPublic1152TestKey];
    [self loadVisaPublic1408TestKey];
    [self loadVisaPublic1984TestKey];
    [self loadVisaPublic1024TestKey];
    
    [self loadMastercardPublic1152TestKey];
    [self loadMasterPublic1408TestKey];
    [self loadMastercardPublic1984TestKey];
    
    [self loadAmexPublic1408TestKey];
    [self loadAmexPublic1984TestKey];
    
    [self loadJcbPublic1024TestKey];
    [self loadJcbPublic1152TestKey];
    [self loadJcbPublic1408TestKey];
    
    // [self loadDiscoverPublicXXXXTestKey];
    [self loadDiscoverPublic1152TestKey];
    [self loadDiscoverPublic1408TestKey];
}

//- (void) loadDiscoverPublicXXXXTestKey {
//    //[5 bytes RID]
//    NSString *rid = @"A000000152";
//    //[1 byte Index]
//    NSString *key_index = @"5A";
//    //[1 byte Hash Algorithm]
//    NSString *hashAlgorithm = @"01";
//    //[1 byte Encryption Algorithm]
//    NSString *encryption_Algorithm = @"01";
//    //[20 bytes HashValue]
//    NSString *hashValue = @"95F4D045422D0920D04E9614B714D936DEA1AACA";
//    //[4 bytes Public Key Exponent]
//    NSString *publicKey_Exponent = @"00000003";
//    //[Variable bytes Modulus]
//    NSString *modulus = @"EDD8252468A705614B4D07DE3211B30031AEDB6D33A4315F2CFF7C97DB918993C2DC02E79E2FF8A2683D5BBD0F614BC9AB360A448283EF8B9CF6731D71D6BE939B7C5D0B0452D660CF24C21C47CAC8E26948C8EED8E3D00C016828D642816E658DC2CFC61E7E7D7740633BEFE34107C1FB55DEA7FAAEA2B25E85BED948893D07";
//
//    NSUInteger modLength = modulus.length / 2;
//    long actlength = (unsigned long) modLength;
//
//    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"8000",modulus, nil];
//
//    NSString* combined = [testKeyArray componentsJoinedByString:@""];
//
//    NSData* capk = [IDTUtility hexToData:combined];
//    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
//    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
//        NSLog(@"loadDiscoverPublicXXXXTestKey loaded");
//    } else{
//        NSLog(@"loadDiscoverPublicXXXXTestKey failed to load");
//    }
//}

- (void) loadDiscoverPublic1152TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000152";
    //[1 byte Index]
    NSString *key_index = @"5B";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"4DC5C6CAB6AE96974D9DC8B2435E21F526BC7A60";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"D3F45D065D4D900F68B2129AFA38F549AB9AE4619E5545814E468F382049A0B9776620DA60D62537F0705A2C926DBEAD4CA7CB43F0F0DD809584E9F7EFBDA3778747BC9E25C5606526FAB5E491646D4DD28278691C25956C8FED5E452F2442E25EDC6B0C1AA4B2E9EC4AD9B25A1B836295B823EDDC5EB6E1E0A3F41B28DB8C3B7E3E9B5979CD7E079EF024095A1D19DD";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"9000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadDiscoverPublic1024TestKey loaded");
    } else{
        NSLog(@"loadDiscoverPublic1024TestKey failed to load");
    }
}


- (void) loadDiscoverPublic1408TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000152";
    //[1 byte Index]
    NSString *key_index = @"5C";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"60154098CBBA350F5F486CA31083D1FC474E31F8";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"833F275FCF5CA4CB6F1BF880E54DCFEB721A316692CAFEB28B698CAECAFA2B2D2AD8517B1EFB59DDEFC39F9C3B33DDEE40E7A63C03E90A4DD261BC0F28B42EA6E7A1F307178E2D63FA1649155C3A5F926B4C7D7C258BCA98EF90C7F4117C205E8E32C45D10E3D494059D2F2933891B979CE4A831B301B0550CDAE9B67064B31D8B481B85A5B046BE8FFA7BDB58DC0D7032525297F26FF619AF7F15BCEC0C92BCDCBC4FB207D115AA65CD04C1CF982191";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"B000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadDiscoverPublic1024TestKey loaded");
    } else{
        NSLog(@"loadDiscoverPublic1024TestKey failed to load");
    }
}

- (void) loadJcbPublic1024TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000065";
    //[1 byte Index]
    NSString *key_index = @"08";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"DD36D5896228C8C4900742F107E2F91FE50BC7EE";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"B74670DAD1DC8983652000E5A7F2F8B35DFD083EE593E5BA895C95729F2BADE9C8ABF3DD9CE240C451C6CEFFC768D83CBAC76ABB8FEA58F013C647007CFF7617BAC2AE3981816F25CC7E5238EF34C4F02D0B01C24F80C2C65E7E7743A4FA8E23206A23ECE290C26EA56DB085C5C5EAE26292451FC8292F9957BE8FF20FAD53E5";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"8000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadJcbPublic1024TestKey loaded");
    } else{
        NSLog(@"loadJcbPublic1024TestKey failed to load");
    }
}


- (void) loadJcbPublic1152TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000065";
    //[1 byte Index]
    NSString *key_index = @"0F";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"2A1B82DE00F5F0C401760ADF528228D3EDE0F403";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"9EFBADDE4071D4EF98C969EB32AF854864602E515D6501FDE576B310964A4F7C2CE842ABEFAFC5DC9E26A619BCF2614FE07375B9249BEFA09CFEE70232E75FFD647571280C76FFCA87511AD255B98A6B577591AF01D003BD6BF7E1FCE4DFD20D0D0297ED5ECA25DE261F37EFE9E175FB5F12D2503D8CFB060A63138511FE0E125CF3A643AFD7D66DCF9682BD246DDEA1";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"9000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadJcbPublic1152TestKey loaded");
    } else{
        NSLog(@"loadJcbPublic1152TestKey failed to load");
    }
}

- (void) loadJcbPublic1408TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000065";
    //[1 byte Index
    NSString *key_index = @"11";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"D9FD62C9DD4E6DE7741E9A17FB1FF2C5DB948BCB";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"A2583AA40746E3A63C22478F576D1EFC5FB046135A6FC739E82B55035F71B09BEB566EDB9968DD649B94B6DEDC033899884E908C27BE1CD291E5436F762553297763DAA3B890D778C0F01E3344CECDFB3BA70D7E055B8C760D0179A403D6B55F2B3B083912B183ADB7927441BED3395A199EEFE0DEBD1F5FC3264033DA856F4A8B93916885BD42F9C1F456AAB8CFA83AC574833EB5E87BB9D4C006A4B5346BD9E17E139AB6552D9C58BC041195336485";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"B000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadJcbPublic1408TestKey loaded");
    } else{
        NSLog(@"loadJcbPublic1408TestKey failed to load");
    }
}


- (void) loadVisaPublic1152TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000003";
    //[1 byte Index]
    NSString *key_index = @"95";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"EE1511CEC71020A9B90443B37B1D5F6E703030F6";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"BE9E1FA5E9A803852999C4AB432DB28600DCD9DAB76DFAAA47355A0FE37B1508AC6BF38860D3C6C2E5B12A3CAAF2A7005A7241EBAA7771112C74CF9A0634652FBCA0E5980C54A64761EA101A114E0F0B5572ADD57D010B7C9C887E104CA4EE1272DA66D997B9A90B5A6D624AB6C57E73C8F919000EB5F684898EF8C3DBEFB330C62660BED88EA78E909AFF05F6DA627B";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"9000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadVisaPublic1152TestKey loaded");
    } else{
        NSLog(@"loadVisaPublic1152TestKey failed to load");
    }
}

- (void) loadVisaPublic1408TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000003";
    //[1 byte Index]
    NSString *key_index = @"92";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"429C954A3859CEF91295F663C963E582ED6EB253";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"996AF56F569187D09293C14810450ED8EE3357397B18A2458EFAA92DA3B6DF6514EC060195318FD43BE9B8F0CC669E3F844057CBDDF8BDA191BB64473BC8DC9A730DB8F6B4EDE3924186FFD9B8C7735789C23A36BA0B8AF65372EB57EA5D89E7D14E9C7B6B557460F10885DA16AC923F15AF3758F0F03EBD3C5C2C949CBA306DB44E6A2C076C5F67E281D7EF56785DC4D75945E491F01918800A9E2DC66F60080566CE0DAF8D17EAD46AD8E30A247C9F";
    
    //TODO We'll need logic to provide the correct modulus length. currently calculated ex B000
    //emv_setCAPKFile order of capk string
    //    [5 bytes RID]
    //    [1 byte Index]
    //    [1 byte Hash Algorithm]
    //    [1 byte Encryption Algorithm]
    //    [20 bytes HashValue]
    //    [4 bytes Public Key Exponent]
    //    [2 bytes Modulus Length]
    //    [Variable bytes Modulus]
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"B000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadVisaPublic1408TestKey loaded");
    } else{
        NSLog(@"loadVisaPublic1408TestKey failed to load");
    }
}

- (void) loadVisaPublic1984TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000003";
    //[1 byte Index]
    NSString *key_index = @"94";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"C4A3C43CCF87327D136B804160E47D43B60E6E0F";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"ACD2B12302EE644F3F835ABD1FC7A6F62CCE48FFEC622AA8EF062BEF6FB8BA8BC68BBF6AB5870EED579BC3973E121303D34841A796D6DCBC41DBF9E52C4609795C0CCF7EE86FA1D5CB041071ED2C51D2202F63F1156C58A92D38BC60BDF424E1776E2BC9648078A03B36FB554375FC53D57C73F5160EA59F3AFC5398EC7B67758D65C9BFF7828B6B82D4BE124A416AB7301914311EA462C19F771F31B3B57336000DFF732D3B83DE07052D730354D297BEC72871DCCF0E193F171ABA27EE464C6A97690943D59BDABB2A27EB71CEEBDAFA1176046478FD62FEC452D5CA393296530AA3F41927ADFE434A2DF2AE3054F8840657A26E0FC617";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"F800",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadVisaPublic1984TestKey loaded");
    } else{
        NSLog(@"loadVisaPublic1984TestKey failed to load");
    }
}

- (void) loadVisaPublic1024TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000003";
    //[1 byte Index]
    NSString *key_index = @"99";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"4ABFFD6B1C51212D05552E431C5B17007D2F5E6D";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"AB79FCC9520896967E776E64444E5DCDD6E13611874F3985722520425295EEA4BD0C2781DE7F31CD3D041F565F747306EED62954B17EDABA3A6C5B85A1DE1BEB9A34141AF38FCF8279C9DEA0D5A6710D08DB4124F041945587E20359BAB47B7575AD94262D4B25F264AF33DEDCF28E09615E937DE32EDC03C54445FE7E382777";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"8000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadVisaPublic1024TestKey loaded");
    } else{
        NSLog(@"loadVisaPublic1024TestKey failed to load");
    }
}

- (void) loadMastercardPublic1152TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000004";
    //[1 byte Index]
    NSString *key_index = @"FA";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"5BED4068D96EA16D2D77E03D6036FC7A160EA99C";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"A90FCD55AA2D5D9963E35ED0F440177699832F49C6BAB15CDAE5794BE93F934D4462D5D12762E48C38BA83D8445DEAA74195A301A102B2F114EADA0D180EE5E7A5C73E0C4E11F67A43DDAB5D55683B1474CC0627F44B8D3088A492FFAADAD4F42422D0E7013536C3C49AD3D0FAE96459B0F6B1B6056538A3D6D44640F94467B108867DEC40FAAECD740C00E2B7A8852D";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"9000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadMastercardPublic1152TestKey loaded");
    } else{
        NSLog(@"loadMastercardPublic1152TestKey failed to load");
    }
}

- (void) loadMasterPublic1408TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000004";
    //[1 byte Index
    NSString *key_index = @"F1";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"D8E68DA167AB5A85D8C3D55ECB9B0517A1A5B4BB";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"A0DCF4BDE19C3546B4B6F0414D174DDE294AABBB828C5A834D73AAE27C99B0B053A90278007239B6459FF0BBCD7B4B9C6C50AC02CE91368DA1BD21AAEADBC65347337D89B68F5C99A09D05BE02DD1F8C5BA20E2F13FB2A27C41D3F85CAD5CF6668E75851EC66EDBF98851FD4E42C44C1D59F5984703B27D5B9F21B8FA0D93279FBBF69E090642909C9EA27F898959541AA6757F5F624104F6E1D3A9532F2A6E51515AEAD1B43B3D7835088A2FAFA7BE7";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"B000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadMastercardPublic1408TestKey loaded");
    } else{
        NSLog(@"loadMastercardPublic1408TestKey failed to load");
    }
}

- (void) loadMastercardPublic1984TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000004";
    //[1 byte Index]
    NSString *key_index = @"EF";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"21766EBB0EE122AFB65D7845B73DB46BAB65427A";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"A191CB87473F29349B5D60A88B3EAEE0973AA6F1A082F358D849FDDFF9C091F899EDA9792CAF09EF28F5D22404B88A2293EEBBC1949C43BEA4D60CFD879A1539544E09E0F09F60F065B2BF2A13ECC705F3D468B9D33AE77AD9D3F19CA40F23DCF5EB7C04DC8F69EBA565B1EBCB4686CD274785530FF6F6E9EE43AA43FDB02CE00DAEC15C7B8FD6A9B394BABA419D3F6DC85E16569BE8E76989688EFEA2DF22FF7D35C043338DEAA982A02B866DE5328519EBBCD6F03CDD686673847F84DB651AB86C28CF1462562C577B853564A290C8556D818531268D25CC98A4CC6A0BDFFFDA2DCCA3A94C998559E307FDDF915006D9A987B07DDAEB3B";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"F800",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadMastercardPublic1984TestKey loaded");
    } else{
        NSLog(@"loadMastercardPublic1984TestKey failed to load");
    }
}

- (void) loadAmexPublic1408TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000025";
    //[1 byte Index
    NSString *key_index = @"C9";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"8E8DFF443D78CD91DE88821D70C98F0638E51E49";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"B362DB5733C15B8797B8ECEE55CB1A371F760E0BEDD3715BB270424FD4EA26062C38C3F4AAA3732A83D36EA8E9602F6683EECC6BAFF63DD2D49014BDE4D6D603CD744206B05B4BAD0C64C63AB3976B5C8CAAF8539549F5921C0B700D5B0F83C4E7E946068BAAAB5463544DB18C63801118F2182EFCC8A1E85E53C2A7AE839A5C6A3CABE73762B70D170AB64AFC6CA482944902611FB0061E09A67ACB77E493D998A0CCF93D81A4F6C0DC6B7DF22E62DB";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"B000",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadAmexPublic1408TestKey loaded");
    } else{
        NSLog(@"loadAmexPublic1408TestKey failed to load");
    }
}

- (void) loadAmexPublic1984TestKey {
    //[5 bytes RID]
    NSString *rid = @"A000000025";
    //[1 byte Index]
    NSString *key_index = @"CA";
    //[1 byte Hash Algorithm]
    NSString *hashAlgorithm = @"01";
    //[1 byte Encryption Algorithm]
    NSString *encryption_Algorithm = @"01";
    //[20 bytes HashValue]
    NSString *hashValue = @"6BDA32B1AA171444C7E8F88075A74FBFE845765F";
    //[4 bytes Public Key Exponent]
    NSString *publicKey_Exponent = @"00000003";
    //[Variable bytes Modulus]
    NSString *modulus = @"C23ECBD7119F479C2EE546C123A585D697A7D10B55C2D28BEF0D299C01DC65420A03FE5227ECDECB8025FBC86EEBC1935298C1753AB849936749719591758C315FA150400789BB14FADD6EAE2AD617DA38163199D1BAD5D3F8F6A7A20AEF420ADFE2404D30B219359C6A4952565CCCA6F11EC5BE564B49B0EA5BF5B3DC8C5C6401208D0029C3957A8C5922CBDE39D3A564C6DEBB6BD2AEF91FC27BB3D3892BEB9646DCE2E1EF8581EFFA712158AAEC541C0BBB4B3E279D7DA54E45A0ACC3570E712C9F7CDF985CFAFD382AE13A3B214A9E8E1E71AB1EA707895112ABC3A97D0FCB0AE2EE5C85492B6CFD54885CDD6337E895CC70FB3255E3";
    
    NSArray *testKeyArray = [[NSArray alloc] initWithObjects:rid,key_index,hashAlgorithm,encryption_Algorithm,hashValue,publicKey_Exponent,@"F800",modulus, nil];
    
    NSString* combined = [testKeyArray componentsJoinedByString:@""];
    
    NSData* capk = [IDTUtility hexToData:combined];
    RETURN_CODE setReturnCode = [[IDT_VP3300 sharedController] emv_setCAPKFile:capk];
    if (RETURN_CODE_DO_SUCCESS == setReturnCode) {
        NSLog(@"loadAmexPublic1984TestKey loaded");
    } else{
        NSLog(@"loadAmexPublic1984TestKey failed to load");
    }
}


- (NSString *) getFirmwareVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Firmware version not found";
    }
}

- (NSString *) getKernelVersion {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Kernel Version Unknown";
    }
}

- (NSString *) getDeviceSerialNumber {
    NSString *result;
    RETURN_CODE rt = [[IDT_VP3300 sharedController] config_getSerialNumber:&result];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        return result;
    } else{
        return @"IDTECH Serial number not found";
    }
}

-(void)deviceDisconnected{
    [self.publicDelegate deviceDisconnected];
}

- (void) deviceMessage:(NSString*)message {
    NSLog(@"IDTech framework called our device message");
    [self.publicDelegate deviceMessage:(NSString*)message];
}

//TODO should we return an error here ? sometimes idtech sends the message here and says its an error but then sends the message to emvTransactionData and says there IS card data?!
- (void) swipeMSRData:(IDTMSRData*)cardData{
    if (cardData != nil && cardData.event == EVENT_MSR_CARD_DATA && (cardData.track2 != nil || cardData.encTrack2 != nil)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequestForASwipe:cardData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    } else {
        [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
    }
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequestForASwipe:(IDTMSRData*)cardData{
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    if (cardData.encTrack2 != nil) {
        NSString *encryptedTrack2Data = [[NSString alloc] initWithData:cardData.encTrack2
                                                              encoding:NSUTF8StringEncoding];
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:true track2Data:encryptedTrack2Data];
    } else if (cardData.track2 != nil) {
        clearentTransactionTokenRequest = [self createClearentTransactionToken:false encrypted:false track2Data:cardData.track2];
    }
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionToken:(BOOL)emv encrypted:(BOOL)encrypted track2Data:(NSString*) track2Data {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    clearentTransactionTokenRequest.emv = emv;
    clearentTransactionTokenRequest.encrypted = encrypted;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.track2Data = track2Data;
    return clearentTransactionTokenRequest;
}

- (void) emvTransactionData:(IDTEMVData*)emvData errorCode:(int)error{
    if (emvData == nil) {
        return;
    }
    //The mobilw-jwt call should succeed or fail. We call the IDTech complete method every time. We alert the client by messaging them via the errorTransactionToken delegate method.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED || emvData.resultCodeV2 == EMV_RESULT_CODE_V2_APPROVED_OFFLINE ) {
        return;
    }
    //We aren't starting an authorization so this result code should never be set. But return just in case.
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_START_TRANS_SUCCESS) {
        return;
    }
    if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_CARD_ERROR) {
        [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
        return;
    }
    
    int entryMode = 0;
    if (emvData.unencryptedTags != nil) {
        entryMode = getEntryMode([[emvData.unencryptedTags objectForKey:@"9F39"] description]);
    } else if (emvData.encryptedTags != nil) {
        entryMode = getEntryMode([[emvData.encryptedTags objectForKey:@"9F39"] description]);
    }
    //Not sure how this scenario could happen but until we get some feedback from IdTech for some of the odd delegate communication behavior I think we'll just be defensive.
    if(entryMode == 0) {
        return;
    }
    //When we get an Go Online result code let's create the transaction token (jwt)
    //TODO clean up the carddata not nil check..its done in two places
    if (emvData.cardData != nil && emvData.resultCodeV2 == EMV_RESULT_CODE_V2_MSR_SUCCESS) {
        if(entryMode == SWIPE) {
            [self swipeMSRData:emvData.cardData];
        } else if(isSupportedEmvEntryMode(entryMode)) {
            ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
            [self createTransactionToken:clearentTransactionTokenRequest];
        } else {
            [self.publicDelegate errorTransactionToken:GENERIC_CARD_READ_ERROR_RESPONSE];
        }
    } else if (emvData.resultCodeV2 == EMV_RESULT_CODE_V2_GO_ONLINE || (entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE || emvData.cardType == 1)) {
        ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [self createClearentTransactionTokenRequest:emvData];
        [self createTransactionToken:clearentTransactionTokenRequest];
    }
}

int getEntryMode (NSString* rawEntryMode) {
    if(rawEntryMode == nil || [rawEntryMode isEqualToString:@""]) {
        return 0;
    }
    NSString *entryModeWithoutTags = [rawEntryMode stringByReplacingOccurrencesOfString:@"[\\<\\>]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [rawEntryMode length])];
    return [entryModeWithoutTags intValue];
}

BOOL isSupportedEmvEntryMode (int entryMode) {
    if(entryMode == FALLBACK_SWIPE || entryMode == NONTECH_FALLBACK_SWIPE || entryMode == CONTACTLESS_EMV || entryMode == CONTACTLESS_MAGNETIC_SWIPE) {
        return true;
    }
    return false;
}

- (ClearentTransactionTokenRequest*)  createClearentTransactionTokenRequest:(IDTEMVData*)emvData {
    if(emvData.cardData != nil) {
        if(emvData.cardData.encTrack2 != nil) {
            [emvData.encryptedTags setValue:emvData.cardData.encTrack2 forKey:TRACK2_DATA_EMV_TAG];
            return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true];
        } else if(emvData.cardData.track2 != nil) {
            [emvData.unencryptedTags setValue:emvData.cardData.track2 forKey:TRACK2_DATA_EMV_TAG];
            return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
        }
    } else if (emvData.unencryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.unencryptedTags isEncrypted: false];
    } else if (emvData.encryptedTags != nil) {
        return [self createClearentTransactionTokenRequest:emvData.encryptedTags isEncrypted: true];
    }
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    return clearentTransactionTokenRequest;
}

- (ClearentTransactionTokenRequest*) createClearentTransactionTokenRequest:(NSDictionary*) tags isEncrypted:(BOOL) isEncrypted {
    ClearentTransactionTokenRequest *clearentTransactionTokenRequest = [[ClearentTransactionTokenRequest alloc] init];
    
    NSMutableDictionary *mutableTags = [tags mutableCopy];
    [mutableTags setObject:self.deviceSerialNumber forKey:DEVICE_SERIAL_NUMBER_EMV_TAG];
    [mutableTags setObject:self.kernelVersion forKey:KERNEL_VERSION_EMV_TAG];
    
    //set Major tags
    //9F35 Terminal Type 21
    //9F33 Terminal Capabilities 6028C8
    //9F40 Additional Terminal Capabilities F000F0A001
    //DF26 Enable Revocation List Processing 01
    //DF11 Enable Transaction Logging 00
    //DF27 Enable Exception List Processing 00
    //DFEE1E Terminal Configuration D0DC20D0C41E1400
    
    [mutableTags setObject:@"6028C8" forKey:@"9F33"];
    [mutableTags setObject:@"F000F0A001" forKey:@"9F40"];
    [mutableTags setObject:@"01" forKey:@"DF26"];
    [mutableTags setObject:@"00" forKey:@"DF11"];
    [mutableTags setObject:@"00" forKey:@"DF27"];
    
    //Set Minor Tags
    //5F36 Transaction Currency Exponent 02
    //9F1A Terminal Country Code 840
    //9F1E Interface Device (IFD) Serial Number 5465726D696E616C
    //9F15 Merchant Category Code 5999
    //9F16 Merchant Identifier 888000001516
    //9F1C Terminal Identification 1515
    //9F4E Merchant Name and Location Test Merchant
    [mutableTags setObject:@"02" forKey:@"5F36"];
    [mutableTags setObject:@"0840" forKey:@"9F1A"];
    [mutableTags setObject:@"5465726D696E616C" forKey:@"9F1E"];
    [mutableTags setObject:@"5999" forKey:@"9F15"];
    
    //888000001516 as CEC0ECB5EC
    [mutableTags setObject:@"888000001516" forKey:@"9F16"];
    [mutableTags setObject:@"1515" forKey:@"9F1C"];
    //test merchant in hex 54657374204d65726368616e74
    [mutableTags setObject:@"54657374204d65726368616e74" forKey:@"9F4E"];
    
    
    //Remove Tags
    [mutableTags removeObjectForKey:@"DF78"];
    [mutableTags removeObjectForKey:@"DF79"];
    [mutableTags removeObjectForKey:@"DF27"];
    [mutableTags removeObjectForKey:@"DFEF4D"];
    [mutableTags removeObjectForKey:@"DFEF4C"];
    [mutableTags removeObjectForKey:@"DF11"];
    [mutableTags removeObjectForKey:@"DFEE26"];
    
    [mutableTags removeObjectForKey:@"DFEE25"];
    [mutableTags removeObjectForKey:@"FFEE01"];
    [mutableTags removeObjectForKey:@"DFEE23"];
    [mutableTags removeObjectForKey:@"DF26"];
    
    [mutableTags removeObjectForKey:@"9F16"];
    
    //Get tags based on TSYS impl guide. TODO Rely on on what is returned from emv_retrieveTransactionResult
    //NSData *tsysTags = [IDTUtility hexToData:@"82 9A 9C 5F2A 9F0D 9F0E 9F0F 9F21 9F35 9F36 9F06"];
    
    //CONTACT 9F40 9F06 9F09 9F15 9F33 9F1A 5F2A 5F36 9F1B 9F35 9F53 9F1E 9F16 9F1C 9F4E 82 009A 009C 9F0D 9F0E 9F0F 9F36
    //CONTACTLESS 9F6D 9F66
    //0082009A009C
    
    //remove these for now - 9F6E 9F53 9F16
    //Original big one
    NSData *tsysTags = [IDTUtility hexToData:@"82959A9B9C9F349F029F039F404F849F069F099F159F339F1A5F2A5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //up to 5F36
    
    //include 9F09 9F15 9F33 9F1A 5F2A
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //NSData *tsysTags = [IDTUtility hexToData:@"9F099F339F1A5F2A5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //82959A9B9C9F349F029F039F404F849F06
    
    // exclude 9F09 9F15 9F33 9F1A 5F2A
    
    //include 82959A9B9C9F349F02
    //NSData *tsysTags = [IDTUtility hexToData:@"82959A9B9C9F349F025F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //excluded 9F03 9F40 9F06 4F 84 9F09 9F15 9F33 9F1A 5F2A
    //NSData *tsysTags = [IDTUtility hexToData:@"9F0382959A9B9C9F349F025F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //try 9F15 9F1A 5F2A
    //NSData *tsysTags = [IDTUtility hexToData:@"82959A9B9C9F349F025F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //Good one
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //    NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F0F9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F369F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F399F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F219F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F269F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F275F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"5F2D5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"5F349F10"];
    //    NSData *tsysTags = [IDTUtility hexToData:@"9F10"];
    //NSData *tsysTags = [IDTUtility hexToData:@""];
    
    //NSData *tsysTags = [IDTUtility hexToData:@"5F369F1B9F359F1E9F1C9F4E9F0D9F0E9F0F9F369F399F219F269F275F2D5F349F10"];
    
    //    NSData *tsysTagsGroupIII55Only = [IDTUtility hexToData:@"82959A9B9C5F2A9F029F039F0D9f0E9F0F9F1A9F219F269F279F339F349F359F369F379F399F404F845F2D5F349F069F10DF78DF79"];
    
    NSDictionary *transactionResultDictionary;
    RETURN_CODE transactionDateRt = [[IDT_VP3300 sharedController] emv_retrieveTransactionResult:tsysTags retrievedTags:&transactionResultDictionary];
    NSData *tagsAsNSData;
    NSString *tlvInHex;
    NSMutableDictionary *mutableTags2;
    if(RETURN_CODE_DO_SUCCESS == transactionDateRt) {
        NSDictionary *transactionTags = [transactionResultDictionary objectForKey:@"tags"];
        NSDictionary *combined = [IDTUtility combineDictionaries:(NSDictionary*)transactionTags dest:mutableTags overwrite:false];
        
        mutableTags2 = [combined mutableCopy];
        [mutableTags2 removeObjectForKey:@"DF27"];
        [mutableTags2 removeObjectForKey:@"DFEF4D"];
        [mutableTags2 removeObjectForKey:@"DFEF4C"];
        [mutableTags2 removeObjectForKey:@"DF11"];
        [mutableTags2 removeObjectForKey:@"DFEE26"];
        [mutableTags2 removeObjectForKey:@"DF78"];
        [mutableTags2 removeObjectForKey:@"DF79"];
        [mutableTags2 removeObjectForKey:@"DFEE25"];
        [mutableTags2 removeObjectForKey:@"FFEE01"];
        [mutableTags2 removeObjectForKey:@"DFEE23"];
        [mutableTags2 removeObjectForKey:@"DF26"];
        
        [mutableTags2 removeObjectForKey:@"9F16"];
        
        //tagsAsNSData = [IDTUtility DICTotTLV:mutableTags2];
        
        tagsAsNSData = [IDTUtility DICTotTLV:mutableTags2];
        
        tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    } else {
        tagsAsNSData = [IDTUtility DICTotTLV:mutableTags];
        tlvInHex = [IDTUtility dataToHexString:tagsAsNSData];
    }
    clearentTransactionTokenRequest.tlv = tlvInHex.uppercaseString;
    clearentTransactionTokenRequest.emv = true;
    clearentTransactionTokenRequest.kernelVersion = [self kernelVersion];
    clearentTransactionTokenRequest.deviceSerialNumber = [self deviceSerialNumber];
    clearentTransactionTokenRequest.firmwareVersion = [self firmwareVersion];
    clearentTransactionTokenRequest.encrypted = isEncrypted;
    
    NSString *track2Data57 = [IDTUtility dataToHexString:[mutableTags2 objectForKey:TRACK2_DATA_EMV_TAG]];
    if(track2Data57 != nil && !([track2Data57 isEqualToString:@""])) {
        clearentTransactionTokenRequest.track2Data = track2Data57;
    } else {
        NSDictionary *ff8105 = [IDTUtility TLVtoDICT_HEX_ASCII:[tags objectForKey:@"FF8105"]];
        NSString *track2Data9F6B = [ff8105 objectForKey:TRACK2_DATA_CONTACTLESS_NON_CHIP_TAG];
        if(track2Data9F6B != nil && !([track2Data9F6B isEqualToString:@""])) {
            clearentTransactionTokenRequest.track2Data = track2Data9F6B;
        } else {
            clearentTransactionTokenRequest.track2Data = @"Mobile SDK failed to read Track2Data";
        }
    }
    return clearentTransactionTokenRequest;
}

- (void) createTransactionToken:(ClearentTransactionTokenRequest*)clearentTransactionTokenRequest {
    NSString *targetUrl = [NSString stringWithFormat:@"%@", [self.publicDelegate getTransactionTokenUrl]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:clearentTransactionTokenRequest.asDictionary options:0 error:&error];
    
    if (error) {
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        return;
    }
    
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[self.publicDelegate getPublicKey] forHTTPHeaderField:@"public-key"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSString *responseStr = nil;
          if(error != nil) {
              [self.publicDelegate errorTransactionToken:error.description];
              [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
          } else if(data != nil) {
              responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              if(200 == [httpResponse statusCode]) {
                  //[[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
                  [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleResponse:responseStr];
              } else {
                  [[IDT_VP3300 sharedController] emv_completeOnlineEMVTransaction:false hostResponseTags:nil];
                  [self handleError:responseStr];
              }
          }
          data = nil;
          response = nil;
          error = nil;
      }] resume];
}

- (void) handleError:(NSString*)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    } else {
        NSDictionary *payloadDictionary = [jsonDictionary objectForKey:@"payload"];
        NSDictionary *errorDictionary = [payloadDictionary objectForKey:@"error"];
        NSString *errorMessage = [errorDictionary objectForKey:@"error-message"];
        if(errorMessage != nil) {
            [self.publicDelegate errorTransactionToken:[NSString stringWithFormat:@"%@. %@.", GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE, errorMessage]];
        } else {
            [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
        }
    }
}

- (void) handleResponse:(NSString *)response {
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
    NSString *responseCode = [jsonDictionary objectForKey:@"code"];
    if([responseCode isEqualToString:@"200"]) {
        [self.publicDelegate successfulTransactionToken:response];
    } else {
        [self.publicDelegate errorTransactionToken:GENERIC_TRANSACTION_TOKEN_ERROR_RESPONSE];
    }
}

@end

