//
//  ClearentConnection.h
//  ClearentIdtechIOSFramework
//
//  Created by David Higginbotham on 3/30/20.
//  Copyright © 2020 Clearent, L.L.C. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CLEARENT_CONNECTION_TYPE) {
    CLEARENT_BLUETOOTH = 0,
    CLEARENT_AUDIO_JACK = 1
};

typedef enum {
    CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_DEFAULT = 0,
    CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_60_MS = 1,
    CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_319_MS = 2,
    CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_760_MS = 3,
    CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL_1280_MS = 4
} CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL;

typedef NS_ENUM(NSUInteger, CLEARENT_READER_INTERFACE_MODE) {
    CLEARENT_READER_INTERFACE_3_IN_1 = 0,
    CLEARENT_READER_INTERFACE_2_IN_1 = 1
};

@protocol ClearentConnection <NSObject>

- (int) bluetoothMaximumScanInSeconds;
- (NSString*) lastFiveDigitsOfDeviceSerialNumber;
- (NSString*) fullFriendlyName;
- (NSString*) bluetoothDeviceId;
- (BOOL) connectToFirstBluetoothFound;
- (BOOL) searchBluetooth;
- (CLEARENT_CONNECTION_TYPE*) connectionType;
- (CLEARENT_READER_INTERFACE_MODE*) readerInterfaceMode;
- (NSString*) createLogMessage;
- (BOOL) isDeviceKnown;
//- (CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL*) bluetoothAdvertisingInterval;

- (instancetype) initAudioJack;
- (instancetype) initBluetoothSearch;
- (instancetype) initBluetoothSearchWithMaxScanTime: (int) bluetoothMaximumScanInSeconds;
- (instancetype) initBluetoothFirstConnect;
- (instancetype) initBluetoothWithLast5: (NSString*) lastFiveDigitsOfDeviceSerialNumber;
- (instancetype) initBluetoothWithFriendlyName: (NSString*) fullFriendlyName;
- (instancetype) initBluetoothWithDeviceUUID: (NSString*) deviceUUID;

@end

@interface ClearentConnection: NSObject <ClearentConnection>

@property (nonatomic) int bluetoothMaximumScanInSeconds;
@property (nonatomic) NSString *lastFiveDigitsOfDeviceSerialNumber;
@property (nonatomic) NSString *fullFriendlyName;
@property (nonatomic) NSString *bluetoothDeviceId;
@property (nonatomic) BOOL connectToFirstBluetoothFound;
@property (nonatomic) BOOL searchBluetooth;
@property (nonatomic) CLEARENT_CONNECTION_TYPE connectionType;
@property (nonatomic) CLEARENT_READER_INTERFACE_MODE readerInterfaceMode;
//@property (nonatomic) CLEARENT_BLUETOOTH_ADVERTISING_INTERVAL bluetoothAdvertisingInterval;

- (NSString*) createLogMessage;
- (BOOL) isDeviceKnown;
+ (NSString*) createFullIdTechFriendlyName:(NSString*) lastFiveDigitsOfDeviceSerialNumber;

- (instancetype) initAudioJack;
- (instancetype) initBluetoothSearch;
- (instancetype) initBluetoothSearchWithMaxScanTime: (int) bluetoothMaximumScanInSeconds;
- (instancetype) initBluetoothFirstConnect;
- (instancetype) initBluetoothWithLast5: (NSString*) lastFiveDigitsOfDeviceSerialNumber;
- (instancetype) initBluetoothWithFriendlyName: (NSString*) fullFriendlyName;
- (instancetype) initBluetoothWithDeviceUUID: (NSString*) deviceUUID;

+ (BOOL) isNewConnectionRequest:(ClearentConnection*) currentConnection connectionRequest:(ClearentConnection*) clearentConnection;

@end
