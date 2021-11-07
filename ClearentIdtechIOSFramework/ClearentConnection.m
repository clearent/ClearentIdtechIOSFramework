//
//  ClearentConnection.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/30/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import "ClearentConnection.h"
#import "ClearentCache.h"
#import "ClearentLumberjack.h"

@implementation ClearentConnection

static int const DEFAULT_BLUETOOTH_MAXIMUM_SCAN_TIME_IN_SECONDS = 10;
static int const DEFAULT_BLUETOOTH_SEARCH_MAXIMUM_SCAN_TIME_IN_SECONDS = 10;
static NSString *const IDTECH_FRIENDLY_NAME_PREFIX = @"IDTECH-VP3300-";

- (instancetype) initBluetoothSearch {
    self = [super init];
    if (self) {
        
        self.connectionType = CLEARENT_BLUETOOTH;
        self.readerInterfaceMode = CLEARENT_READER_INTERFACE_3_IN_1;
        self.bluetoothMaximumScanInSeconds = DEFAULT_BLUETOOTH_SEARCH_MAXIMUM_SCAN_TIME_IN_SECONDS;
       // self.bluetoothAdvertisingInterval = CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT;
        self.connectToFirstBluetoothFound = false;
        self.searchBluetooth = true;
        self.lastFiveDigitsOfDeviceSerialNumber = nil;
        self.bluetoothDeviceId = nil;
        self.fullFriendlyName = nil;
    }
    return self;
}

- (instancetype) initBluetoothSearchWithMaxScanTime: (int) bluetoothMaximumScanInSeconds {
    self = [self initBluetoothSearch];
    if (self) {
        self.bluetoothMaximumScanInSeconds = bluetoothMaximumScanInSeconds;
    }
    return self;
}

- (instancetype) initBluetoothFirstConnect {
    self = [super init];
    if (self) {
        
        self.connectionType = CLEARENT_BLUETOOTH;
        self.readerInterfaceMode = CLEARENT_READER_INTERFACE_3_IN_1;
        self.bluetoothMaximumScanInSeconds = DEFAULT_BLUETOOTH_MAXIMUM_SCAN_TIME_IN_SECONDS;
      //  self.bluetoothAdvertisingInterval = CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT;
        self.connectToFirstBluetoothFound = true;
        self.searchBluetooth = false;
        self.lastFiveDigitsOfDeviceSerialNumber = nil;
        self.bluetoothDeviceId = nil;
        self.fullFriendlyName = nil;
    }
    return self;
}

- (instancetype) initBluetoothWithLast5: (NSString*) lastFiveDigitsOfDeviceSerialNumber  {
    self = [super init];
    if (self) {
        
        self.connectionType = CLEARENT_BLUETOOTH;
        self.readerInterfaceMode = CLEARENT_READER_INTERFACE_3_IN_1;
        self.bluetoothMaximumScanInSeconds = DEFAULT_BLUETOOTH_MAXIMUM_SCAN_TIME_IN_SECONDS;
      //  self.bluetoothAdvertisingInterval = CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT;
        self.connectToFirstBluetoothFound = false;
        self.searchBluetooth = false;
        self.lastFiveDigitsOfDeviceSerialNumber = lastFiveDigitsOfDeviceSerialNumber;
        self.bluetoothDeviceId = nil;
        self.fullFriendlyName = nil;
    }
    return self;
}

- (instancetype) initBluetoothWithFriendlyName: (NSString*) fullFriendlyName  {
    self = [super init];
    if (self) {
        
        self.connectionType = CLEARENT_BLUETOOTH;
        self.readerInterfaceMode = CLEARENT_READER_INTERFACE_3_IN_1;
        self.bluetoothMaximumScanInSeconds = DEFAULT_BLUETOOTH_MAXIMUM_SCAN_TIME_IN_SECONDS;
      //  self.bluetoothAdvertisingInterval = CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT;
        self.connectToFirstBluetoothFound = false;
        self.searchBluetooth = false;
        self.lastFiveDigitsOfDeviceSerialNumber = nil;
        self.bluetoothDeviceId = nil;
        self.fullFriendlyName = fullFriendlyName;
    }
    return self;
}

- (instancetype) initBluetoothWithDeviceUUID: (NSString*) deviceUUID {
    self = [super init];
    if (self) {
        
        self.connectionType = CLEARENT_BLUETOOTH;
        self.readerInterfaceMode = CLEARENT_READER_INTERFACE_3_IN_1;
        self.bluetoothMaximumScanInSeconds = DEFAULT_BLUETOOTH_MAXIMUM_SCAN_TIME_IN_SECONDS;
      //  self.bluetoothAdvertisingInterval = CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT;
        self.connectToFirstBluetoothFound = false;
        self.searchBluetooth = false;
        self.lastFiveDigitsOfDeviceSerialNumber = nil;
        self.bluetoothDeviceId = deviceUUID;
        self.fullFriendlyName = nil;
    }
    return self;
}


- (instancetype) initAudioJack {
    self = [super init];
    if (self) {
        
        self.connectionType = CLEARENT_AUDIO_JACK;
        self.readerInterfaceMode = CLEARENT_READER_INTERFACE_3_IN_1;
        
    }
    return self;
}


- (NSString*) createLogMessage {
    
    NSString *logMessage;
    
    NSString *lastFiveDigitsOfDeviceSerialNumber;
    NSString *bluetoothMaximumScanInSeconds;
    NSString *connectionType;
    NSString *connectToFirstBluetoothFound;
    NSString *searchBluetooth;
    NSString *readerInterfaceMode;
    NSString *fullFriendlyName;
    NSString *bluetoothDeviceId;
    
    @try {
       
        if(self.lastFiveDigitsOfDeviceSerialNumber == nil) {
            lastFiveDigitsOfDeviceSerialNumber = @"none";
        } else {
            lastFiveDigitsOfDeviceSerialNumber = self.lastFiveDigitsOfDeviceSerialNumber;
        }
            
        if(self.fullFriendlyName == nil) {
            fullFriendlyName = @"none";
        } else {
            fullFriendlyName = self.fullFriendlyName;
        }
        
        if(self.bluetoothDeviceId == nil) {
            bluetoothDeviceId = @"none";
        } else {
            bluetoothDeviceId = self.bluetoothDeviceId;
        }
        
        bluetoothMaximumScanInSeconds = [NSString stringWithFormat:@"%i", self.bluetoothMaximumScanInSeconds];
            
        if(self.connectionType == CLEARENT_BLUETOOTH) {
            connectionType = @"bluetooth";
        } else if(self.connectionType == CLEARENT_AUDIO_JACK) {
            connectionType = @"audio jack";
        } else {
            connectionType = @"unknown";
        }
        
        if(self.connectToFirstBluetoothFound) {
            connectToFirstBluetoothFound = @"TRUE";
        } else {
            connectToFirstBluetoothFound = @"FALSE";
        }
        
        if(self.searchBluetooth) {
            searchBluetooth = @"TRUE";
        } else {
            searchBluetooth = @"FALSE";
        }
        
        if(self.readerInterfaceMode == CLEARENT_READER_INTERFACE_3_IN_1) {
            readerInterfaceMode = @"3 in 1";
        } if(self.readerInterfaceMode == CLEARENT_READER_INTERFACE_2_IN_1) {
            readerInterfaceMode = @"2 in 1";
        } else {
            readerInterfaceMode = @"unknown";
        }
        
        logMessage= [NSString stringWithFormat:@" Connection properties %@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", @"lastFiveDigitsOfDeviceSerialNumber:", lastFiveDigitsOfDeviceSerialNumber, @" bluetoothMaximumScanInSeconds:", bluetoothMaximumScanInSeconds, @" connectionType:", connectionType, @" connectToFirstBluetoothFound:", connectToFirstBluetoothFound, @" readerInterfaceMode:", readerInterfaceMode, @" fullFriendlyName:", fullFriendlyName, @" searchBluetooth:", searchBluetooth, @" bluetoothDeviceId:", bluetoothDeviceId];
        
    } @catch (NSException *exception) {
        logMessage = @"Failed to create log message of ClearentConnection";
    }
    
    return logMessage;
}

+ (NSString*) createFullIdTechFriendlyName:(NSString*) lastFiveDigitsOfDeviceSerialNumber {
    
    return [NSString stringWithFormat:@"%@%@",IDTECH_FRIENDLY_NAME_PREFIX, lastFiveDigitsOfDeviceSerialNumber];
    
}

- (BOOL) isDeviceKnown {
    
    if(self.fullFriendlyName != nil
        && ![self.fullFriendlyName isEqualToString:@""]) {
        return YES;
    } else if(self.lastFiveDigitsOfDeviceSerialNumber != nil
        && ![self.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]) {
        return YES;
    } else if(self.bluetoothDeviceId != nil
        && ![self.bluetoothDeviceId isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL) isNewConnectionRequest:(ClearentConnection*) currentConnection connectionRequest:(ClearentConnection*) connectionRequest {
    
    if(currentConnection == nil || connectionRequest == nil ) {
        [ClearentLumberjack logInfo:@"isNewConnectionRequest:nil"];
        return YES;
    } else if(connectionRequest != nil && connectionRequest.searchBluetooth) {
        [ClearentLumberjack logInfo:@"isNewConnectionRequest:connectionRequest is search"];
        return YES;
    }
    
    if(currentConnection != nil
        && connectionRequest != nil
        && currentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
        && connectionRequest.lastFiveDigitsOfDeviceSerialNumber != nil
        && ![currentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:connectionRequest.lastFiveDigitsOfDeviceSerialNumber]) {
        [ClearentLumberjack logInfo:@"isNewConnectionRequest:request 5 digits does not match current connection 5 digits"];
        return YES;
    }
    
    if(currentConnection != nil
        && connectionRequest != nil
        && currentConnection.bluetoothDeviceId != nil
        && connectionRequest.bluetoothDeviceId != nil
        && ![currentConnection.bluetoothDeviceId isEqualToString:connectionRequest.bluetoothDeviceId]) {
        [ClearentLumberjack logInfo:@"isNewConnectionRequest:request bluetoothDeviceId does not match current connection bluetoothDeviceId"];
        return YES;
    }
    
    if(currentConnection != nil
        && connectionRequest != nil
        && currentConnection.fullFriendlyName != nil
        && connectionRequest.fullFriendlyName != nil
        && ![currentConnection.fullFriendlyName isEqualToString:connectionRequest.fullFriendlyName]) {
        [ClearentLumberjack logInfo:@"isNewConnectionRequest:request fullFriendlyName does not match current connection fullFriendlyName"];
        return YES;
    }
    
    [ClearentLumberjack logInfo:@"isNewConnectionRequest:NO"];
    return NO;
}

@end
