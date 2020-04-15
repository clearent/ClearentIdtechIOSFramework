//
//  ClearentDeviceConnector.m
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/2/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClearentDeviceConnector.h"
#import "ClearentCache.h"
#import "Teleport.h"
#import "ClearentConnection.h"
#import "ClearentDelegate.h"
#import "Clearent_VP3300.h"
#import "ClearentBluetoothDevice.h"
#import "IDTUtility.h"

@implementation ClearentDeviceConnector

static NSString *const CONNECTION_TYPE_REQUIRED = @"Connection type required";
static NSString *const BLUETOOTH_SEARCH_IN_PROGRESS  = @"SEARCHING BLUETOOTH";
static NSString *const BLUETOOTH_NOT_CONNECTED  = @"BLUETOOTH NOT CONNECTED";
static NSString *const CONNECTION_PROPERTIES_REQUIRED = @"CONNECTION PROPERTIES REQUIRED";
static NSString *const NEW_BLUETOOTH_CONNECTION_REQUESTED = @"NEW BLUETOOTH CONNECTION REQUESTED. DISCONNECT CURRENT BLUETOOTH";
static NSString *const DISCONNECTING_BLUETOOTH_PLUGIN_AUDIO_JACK = @"DISCONNECTING BLUETOOTH. PLUG IN AUDIO JACK";
static NSString *const USER_ACTION_PRESS_BUTTON_MESSAGE = @"PRESS BUTTON ON READER";
static NSString *const PLUGIN_AUDIO_JACK = @"PLUGIN AUDIO JACK";
static NSString *const INVALID_FIRMWARE_VERSION = @"Device Firmware version not found";
static NSString *const INVALID_FRIENDLY_NAME = @"INVALID_FRIENDLY_NAME";

NSTimer *bluetoothSearchDisableTimer;

- (instancetype) init: (ClearentDelegate*) clearentDelegate clearentVP3300:(Clearent_VP3300*) clearentVP3300 {
    
    self = [super init];
    
    if (self) {
        _clearentDelegate = clearentDelegate;
        _clearentVP3300 = clearentVP3300;
        _previousConnectionFailed = false;
        _retriedBluetoothWhenNoDevicesFound = false;
        _tryConnectWithSavedDeviceId = false;
        _bluetoothSearchInProgress = false;
        _bluetoothDevices = [[NSMutableArray<ClearentBluetoothDevice> alloc] init];
    }
    
    return self;
}

- (void) resetConnection {
    
    [_bluetoothDevices removeAllObjects];
    
    [self resetBluetoothAfterConnected];
    
}

- (void) resetBluetoothAfterConnected {
    
    _bluetoothSearchInProgress = false;
    _tryConnectWithSavedDeviceId = false;
    _previousConnectionFailed = false;
    _retriedBluetoothWhenNoDevicesFound = false;
    _searchingBluetoothfriendlyName = nil;
    _searchingBluetoothDeviceId = nil;
    _connectingWithBluetoothfriendlyName = nil;
    _connectingWithBluetoothDeviceId = nil;
    _foundDeviceWaitingToConnect = false;
    _findBluetoothFriendlyName = nil;
    
}

- (void) startConnection:(ClearentConnection*) clearentConnection {
    
    if(clearentConnection == nil) {
        [_clearentDelegate deviceMessage:CONNECTION_PROPERTIES_REQUIRED];
        return;
    }
    
    if(clearentConnection.connectionType == AUDIO_JACK && ![_clearentVP3300 device_isAudioReaderConnected]) {
        [_clearentDelegate deviceMessage:@"AUDIO JACK NOT CONNECTED"];
        return;
    }
    
    [self resetConnection];
    
    [[IDT_VP3300 sharedController] device_setBLEFriendlyName:nil];
    
    [self disconnect:clearentConnection];
    
    if(![_clearentVP3300 isConnected]) {
        if(clearentConnection.connectionType == AUDIO_JACK) {
            if([_clearentVP3300 device_isAudioReaderConnected]) {
                [_clearentDelegate deviceMessage:@"AUDIO JACK CONNECTED"];
            } else {
                [_clearentDelegate deviceMessage:@"AUDIO JACK NOT CONNECTED"];
            }
        } else if(clearentConnection.connectionType == BLUETOOTH) {
            [self startBluetoothSearch: clearentConnection];
        }
    } else {
        if(clearentConnection.connectionType == BLUETOOTH) {
            NSString *logMessage = [NSString stringWithFormat:@"CONNECTED : %@", [_clearentVP3300 device_getBLEFriendlyName]];
            [self sendBluetoothFeedback:logMessage];
        } else {
            [_clearentDelegate deviceMessage:@"AUDIO JACK CONNECTED"];
        }
    }
}

- (void) disconnect:(ClearentConnection*) clearentConnection  {
    
    if([_clearentVP3300 device_isAudioReaderConnected] && clearentConnection.connectionType == AUDIO_JACK) {
        [Teleport logInfo:@"disconnectBluetooth AUDIO JACK ALREADY CONNECTED"];
    } else if([_clearentVP3300 isConnected]
       && [self isNewConnectionRequest:clearentConnection] && _clearentDelegate.clearentConnection.connectionType == BLUETOOTH) {
        [Teleport logInfo:@"disconnectBluetooth. Device is connected but a new connection request is provided. Disconnect bluetooth"];
        [Teleport logInfo:@"disconnectBluetooth CLEAR SAVED BLUETOOTH DEVICE FROM CACHE"];
        [self disconnectBluetooth];
    } else if([_clearentVP3300 isConnected] && _previousConnectionFailed) {
        [Teleport logInfo:@"disconnectBluetooth. the framework says it's connected but previous attempt to connect failed. FORCE A DISCONNECT"];
        [self disconnectBluetooth];
    }
}

//TODO does this belong in the connector ?
//- (void) adjustBluetoothAdvertisingInterval {
//
//    if(_clearentDelegate.clearentConnection != nil && [_clearentVP3300 isConnected]) {
//
//        NSString *firmwareVersion = [_clearentDelegate getFirmwareVersion];
//
//        if(firmwareVersion != nil
//           && ([firmwareVersion isEqualToString:INVALID_FIRMWARE_VERSION] ||
//               [firmwareVersion isEqualToString:@"VP3300 Bluetooth NEO v1.01.151"] ||
//               [firmwareVersion isEqualToString:@"VP3300 Bluetooth NEO v1.01.090"]
//                 || [firmwareVersion isEqualToString:@"VP3300 Audio Jack NEO v1.01.055"]
//                 || [firmwareVersion isEqualToString:@"VP3300 Audio Jack NEO v1.01.064"])) {
//                  [Teleport logInfo:[NSString stringWithFormat:@"skipping adjustBluetoothAdvertisingInterval for firmware version - %@", firmwareVersion]];
//            return;
//        } else {
//            [Teleport logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval: firmware version - %@", firmwareVersion]];
//        }
//
//        NSString *advertisingIntervalHex;
//
//        advertisingIntervalHex = [self getAdvertisingIntervalInHex:_clearentDelegate.clearentConnection.bluetoothAdvertisingInterval];
//
//        NSString *updateAdvertisingIntervalStr = [NSString stringWithFormat:@"DFED6C02%@", advertisingIntervalHex];
//
//        [Teleport logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval update %@", updateAdvertisingIntervalStr]];
//
//        NSData *configData = [IDTUtility hexToData:updateAdvertisingIntervalStr];
//        RETURN_CODE ctls_setTerminalDataRt = [[IDT_VP3300 sharedController] ctls_setTerminalData:configData];
//
//        if (RETURN_CODE_DO_SUCCESS == ctls_setTerminalDataRt) {
//                [Teleport logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval updated"]];
//        } else {
//            NSString *errorResponse = [[IDT_VP3300 sharedController] device_getResponseCodeString:ctls_setTerminalDataRt];
//            [_clearentDelegate deviceMessage:errorResponse];
//            [Teleport logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval failed set advertising interval. error %@", errorResponse]];
//        }
//    } else {
//        [Teleport logInfo:[NSString stringWithFormat:@"reader is not connected or no connection props. skip updating advertising interval"]];
//    }
//
//}

//- (NSString*) getAdvertisingIntervalInHex: (BLUETOOTH_ADVERTISING_INTERVAL) bluetoothAdvertisingInterval {
//    
//    NSString *advIntHex;
//
//    switch(bluetoothAdvertisingInterval){
//        case BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT:
//            advIntHex = @"02F8";
//             break;
//        case BLUETOOTH_ADVERTISING_INTERVAL_319_MS:
//            advIntHex = @"013F";
//             break;
//        case BLUETOOTH_ADVERTISING_INTERVAL_760_MS:
//            advIntHex = @"02F8";
//             break;
//        case BLUETOOTH_ADVERTISING_INTERVAL_1280_MS:
//            advIntHex = @"0500";
//        break;
//    default:
//            advIntHex = @"013E";
//        break;
//    }
//
//    return advIntHex;
//}

//TODO equality ?
- (BOOL) isNewConnectionRequest:(ClearentConnection*) clearentConnection {
    if(_clearentDelegate.clearentConnection == nil) {
        return YES;
    } else if(_clearentDelegate.clearentConnection.searchBluetooth) {
        return YES;
    } else if(clearentConnection.connectionType == BLUETOOTH) {
        if(clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
           && ![clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]
           && (_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber == nil
           || ![_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:clearentConnection.lastFiveDigitsOfDeviceSerialNumber])) {
            return YES;
        } else if(clearentConnection.fullFriendlyName != nil
                  && ![clearentConnection.fullFriendlyName isEqualToString:@""]
                  && (_clearentDelegate.clearentConnection.fullFriendlyName == nil
                  || ![_clearentDelegate.clearentConnection.fullFriendlyName isEqualToString:clearentConnection.fullFriendlyName])) {
            return YES;
        } else if(_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
                  && ![_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]
                  && clearentConnection.fullFriendlyName != nil
                  && ![clearentConnection.fullFriendlyName isEqualToString:@""]) {
            return YES;
        } else if(_clearentDelegate.clearentConnection.fullFriendlyName != nil
                  && ![_clearentDelegate.clearentConnection.fullFriendlyName isEqualToString:@""]
                  && clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
                  && ![clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]) {
            return YES;
        } else if(_clearentDelegate.clearentConnection.connectionType != clearentConnection.connectionType) {
            return YES;
        } else if(_clearentDelegate.clearentConnection.connectToFirstBluetoothFound != clearentConnection.connectToFirstBluetoothFound) {
            return YES;
        } else if(_clearentDelegate.clearentConnection.bluetoothMaximumScanInSeconds != clearentConnection.bluetoothMaximumScanInSeconds) {
            return YES;
        }
    } else if (_clearentDelegate.clearentConnection.connectionType != clearentConnection.connectionType) {
        
        if ([_clearentVP3300 isConnected]
        && _clearentDelegate.clearentConnection.connectionType == BLUETOOTH) {
           [Teleport logInfo:@"disconnectBluetooth. Still connected to bluetooth but wants to connect to audio jack. Disconnecting bluetooth"];
           [self sendBluetoothFeedback:DISCONNECTING_BLUETOOTH_PLUGIN_AUDIO_JACK];
           return YES;
        }
        return YES;
    }
    
    return FALSE;
}

- (void) startBluetoothSearch:(ClearentConnection*) clearentConnection {
    
    if(clearentConnection == nil) {
        [_clearentDelegate deviceMessage:CONNECTION_PROPERTIES_REQUIRED];
        return;
    }
    
    if([_clearentVP3300 isConnected] && !clearentConnection.searchBluetooth) {
        NSString *logMessage = [NSString stringWithFormat:@"CONNECTED : %@", [_clearentVP3300 device_getBLEFriendlyName]];
        if(clearentConnection.connectionType == BLUETOOTH) {
            [self sendBluetoothFeedback:logMessage];
        }
        return;
    }
    
    if(_bluetoothSearchInProgress) {
        [self sendBluetoothFeedback:BLUETOOTH_SEARCH_IN_PROGRESS];
        return;
    }
    
    [_bluetoothDevices removeAllObjects];
   
    if(clearentConnection.connectionType == BLUETOOTH) {
        
        [self updateConnection:clearentConnection];
        
        NSString *lastUsedBluetoothDeviceId = [ClearentCache getLastUsedBluetoothDeviceId];
        
        [self disableBluetoothSearchInFuture:clearentConnection];
        
        if(clearentConnection.searchBluetooth) {
            [self startBlindBluetoothSearch];
        } else if(lastUsedBluetoothDeviceId != nil && ![lastUsedBluetoothDeviceId isEqualToString:@""]) {
            [self startBluetoothSearchWithUUID:lastUsedBluetoothDeviceId];
        } else if(clearentConnection.bluetoothDeviceId != nil && ![clearentConnection.bluetoothDeviceId isEqualToString:@""]) {
            [self startBluetoothSearchWithUUID:clearentConnection.bluetoothDeviceId];
        } else if(clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil && ![clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]) {
            NSString *fullIdTechFriendlyName = [ClearentConnection createFullIdTechFriendlyName:clearentConnection.lastFiveDigitsOfDeviceSerialNumber];
            [self startBluetoothSearchWithFullFriendlyName:fullIdTechFriendlyName ];
        } else if(clearentConnection.fullFriendlyName != nil && ![clearentConnection.fullFriendlyName isEqualToString:@""]) {
            [self startBluetoothSearchWithFullFriendlyName:clearentConnection.fullFriendlyName ];
        } else {
            [self startBlindBluetoothSearch];
        }
        
    } else {
        
        if(clearentConnection.connectionType == BLUETOOTH) {
            [self sendBluetoothFeedback:CONNECTION_TYPE_REQUIRED];
        } else {
            [_clearentDelegate deviceMessage:CONNECTION_TYPE_REQUIRED];
        }
        
    }
}

- (void) disableBluetoothSearchInFuture: (ClearentConnection*) clearentConnection {
    
    NSString *lastUsedBluetoothDeviceId = [ClearentCache getLastUsedBluetoothDeviceId];
    
    if(clearentConnection.searchBluetooth) {
        _tryConnectWithSavedDeviceId = false;
    } else if(lastUsedBluetoothDeviceId != nil && ![lastUsedBluetoothDeviceId isEqualToString:@""]) {
        _tryConnectWithSavedDeviceId = true;
        [Teleport logInfo:@"disableBluetoothSearchInFuture. bluetooth search using saved device id."];
    } else if(clearentConnection.bluetoothDeviceId != nil && ![clearentConnection.bluetoothDeviceId isEqualToString:@""]) {
        _tryConnectWithSavedDeviceId = true;
        [Teleport logInfo:@"disableBluetoothSearchInFuture. bluetooth search using provided device id."];
    } else {
        _tryConnectWithSavedDeviceId = false;
    }
    
    [self disableBluetoothSearchAfterPeriod:clearentConnection.bluetoothMaximumScanInSeconds];
}

-(void) updateConnection: (ClearentConnection*) clearentConnection {
    [self clearSavedDeviceId:clearentConnection];
    [_clearentDelegate setClearentConnection:clearentConnection];
}

- (void) clearSavedDeviceId: (ClearentConnection*) clearentConnection {
    
    if(clearentConnection != nil && clearentConnection.connectionType == BLUETOOTH) {
        
        NSString *lastUsedFriendlyName = [ClearentCache getLastUsedBluetoothFriendlyName];
        NSString *lastUsedDeviceId = [ClearentCache getLastUsedBluetoothDeviceId];
    
        if(lastUsedFriendlyName != nil) {
            if(clearentConnection.searchBluetooth) {
                [self clearSavedBluetoothCache];
            } else if ([clearentConnection isDeviceKnown]) {
                if(lastUsedDeviceId != nil && clearentConnection.bluetoothDeviceId != nil
                   && ![clearentConnection.bluetoothDeviceId isEqualToString:@""]
                   && [clearentConnection.bluetoothDeviceId isEqualToString:lastUsedDeviceId]) {
                      [Teleport logInfo:@"BLUETOOTH DEVICE ID MATCHES SAVED DEVICE UUID"];
                } else if(clearentConnection.fullFriendlyName != nil
                   && ![clearentConnection.fullFriendlyName isEqualToString:@""]
                   && [clearentConnection.fullFriendlyName isEqualToString:lastUsedFriendlyName]) {
                      [Teleport logInfo:@"BLUETOOTH FRIENDLY NAME MATCHES SAVED FRIENDLY NAME"];
                } else if(clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
                    && ![clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]
                    && [lastUsedFriendlyName containsString:clearentConnection.lastFiveDigitsOfDeviceSerialNumber]) {
                       [Teleport logInfo:@"SAVED BLUETOOTH FRIENDLY NAME CONTAINS PROVIDED LAST 5 DIGITS OF DSN"];
                } else {
                    [self clearSavedBluetoothCache];
                }
            } else if(!clearentConnection.connectToFirstBluetoothFound) {
                  [self clearSavedBluetoothCache];
            }
        }
    }
}


- (void) clearSavedBluetoothCache {
    [Teleport logInfo:@"clearSavedDeviceId CLEAR SAVED BLUETOOTH DEVICE FROM CACHE"];
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    [self setInvalidSearchFriendlyName];
        
    if([_clearentVP3300 isConnected]) {
        [Teleport logInfo:@"clearSavedDeviceId. Device is connected but connection request is different than saved bluetooth device. Disconnect bluetooth"];
        [_clearentVP3300 device_disconnectBLE];
        [NSThread sleepForTimeInterval:0.5f];
    }
}

- (void) disconnectBluetooth {
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    [_clearentVP3300 device_disconnectBLE];
    [NSThread sleepForTimeInterval:0.5f];
    
}

-(void) disableBluetoothSearchAfterPeriod:(int) bluetoothMaximumScanInSeconds {
    
    bluetoothSearchDisableTimer = [NSTimer scheduledTimerWithTimeInterval:bluetoothMaximumScanInSeconds target:self selector:@selector(disableBluetoothSearch:) userInfo:nil repeats:false];
}

-(void) disableBluetoothSearch:(id) sender {
    
    RETURN_CODE rt = [_clearentVP3300 device_disableBLEDeviceSearch];
    
    if (RETURN_CODE_DO_SUCCESS == rt) {
        [Teleport logInfo:@"disableBluetoothSearch: BLUETOOTH SEARCH DISABLED"];
    } else {
        [Teleport logInfo:@"disableBluetoothSearch: BLUETOOTH SEARCH FAILED TO DISABLE"];
    }
   
    NSUInteger size = 0;
    
    if(_bluetoothDevices != nil) {
        size = [_bluetoothDevices count];
    }
    
    _bluetoothSearchInProgress = false;
        
    BOOL sendBluetoothDeviceList = false;
    
    if(size > 0) {
        sendBluetoothDeviceList = true;
        [Teleport logInfo:@"LIST OF BLUETOOTH DEVICES COMMUNICATED"];
    } else {
        [Teleport logInfo:@"EMPTY BLUETOOTH DEVICES COMMUNICATED"];
    }
    
    if(![_clearentVP3300 isConnected] && !_clearentDelegate.clearentConnection.searchBluetooth) {
        if(_retriedBluetoothWhenNoDevicesFound) {
            [Teleport logInfo:@"disableBluetoothSearch retriedBluetoothWhenNoDevicesFound failed."];
            if(size == 0) {
                [Teleport logInfo:@"disableBluetoothSearch retriedBluetoothWhenNoDevicesFound. No devices found."];
            }
            if(!_clearentDelegate.clearentConnection.connectToFirstBluetoothFound) {
                [Teleport logInfo:@"disableBluetoothSearch retriedBluetoothWhenNoDevicesFound. Report only."];
            } else {
                [self sendBluetoothFeedback:BLUETOOTH_NOT_CONNECTED];
            }
        } else  {
            if(!_tryConnectWithSavedDeviceId) {
                if(size == 0) {
                    sendBluetoothDeviceList = false;
                    [Teleport logInfo:@"disableBluetoothSearch says it is not connected but no devices found. force disconnect and try again"];
                    [self retryBluetoothWhenNoDevicesFound];
                } else {
                    [Teleport logInfo:@"disableBluetoothSearch says it is not connected but devices found. force disconnect and try again"];
                    [self retryBluetoothWhenNoDevicesFound];
                }
            } else {
                [Teleport logInfo:@"disableBluetoothSearch saved blbuetooth not found. Clear bluetooth cache and start bluetooth connection again"];
                [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
                _tryConnectWithSavedDeviceId = false;
                sendBluetoothDeviceList = false;
                [self startConnection:_clearentDelegate.clearentConnection];
            }
        }
    } else if(size == 0) {
         if(_clearentDelegate.clearentConnection.searchBluetooth) {
             [Teleport logInfo:@"disableBluetoothSearch says it is connected but no devices found. handle this elsewhere"];
         }
    }
    
    if(sendBluetoothDeviceList) {
        [_clearentDelegate sendBluetoothDevices];
    }
    
    if(![_clearentVP3300 isConnected] && !_clearentDelegate.clearentConnection.searchBluetooth) {
        _previousConnectionFailed = true;
    } else {
        _previousConnectionFailed = false;
    }
    
}

- (void) sendBluetoothFeedback:(NSString*) message {
    
    [_clearentDelegate feedback:[[ClearentFeedback alloc] initBluetooth:message]];
    
}

//Readers are broadcasting but no devices come back in idtech callback. Forcing a disconnect and searching again
//fixes this. Just trying once should reset whatever the Idtech framework is doing.
- (void) retryBluetoothWhenNoDevicesFound {
    if(!_retriedBluetoothWhenNoDevicesFound) {
        [_clearentVP3300 device_disconnectBLE];
       // [self setInvalidSearchFriendlyName];
        [NSThread sleepForTimeInterval:0.5f];
        _foundDeviceWaitingToConnect = false;
        [self startConnection:_clearentDelegate.clearentConnection];
    }
    _retriedBluetoothWhenNoDevicesFound = true;
}

- (NSString*) getFirstBluetoothDeviceIdNotConnected {
    if(_bluetoothDevices != nil) {
        for (ClearentBluetoothDevice* clearentBluetoothDevice in _bluetoothDevices) {
            if(!clearentBluetoothDevice.connected) {
                [Teleport logInfo:[NSString stringWithFormat:@"Unconnected bluetooth Device Found %@", clearentBluetoothDevice.friendlyName]];
                return clearentBluetoothDevice.deviceId;
            }
        }
    }
    return nil;
}


- (void) disableBluetoothSearchTimer {
    if(bluetoothSearchDisableTimer != nil) {
        [bluetoothSearchDisableTimer fire];
    }
}

- (void) handleBluetoothDeviceFound:(NSString*) bluetoothDeviceFoundMessage {
        
    if(_foundDeviceWaitingToConnect) {
        return;
    }
    
    _searchingBluetoothDeviceId = [self extractDeviceIdFromIdTechBLEDeviceFoundMessage:bluetoothDeviceFoundMessage];
    _searchingBluetoothfriendlyName = [self extractFriendlyNameFromIdTechBLEDeviceFoundMessage:bluetoothDeviceFoundMessage];
    
    NSString *lastUsedBluetoothDeviceId = [ClearentCache getLastUsedBluetoothDeviceId];
    
    if(_clearentDelegate.clearentConnection != nil && _clearentDelegate.clearentConnection.searchBluetooth) {
        if([bluetoothDeviceFoundMessage containsString:@"IDTECH"]) {
            [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        }
    } else if (lastUsedBluetoothDeviceId != nil && [lastUsedBluetoothDeviceId isEqualToString:_searchingBluetoothDeviceId]) {

        [Teleport logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found by uuid %@", _searchingBluetoothfriendlyName]];
        
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
        [self recordFoundDeviceWaitingToConnect];
        
    } else if(_clearentDelegate.clearentConnection != nil
              && _clearentDelegate.clearentConnection.bluetoothDeviceId != nil
              && [_clearentDelegate.clearentConnection.bluetoothDeviceId isEqualToString:_searchingBluetoothDeviceId]) {
        
        [Teleport logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found by provided device uuid %@", _searchingBluetoothfriendlyName]];
               
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
               
        [self recordFoundDeviceWaitingToConnect];
        
    } else if(_findBluetoothFriendlyName != nil && [_searchingBluetoothfriendlyName isEqualToString:_findBluetoothFriendlyName]) {
    
        [Teleport logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found %@",_findBluetoothFriendlyName]];
        
        [self recordFoundDeviceWaitingToConnect];
        
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
    } else if([bluetoothDeviceFoundMessage containsString:@"IDTECH"]) {
        
        if(_clearentDelegate.clearentConnection != nil && _clearentDelegate.clearentConnection.connectToFirstBluetoothFound && !_tryConnectWithSavedDeviceId ) {
            
            if([_clearentDelegate.clearentConnection isDeviceKnown]) {
                if(_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
                   && ![_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]
                   && ([_searchingBluetoothfriendlyName containsString:_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber])) {
                    [Teleport logInfo:[NSString stringWithFormat:@"Connect to first bluetooth reader found with last 5 %@", _searchingBluetoothfriendlyName]];
                    [self recordFoundDeviceWaitingToConnect];
                } else if(_clearentDelegate.clearentConnection.fullFriendlyName != nil
                && ![_clearentDelegate.clearentConnection.fullFriendlyName isEqualToString:@""]
                && ([_searchingBluetoothfriendlyName containsString:_clearentDelegate.clearentConnection.fullFriendlyName])) {
                    [Teleport logInfo:[NSString stringWithFormat:@"Connect to first bluetooth reader found with friendly name %@", _searchingBluetoothfriendlyName]];
                    [self recordFoundDeviceWaitingToConnect];
                }
            } else {
                [Teleport logInfo:[NSString stringWithFormat:@"Connect to first bluetooth reader found when device is not known %@", _searchingBluetoothfriendlyName]];
                [self recordFoundDeviceWaitingToConnect];
            }
            
        }
        
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
    } else {
        
        [Teleport logInfo:[NSString stringWithFormat:@"Found NON IDTECH bluetooth devices %@", _searchingBluetoothfriendlyName]];
        
    }
}

- (void) recordFoundDeviceWaitingToConnect {
    self.connectingWithBluetoothfriendlyName = _searchingBluetoothfriendlyName;
    [_clearentVP3300 device_setBLEFriendlyName:self.connectingWithBluetoothfriendlyName];
    self.connectingWithBluetoothDeviceId = _searchingBluetoothDeviceId;
    _foundDeviceWaitingToConnect = true;
}

- (void) resetBluetoothSearch {
    
    self.bluetoothSearchInProgress = FALSE;
    
}

- (NSString*) extractDeviceIdFromIdTechBLEDeviceFoundMessage: (NSString*) idTechBLEDeviceFoundMessage {
    
    NSArray *components = [idTechBLEDeviceFoundMessage componentsSeparatedByString:@"("];
    NSArray *uuidComponents = [components.lastObject componentsSeparatedByString:@")"];
    
    return uuidComponents.firstObject;
}

- (NSString*) extractFriendlyNameFromIdTechBLEDeviceFoundMessage: (NSString*) idTechBLEDeviceFoundMessage {
    
    NSRange r1 = [idTechBLEDeviceFoundMessage rangeOfString:@"BLE DEVICE FOUND: "];
    NSRange r2 = [idTechBLEDeviceFoundMessage rangeOfString:@" ("];
    NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
    
    return [idTechBLEDeviceFoundMessage substringWithRange:rSub];
    
}

- (void) recordFoundBluetoothDevice: (NSString*) friendlyName deviceId:(NSString*) deviceId {
    
    BOOL found = FALSE;
    
    for (ClearentBluetoothDevice* clearentBluetoothDevice in _bluetoothDevices) {
        
        if([clearentBluetoothDevice.friendlyName isEqualToString:friendlyName]) {
            found = TRUE;
        }
        
    }
    
    if(!found) {
        
        ClearentBluetoothDevice *clearentBluetoothDevice = [[ClearentBluetoothDevice alloc] init];
        clearentBluetoothDevice.friendlyName = friendlyName;
        clearentBluetoothDevice.deviceId = deviceId;
        clearentBluetoothDevice.connected = false;
        [_bluetoothDevices addObject:clearentBluetoothDevice];
        
    }

}

- (void) recordBluetoothDeviceAsConnected {
    
    if([[IDT_VP3300 sharedController] isConnected] && _connectingWithBluetoothDeviceId != nil && _connectingWithBluetoothfriendlyName != nil) {
        
        bool found = false;
        
        for (ClearentBluetoothDevice* clearentBluetoothDevice in _bluetoothDevices) {
            if([clearentBluetoothDevice.friendlyName isEqualToString:_connectingWithBluetoothfriendlyName]) {
                
                NSUUID *connectedNSUUID = [[IDT_VP3300 sharedController] device_connectedBLEDevice];
                
                if(connectedNSUUID != nil) {
                    NSString *uuid = [connectedNSUUID UUIDString];
                    if(uuid != nil && [uuid isEqualToString:clearentBluetoothDevice.deviceId]) {
                        [ClearentCache cacheLastUsedBluetoothDevice: clearentBluetoothDevice.deviceId bluetoothFriendlyName: clearentBluetoothDevice.friendlyName];
                        clearentBluetoothDevice.connected = true;

                    }
                }
              
                found = true;
            }
        }
        
    }
    
}

- (BOOL) isConfigurationRequested {
    
    if(_clearentDelegate.autoConfiguration || _clearentDelegate.contactlessAutoConfiguration) {
        return true;
    }
    
    return false;
}

- (void) startBluetoothSearchWithScannedDevice:(NSString *) uuid bluetoothFriendlyName:(NSString*) bluetoothFriendlyName {
    
    if (self.bluetoothSearchInProgress && _connectingWithBluetoothDeviceId != nil && [_connectingWithBluetoothDeviceId isEqualToString:uuid]) {
        return;
    }

    self.connectingWithBluetoothfriendlyName = bluetoothFriendlyName;
    self.connectingWithBluetoothDeviceId = uuid;
    self.bluetoothSearchInProgress = TRUE;
    
    NSUUID *val = nil;
    if (uuid.length > 0) {
        val = [[NSUUID alloc] initWithUUIDString:uuid];
    } else {
        [_clearentVP3300 device_setBLEFriendlyName:self.connectingWithBluetoothfriendlyName];
    }
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [Teleport logInfo:@"BLUETOOTH SCAN FAILED USING DISCOVERED DEVICE ID"];
    }
    
}

- (void) startBluetoothSearchWithUUID:(NSString *) uuid {
    
    [_clearentVP3300 device_setBLEFriendlyName:nil];
    
    NSUUID *val = nil;
    if (uuid.length > 0) {
        val = [[NSUUID alloc] initWithUUIDString:uuid];
    }
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [Teleport logInfo:@"Clearent_VP3300:startBluetoothSearchWithUUID device_enableBLEDeviceSearch bad return code but might have still connected"];
    }
}

- (void) startBluetoothSearchWithFullFriendlyName:(NSString*) fullFriendlyName {
    
    _findBluetoothFriendlyName = fullFriendlyName;
    [_clearentVP3300 device_setBLEFriendlyName:_findBluetoothFriendlyName];
    
    NSUUID* val = nil;
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [Teleport logInfo:@"BLUETOOTH SCAN FAILED WITH FULL FRIENDLY NAME"];
    }
    
}

- (void) startBlindBluetoothSearch {
    
    [self setInvalidSearchFriendlyName];
    
    NSUUID* val = nil;
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [Teleport logInfo:@"BLUETOOTH SCAN FAILED on BLIND SEARCH"];
    }
    
}

- (void) setInvalidSearchFriendlyName {
    _findBluetoothFriendlyName = nil;
    [_clearentVP3300 device_setBLEFriendlyName:nil];
}

@end
