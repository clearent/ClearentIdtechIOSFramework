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
#import "ClearentLumberjack.h"
#import "ClearentConnection.h"
#import "ClearentDelegate.h"
#import "Clearent_VP3300.h"
#import "ClearentBluetoothDevice.h"
#import <IDTech/IDTUtility.h>
#import <IDTech/IDT_VP3300.h>

@implementation ClearentDeviceConnector

static NSString *const INVALID_FRIENDLY_NAME = @"INVALID_FRIENDLY_NAME";

NSTimer *bluetoothSearchDisableTimer;

- (instancetype) init: (ClearentDelegate*) clearentDelegate clearentVP3300:(Clearent_VP3300*) clearentVP3300 {
    
    self = [super init];
    
    if (self) {
        _clearentDelegate = clearentDelegate;
        _clearentVP3300 = clearentVP3300;
        _tryConnectWithSavedDeviceId = false;
        _bluetoothDevices = [[NSMutableArray<ClearentBluetoothDevice> alloc] init];
    }
    
    return self;
}

- (void) resetConnection {
    
    [_bluetoothDevices removeAllObjects];
    
    [self resetBluetoothAfterConnected];
    
}

- (void) resetBluetoothAfterConnected {
    
    _tryConnectWithSavedDeviceId = false;
    _searchingBluetoothfriendlyName = nil;
    _searchingBluetoothDeviceId = nil;
    _connectingWithBluetoothfriendlyName = nil;
    _connectingWithBluetoothDeviceId = nil;
    _foundDeviceWaitingToConnect = false;
    _findBluetoothFriendlyName = nil;
    
}

- (void) startConnection: (ClearentConnection*) clearentConnection {
    
    if(clearentConnection == nil) {
        [_clearentDelegate deviceMessage:CLEARENT_CONNECTION_PROPERTIES_REQUIRED];
        return;
    }
    
    if(clearentConnection.connectionType == CLEARENT_AUDIO_JACK && ![_clearentVP3300 device_isAudioReaderConnected]) {
        [_clearentDelegate deviceMessage:CLEARENT_AUDIO_JACK_DISCONNECTED];
        return;
    }
    
    [self resetConnection];
    
    [_clearentDelegate.idTechSharedInstance device_setBLEFriendlyName:nil];
    
    [self disconnectBluetoothOnChangedState:clearentConnection];
    
    if(![_clearentVP3300 isConnected]) {
        [ClearentLumberjack logInfo:@"startConnection. Device not connected"];
        if(clearentConnection.connectionType == CLEARENT_AUDIO_JACK) {
            [self communicateAudioJackState];
        } else if(clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
            [ClearentLumberjack logInfo:@"startConnection. device_setBLEFriendlyName to nil"];
            [self startBluetoothSearch: clearentConnection];
        }
    } else {
        [ClearentLumberjack logInfo:@"startConnection. connected,communicateConnectionState"];
        [self communicateConnectionState:clearentConnection];
    }
}

- (void) communicateConnectionState:(ClearentConnection*) clearentConnection {
    
    if(clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        [self communicateBluetoothState];
    } else {
        [self communicateAudioJackState];
    }
    
}

- (void) communicateBluetoothState {
    NSString *bleFriendlyName = [_clearentVP3300 device_getBLEFriendlyName];
    if(bleFriendlyName != nil && ![bleFriendlyName isEqualToString:@""]) {
        NSString *logMessage = [NSString stringWithFormat:@"CONNECTED : %@", bleFriendlyName];
        [self sendBluetoothFeedback:logMessage];
    } else {
        [self sendBluetoothFeedback:@"CONNECTED"];
    }
}

- (void) communicateAudioJackState {
    
    if([_clearentVP3300 device_isAudioReaderConnected]) {
        [_clearentDelegate deviceMessage:CLEARENT_AUDIO_JACK_CONNECTED];
    } else {
        [_clearentDelegate deviceMessage:CLEARENT_AUDIO_JACK_DISCONNECTED];
    }
    
}

- (void) disconnectBluetoothOnChangedState:(ClearentConnection*) clearentConnection  {
    
    if([_clearentVP3300 device_isAudioReaderConnected] && clearentConnection.connectionType == CLEARENT_AUDIO_JACK) {
        
        [ClearentLumberjack logInfo:@"disconnectBluetooth AUDIO JACK ALREADY CONNECTED"];
        
    } else if([self isNewConnectionRequest:_clearentDelegate.clearentConnection connectionRequest: clearentConnection]
              && (clearentConnection.connectionType == CLEARENT_BLUETOOTH || _clearentDelegate.clearentConnection.connectionType == CLEARENT_BLUETOOTH)) {
        
        if([_clearentVP3300 isConnected]) {
            [ClearentLumberjack logInfo:@"disconnectBluetoothOnChangedState. Device is connected but a new connection request is provided. Disconnect bluetooth"];
        } else {
            [ClearentLumberjack logInfo:@"disconnectBluetoothOnChangedState. Device is not connected but a new connection request is provided. Force a disconnect bluetooth"];
        }
        
        [ClearentCache clearReaderProfile];
        
        [self disconnectBluetooth];
        
        if(![_clearentVP3300 device_isAudioReaderConnected] && clearentConnection.connectionType == CLEARENT_AUDIO_JACK) {
            [self sendBluetoothFeedback:CLEARENT_DISCONNECTING_BLUETOOTH_PLUGIN_AUDIO_JACK];
        }
        
    } else {
        [ClearentLumberjack logInfo:@"disconnectBluetoothOnChangedState: Same connection request"];
    }
}

//if this works we need to use NSUSErDefaults to save a flag so it doesnt adjust every time.
- (void) adjustBluetoothAdvertisingInterval {
    
    if(_clearentDelegate.clearentConnection != nil && [_clearentVP3300 isConnected]) {

        NSString *firmwareVersion = [_clearentDelegate getFirmwareVersion];

        if(firmwareVersion != nil
           && ([firmwareVersion isEqualToString:CLEARENT_INVALID_FIRMWARE_VERSION] ||
               [firmwareVersion isEqualToString:@"VP3300 Bluetooth NEO v1.01.151"] ||
               [firmwareVersion isEqualToString:@"VP3300 Bluetooth NEO v1.01.090"]
                 || [firmwareVersion isEqualToString:@"VP3300 Audio Jack NEO v1.01.055"]
                 || [firmwareVersion isEqualToString:@"VP3300 Audio Jack NEO v1.01.064"])) {
                  [ClearentLumberjack logInfo:[NSString stringWithFormat:@"skipping adjustBluetoothAdvertisingInterval for firmware version - %@", firmwareVersion]];
            return;
        } else {
            [ClearentLumberjack logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval: firmware version - %@", firmwareVersion]];
        }

        //NSString *advertisingIntervalHex = [self getAdvertisingIntervalInHex:_clearentDelegate.clearentConnection.bluetoothAdvertisingInterval];
        NSString *advertisingIntervalHex = @"";
        NSString *updateAdvertisingIntervalStr = [NSString stringWithFormat:@"DFED6C02%@", advertisingIntervalHex];

        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval update %@", updateAdvertisingIntervalStr]];

        NSData *configData = [IDTUtility hexToData:updateAdvertisingIntervalStr];
        
        bool adjusted = false;
        
        for(int i = 0; i < 5; i++ ) {
            
            if(!adjusted) {
                
                [NSThread sleepForTimeInterval:0.5f];
                
                RETURN_CODE ctls_setTerminalDataRt = [[IDT_VP3300 sharedController] ctls_setTerminalData:configData];

                if (RETURN_CODE_DO_SUCCESS == ctls_setTerminalDataRt) {
                    adjusted = true;
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval updated"]];
                    break;
                } else {
                    NSString *errorResponse = [[IDT_VP3300 sharedController] device_getResponseCodeString:ctls_setTerminalDataRt];
                    [_clearentDelegate deviceMessage:errorResponse];
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"adjustBluetoothAdvertisingInterval failed set advertising interval. error %@", errorResponse]];
                }
            }
        }
       
    } else {
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"reader is not connected or no connection props. skip updating advertising interval"]];
    }
    
}

- (NSString*) getAdvertisingIntervalInHex: (CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL) bluetoothAdvertisingInterval {
    
    NSString *advIntHex;

    switch(bluetoothAdvertisingInterval){
        case CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT:
            advIntHex = @"003C";
             break;
        case CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_60_MS:
            advIntHex = @"003C";
             break;
        case CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_319_MS:
            advIntHex = @"013F";
             break;
        case CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_760_MS:
            advIntHex = @"02F8";
             break;
        case CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_1280_MS:
            advIntHex = @"0500";
        break;
    default:
            advIntHex = @"003C";
        break;
    }

    return advIntHex;
}


- (BOOL) isNewConnectionRequest:(ClearentConnection*) currentConnection connectionRequest:(ClearentConnection*) connectionRequest {
    
    if([ClearentConnection isNewConnectionRequest:currentConnection connectionRequest:connectionRequest]) {
         return YES;
    }
    
    return NO;
}

- (void) startBluetoothSearch: (ClearentConnection*) clearentConnection {
    
    if(clearentConnection == nil) {
        [_clearentDelegate deviceMessage:CLEARENT_CONNECTION_PROPERTIES_REQUIRED];
        return;
    }
    
    if([_clearentVP3300 isConnected] && !clearentConnection.searchBluetooth && clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        [self communicateBluetoothState];
        return;
    }
    
    if(clearentConnection.searchBluetooth) {
        [self sendBluetoothFeedback:CLEARENT_BLUETOOTH_SEARCH];
    };
     
    [_bluetoothDevices removeAllObjects];
   
    if(clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        
        [self updateConnection:clearentConnection];
        
        [self pickBluetoothSearchAndStart:clearentConnection];
        
    } else {
        
        [self communicateConnectionType:clearentConnection.connectionType];
        
    }
}

//11-06-21 Now we check the cache LAST. The caller has told us they have the information for the search.
//let's always check the incoming request first and fallback to the cache. This should help in scenarios
//where the cache might not be reliable.
- (void) pickBluetoothSearchAndStart : (ClearentConnection*) clearentConnection {

    NSString *lastUsedBluetoothDeviceId = [ClearentCache getLastUsedBluetoothDeviceId];
    
    [self disableBluetoothSearchInFuture:clearentConnection];
    
    if(clearentConnection.searchBluetooth) {
        
        [self startBlindBluetoothSearch];
        
    } else if(clearentConnection.bluetoothDeviceId != nil && ![clearentConnection.bluetoothDeviceId isEqualToString:@""]) {
        
        [self startBluetoothSearchWithUUID:clearentConnection.bluetoothDeviceId];
        
    } else if(clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil && ![clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]) {
        
        NSString *fullIdTechFriendlyName = [ClearentConnection createFullIdTechFriendlyName:clearentConnection.lastFiveDigitsOfDeviceSerialNumber];
        [self startBluetoothSearchWithFullFriendlyName:fullIdTechFriendlyName];
        
    } else if(clearentConnection.fullFriendlyName != nil && ![clearentConnection.fullFriendlyName isEqualToString:@""]) {
        
        [self startBluetoothSearchWithFullFriendlyName:clearentConnection.fullFriendlyName ];
        
    } else if(lastUsedBluetoothDeviceId != nil && ![lastUsedBluetoothDeviceId isEqualToString:@""]) {
        
        [self startBluetoothSearchWithUUID:lastUsedBluetoothDeviceId];
        
    } else {
        
        [self startBlindBluetoothSearch];
        
    }
}

- (void) communicateConnectionType: (CLEARENT_CONNECTION_TYPE) connectionType {
    if(connectionType == CLEARENT_BLUETOOTH) {
        [self sendBluetoothFeedback:CLEARENT_CONNECTION_TYPE_REQUIRED];
    } else {
        [_clearentDelegate deviceMessage:CLEARENT_CONNECTION_TYPE_REQUIRED];
    }
}

- (void) disableBluetoothSearchInFuture: (ClearentConnection*) clearentConnection {
    
    [self disableBluetoothSearchAfterPeriod:clearentConnection.bluetoothMaximumScanInSeconds];
}

-(void) updateConnection: (ClearentConnection*) clearentConnection {
    [self clearSavedDeviceId:clearentConnection];
    [_clearentDelegate setClearentConnection:clearentConnection];
}

- (void) clearSavedDeviceId: (ClearentConnection*) clearentConnection {
    
    if(clearentConnection != nil && clearentConnection.connectionType == CLEARENT_BLUETOOTH) {
        
        NSString *lastUsedFriendlyName = [ClearentCache getLastUsedBluetoothFriendlyName];
        NSString *lastUsedDeviceId = [ClearentCache getLastUsedBluetoothDeviceId];
    
        if(lastUsedFriendlyName != nil) {
            
            if(clearentConnection.searchBluetooth) {
                
                [self clearSavedBluetoothCache];
                
            } else if ([clearentConnection isDeviceKnown]) {
                
                if(lastUsedDeviceId != nil && clearentConnection.bluetoothDeviceId != nil
                   && ![clearentConnection.bluetoothDeviceId isEqualToString:@""]
                   && [clearentConnection.bluetoothDeviceId isEqualToString:lastUsedDeviceId]) {
                    
                      [ClearentLumberjack logInfo:@"BLUETOOTH DEVICE ID MATCHES SAVED DEVICE UUID"];
                    
                } else if(clearentConnection.fullFriendlyName != nil
                   && ![clearentConnection.fullFriendlyName isEqualToString:@""]
                   && [clearentConnection.fullFriendlyName isEqualToString:lastUsedFriendlyName]) {
                    
                      [ClearentLumberjack logInfo:@"BLUETOOTH FRIENDLY NAME MATCHES SAVED FRIENDLY NAME"];
                    
                } else if(clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
                    && ![clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]
                    && [lastUsedFriendlyName containsString:clearentConnection.lastFiveDigitsOfDeviceSerialNumber]) {
                    
                       [ClearentLumberjack logInfo:@"SAVED BLUETOOTH FRIENDLY NAME CONTAINS PROVIDED LAST 5 DIGITS OF DSN"];
                    
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
    
    [ClearentLumberjack logInfo:@"clearSavedDeviceId CLEAR SAVED BLUETOOTH DEVICE FROM CACHE"];
    
    [ClearentCache cacheLastUsedBluetoothDevice:nil bluetoothFriendlyName:nil];
    
    [self setInvalidSearchFriendlyName];
        
    if([_clearentVP3300 isConnected]) {
        
        [ClearentLumberjack logInfo:@"clearSavedBluetoothCache. Disconnect bluetooth"];
        [_clearentVP3300 device_disconnectBLE];
        [NSThread sleepForTimeInterval:0.5f];
        
    }
    
}

- (void) disconnectBluetooth {
    
    [_clearentVP3300 device_disconnectBLE];
    [NSThread sleepForTimeInterval:0.5f];
    
}

-(void) disableBluetoothSearchAfterPeriod:(int) bluetoothMaximumScanInSeconds {
    
    if (bluetoothSearchDisableTimer != nil) {
        [bluetoothSearchDisableTimer invalidate];
        bluetoothSearchDisableTimer = nil;
        [NSThread sleepForTimeInterval:0.2f];
    }

    // Timers require an active run loop which is not always available on background queues
    dispatch_async(dispatch_get_main_queue(), ^{
        bluetoothSearchDisableTimer = [NSTimer scheduledTimerWithTimeInterval:bluetoothMaximumScanInSeconds target:self selector:@selector(disableBluetoothSearch:) userInfo:nil repeats:false];
    });
}

-(void) disableBluetoothSearch:(id) sender {
   //TODO do we need to cancel search if searchBluetooth is not  enabled ?
    if(_clearentDelegate.clearentConnection.searchBluetooth) {
    
        [ClearentLumberjack logInfo:@"disableBluetoothSearch: device_disableBLEDeviceSearch only when in search mode"];
        
        RETURN_CODE rt = [_clearentVP3300 device_disableBLEDeviceSearch];

    }
   
    NSUInteger size = 0;
    
    if(_bluetoothDevices != nil) {
        size = [_bluetoothDevices count];
    } else {
        [ClearentLumberjack logInfo:@"disableBluetoothSearch: _bluetoothDevices is nil"];
    }
        
    if(size > 0) {
        [ClearentLumberjack logInfo:@"disableBluetoothSearch: BLUETOOTH DEVICES FOUND"];
    } else {
        [ClearentLumberjack logInfo:@"disableBluetoothSearch: NO BLUETOOTH DEVICES FOUND"];
    }
    
    if(![_clearentVP3300 isConnected] && !_clearentDelegate.clearentConnection.searchBluetooth) {
        [ClearentLumberjack logInfo:@"disableBluetoothSearch:CLEARENT_BLUETOOTH_DISCONNECTED"];
        [self sendBluetoothFeedback:CLEARENT_BLUETOOTH_DISCONNECTED];
    }
    
    //Special case for idtech framework.
    //Readers are broadcasting but no devices come back in idtech callback. Forcing a disconnect and searching again
    //fixes this. We used to try one more time but then the client is left wondering why it's taking longer than the configured 10 seconds
    //maximum search. Let's compromise and force the disconnect now and make them retry.
    
    //11-06-21 Let's stop doing this and see if the new IDTech framework is better.
//    if(size == 0 || ![_clearentVP3300 isConnected]) {
//        [ClearentLumberjack logInfo:@"disableBluetoothSearch:no devices found and device is not connecrted. force disconnect"];
//        [_clearentVP3300 device_disconnectBLE];
//    }
        
    if(_clearentDelegate.clearentConnection.searchBluetooth) {
        [ClearentLumberjack logInfo:@"disableBluetoothSearch:sendBluetoothDevices"];
        [_clearentDelegate sendBluetoothDevices];
    }

}

- (void) sendBluetoothFeedback:(NSString*) message {
    
    [_clearentDelegate feedback:[[ClearentFeedback alloc] initBluetooth:message]];
    
}

//11-06-21 Flipped the logic around to always check the incoming connection request first before relying on the cached information.
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
        
    } else if(_clearentDelegate.clearentConnection != nil
              && _clearentDelegate.clearentConnection.bluetoothDeviceId != nil
              && [_clearentDelegate.clearentConnection.bluetoothDeviceId isEqualToString:_searchingBluetoothDeviceId]) {
        
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found by provided device uuid %@", _searchingBluetoothfriendlyName]];
               
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
               
        [self recordFoundDeviceWaitingToConnect];
        
    } else if(_clearentDelegate.clearentConnection != nil
              && _clearentDelegate.clearentConnection.fullFriendlyName != nil
              && [_searchingBluetoothfriendlyName isEqualToString:_clearentDelegate.clearentConnection.fullFriendlyName]) {
           
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found %@",_searchingBluetoothfriendlyName]];
            
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
        [self recordFoundDeviceWaitingToConnect];
        
    } else if(_findBluetoothFriendlyName != nil && [_searchingBluetoothfriendlyName isEqualToString:_findBluetoothFriendlyName]) {
    
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found %@",_findBluetoothFriendlyName]];
        
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
        [self recordFoundDeviceWaitingToConnect];
        
    } else if (lastUsedBluetoothDeviceId != nil && [lastUsedBluetoothDeviceId isEqualToString:_searchingBluetoothDeviceId]) {

        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Bluetooth friendly name found by uuid %@", _searchingBluetoothfriendlyName]];
        
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
        [self recordFoundDeviceWaitingToConnect];
    
        
    } else if([bluetoothDeviceFoundMessage containsString:@"IDTECH"]) {
        
        if(_clearentDelegate.clearentConnection != nil && _clearentDelegate.clearentConnection.connectToFirstBluetoothFound && !_tryConnectWithSavedDeviceId ) {
            
            if([_clearentDelegate.clearentConnection isDeviceKnown]) {
                if(_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber != nil
                   && ![_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber isEqualToString:@""]
                   && ([_searchingBluetoothfriendlyName containsString:_clearentDelegate.clearentConnection.lastFiveDigitsOfDeviceSerialNumber])) {
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Connect to first bluetooth reader found with last 5 %@", _searchingBluetoothfriendlyName]];
                    [self recordFoundDeviceWaitingToConnect];
                } else if(_clearentDelegate.clearentConnection.fullFriendlyName != nil
                && ![_clearentDelegate.clearentConnection.fullFriendlyName isEqualToString:@""]
                && ([_searchingBluetoothfriendlyName containsString:_clearentDelegate.clearentConnection.fullFriendlyName])) {
                    [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Connect to first bluetooth reader found with friendly name %@", _searchingBluetoothfriendlyName]];
                    [self recordFoundDeviceWaitingToConnect];
                }
            } else {
                [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Connect to first bluetooth reader found when device is not known %@", _searchingBluetoothfriendlyName]];
                [self recordFoundDeviceWaitingToConnect];
            }
            
        }
        
        [self recordFoundBluetoothDevice:_searchingBluetoothfriendlyName deviceId:_searchingBluetoothDeviceId];
        
    } else {
        
        [ClearentLumberjack logInfo:[NSString stringWithFormat:@"Found NON IDTECH bluetooth devices %@", _searchingBluetoothfriendlyName]];
        
    }
}

- (void) recordFoundDeviceWaitingToConnect {
    self.connectingWithBluetoothfriendlyName = _searchingBluetoothfriendlyName;
    [_clearentVP3300 device_setBLEFriendlyName:self.connectingWithBluetoothfriendlyName];
    self.connectingWithBluetoothDeviceId = _searchingBluetoothDeviceId;
    _foundDeviceWaitingToConnect = true;
}

- (void) resetBluetoothSearch {
    
    
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
    
    if([_clearentDelegate.idTechSharedInstance isConnected] && _connectingWithBluetoothDeviceId != nil && _connectingWithBluetoothfriendlyName != nil) {
        
        bool found = false;
        
        for (ClearentBluetoothDevice* clearentBluetoothDevice in _bluetoothDevices) {
            if([clearentBluetoothDevice.friendlyName isEqualToString:_connectingWithBluetoothfriendlyName]) {
                
                NSUUID *connectedNSUUID = [_clearentDelegate.idTechSharedInstance device_connectedBLEDevice];
                
                if(connectedNSUUID != nil) {
                    NSString *uuid = [connectedNSUUID UUIDString];
                    if(uuid != nil && [uuid isEqualToString:clearentBluetoothDevice.deviceId]) {
                        [ClearentCache cacheLastUsedBluetoothDevice: clearentBluetoothDevice.deviceId bluetoothFriendlyName: clearentBluetoothDevice.friendlyName];
                        clearentBluetoothDevice.connected = true;

                    } else {
                        [ClearentLumberjack logInfo:@"recordBluetoothDeviceAsConnected:connectedNSUUID does not match deviceid"];
                    }
                } else {
                    [ClearentLumberjack logInfo:@"recordBluetoothDeviceAsConnected:connectedNSUUID nil"];
                }
              
                found = true;
            }
        }
        if(!found) {
            [ClearentLumberjack logInfo:@"recordBluetoothDeviceAsConnected:failed to find in device list"];
        }
    } else {
        
        [ClearentLumberjack logInfo:@"recordBluetoothDeviceAsConnected:failed to record ble as connected"];
        
    }
    
}

- (BOOL) isConfigurationRequested {
    
    if(_clearentDelegate.autoConfiguration || _clearentDelegate.contactlessAutoConfiguration) {
        return true;
    }
    
    return false;
}

- (void) startBluetoothSearchWithUUID:(NSString *) uuid {
    [ClearentLumberjack logInfo:@"startBluetoothSearchWithUUID"];
    [_clearentVP3300 device_setBLEFriendlyName:nil];
    
    NSUUID *val = nil;
    if (uuid.length > 0) {
        val = [[NSUUID alloc] initWithUUIDString:uuid];
    }
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [ClearentLumberjack logInfo:@"Clearent_VP3300:startBluetoothSearchWithUUID device_enableBLEDeviceSearch bad return code but might have still connected"];
    }
}

- (void) startBluetoothSearchWithFullFriendlyName:(NSString*) fullFriendlyName {
    [ClearentLumberjack logInfo:@"startBluetoothSearchWithFullFriendlyName"];
    _findBluetoothFriendlyName = fullFriendlyName;
    [_clearentVP3300 device_setBLEFriendlyName:_findBluetoothFriendlyName];
    
    NSUUID* val = nil;
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [ClearentLumberjack logInfo:@"BLUETOOTH SCAN FAILED WITH FULL FRIENDLY NAME"];
    }
    //TODO
    //NSString* SPS_SERVICE_3300 =  @"1820";
    //[[IDT_VP3300 sharedController] scanForBLEDevices:2.0 serviceUUIDs:@[[CBUUID UUIDWithString:SPS_SERVICE_3300]/] options:nil];
    
}

- (void) startBlindBluetoothSearch {
    
    [ClearentLumberjack logInfo:@"startBlindBluetoothSearch"];
    
    [self setInvalidSearchFriendlyName];
    
    NSUUID* val = nil;
    
    bool device_enableBLEDeviceSearchReturnCode = [_clearentVP3300 device_enableBLEDeviceSearch:val];
    
    if(!device_enableBLEDeviceSearchReturnCode) {
        [ClearentLumberjack logInfo:@"BLUETOOTH SCAN FAILED on BLIND SEARCH"];
    }
    
}

- (void) setInvalidSearchFriendlyName {
    [ClearentLumberjack logInfo:@"setInvalidSearchFriendlyName"];
    _findBluetoothFriendlyName = nil;
    [_clearentVP3300 device_setBLEFriendlyName:nil];
}

@end
