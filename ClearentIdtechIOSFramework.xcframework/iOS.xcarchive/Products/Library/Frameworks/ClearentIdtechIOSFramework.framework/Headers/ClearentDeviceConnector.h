//
//  ClearentDeviceConnector.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 4/2/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

@class ClearentDeviceConnector;
@class ClearentConnection;
@class ClearentDelegate;
@class Clearent_VP3300;
@class ClearentBluetoothDevice;

#import <Foundation/Foundation.h>

@protocol ClearentDeviceConnector <NSObject>

- (ClearentDelegate*) clearentDelegate;
- (Clearent_VP3300*) clearentVP3300;
- (void) resetConnection;
- (void) resetBluetoothAfterConnected;
- (void) startConnection:(ClearentConnection*) clearentConnection;
- (BOOL) previousConnectionFailed;
- (BOOL) retriedBluetoothWhenNoDevicesFound;
- (BOOL) tryConnectWithSavedDeviceId;
- (BOOL) foundDeviceWaitingToConnect;
- (NSString*) findBluetoothFriendlyName;
- (NSString*) searchingBluetoothfriendlyName;
- (NSString*) connectingWithBluetoothfriendlyName;
- (NSString*) connectingWithBluetoothDeviceId;
- (NSString*) searchingBluetoothDeviceId;
- (BOOL) waitingForAudioJackInsert;
- (NSMutableArray<ClearentBluetoothDevice*>*) bluetoothDevices;
- (void) handleBluetoothDeviceFound:(NSString*) bluetoothDeviceFoundMessage;
- (void) resetBluetoothSearch;
- (void) recordBluetoothDeviceAsConnected;
- (void) recordFoundBluetoothDevice: (NSString*) friendlyName deviceId:(NSString*) deviceId;
- (void) clearSavedDeviceId: (ClearentConnection*) clearentConnection;
//- (void) adjustBluetoothAdvertisingInterval;

@end

@interface ClearentDeviceConnector : NSObject <ClearentDeviceConnector>

@property (nonatomic) ClearentDelegate *clearentDelegate;
@property (nonatomic) Clearent_VP3300 *clearentVP3300;
@property (nonatomic) BOOL previousConnectionFailed;
@property (nonatomic) BOOL retriedBluetoothWhenNoDevicesFound;
@property (nonatomic) BOOL tryConnectWithSavedDeviceId;
@property (nonatomic) BOOL foundDeviceWaitingToConnect;
@property(nonatomic) NSString *findBluetoothFriendlyName;
@property(nonatomic) NSString *searchingBluetoothfriendlyName;
@property(nonatomic) NSString *connectingWithBluetoothfriendlyName;
@property(nonatomic) NSString *connectingWithBluetoothDeviceId;
@property(nonatomic) NSString *searchingBluetoothDeviceId;
@property(nonatomic) BOOL waitingForAudioJackInsert;
@property(nonatomic) NSMutableArray<ClearentBluetoothDevice*> *bluetoothDevices;

- (instancetype) init : (ClearentDelegate*) clearentDelegate clearentVP3300:(Clearent_VP3300*) clearentVP3300;

- (void) resetConnection;
- (void) resetBluetoothAfterConnected;
- (void) recordFoundBluetoothDevice: (NSString*) friendlyName deviceId:(NSString*) deviceId;
- (void) startConnection:(ClearentConnection*) clearentConnection;
- (BOOL) isNewConnectionRequest:(ClearentConnection*) currentConnection connectionRequest:(ClearentConnection*) connectionRequest;
- (void) handleBluetoothDeviceFound:(NSString*) bluetoothDeviceFoundMessage;
- (void) resetBluetoothSearch;
- (void) recordBluetoothDeviceAsConnected;
- (void) clearSavedDeviceId: (ClearentConnection*) clearentConnection;
//- (void) adjustBluetoothAdvertisingInterval;

- (void) startBluetoothSearchWithUUID:(NSString *) uuid;
- (void) startBluetoothSearchWithFullFriendlyName:(NSString*) fullFriendlyName;
- (void) startBlindBluetoothSearch;

- (NSString*) extractDeviceIdFromIdTechBLEDeviceFoundMessage: (NSString*) idTechBLEDeviceFoundMessage;
- (NSString*) extractFriendlyNameFromIdTechBLEDeviceFoundMessage: (NSString*) idTechBLEDeviceFoundMessage;


@end
