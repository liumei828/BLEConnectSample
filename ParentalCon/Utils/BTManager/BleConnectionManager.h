//
//  CaptureManager.h
//  LifeFlow
//
//  Created by Macmini on 10/26/17.
//  Copyright © 2017 CULabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTManager.h"
#import "BLESimulator.h"

typedef enum {
    NOT_CONNECTED = 0,
    CONNECTING,
    CONNECTED
} ConnectionStatus;

@protocol BleConnectionDelegate
@optional
- (void) connecting;
- (void) connected;
- (void) timeout;
- (void) failed;
- (void) disconnected;
- (void) connectionUpdated;
- (void) bleStateUpdated;
@end

@protocol BleDataDelegate <BleConnectionDelegate>
- (void) dataReceived: (PMVValue*) data;
@end

@interface BleConnectionManager: NSObject <BTManagerDelegate>
@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, assign) ConnectionStatus connectionStatus;
@property (nonatomic, strong) CBPeripheral* connectedDevice;

@property (nonatomic, assign) BOOL isCapturing;

@property (nonatomic, strong) NSMutableArray* discoveredDevices;

@property (nonatomic, strong) id<BleDataDelegate> dataReceiver;
@property (nonatomic, strong) NSMutableArray* bleConnectionObservers; //list of ble connection delegates

+ (instancetype)sharedManager;

- (void) connectToDevice: (CBPeripheral*) periperal;

- (void) saveDevice: (CBPeripheral*) peripheral;
- (void) deleteSavedDevices;
- (NSString*) savedDeviceUUID;

- (void) configure;
- (void) start;
- (void) startWithoutConnect;
- (void) startAutoConnect;
- (void) stopScan;

- (void) addConnectionObserver: (id<BleConnectionDelegate>) observer;
- (void) removeConnectionObserver: (id<BleConnectionDelegate>) observer;

- (void) unPair;

@end

