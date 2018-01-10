//
//  CaptureManager.m
//  LifeFlow
//
//  Created by Macmini on 10/26/17.
//  Copyright © 2017 CULabs. All rights reserved.
//

#import "BleConnectionManager.h"
#import "BTManager.h"
#import "UIManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface BleConnectionManager ()
@property (nonatomic, strong) BTManager* bleManager;
@property (nonatomic, assign) BOOL autoconnect;
@end

@implementation BleConnectionManager

+ (BleConnectionManager*) sharedManager {
    static BleConnectionManager* instance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        instance = [[BleConnectionManager alloc] init];
    });
    return instance;
}

- (void) configure {
    self.bleManager = [BTManager sharedManager];
    self.bleManager.delegate = self;
}

- (void) saveDevice: (CBPeripheral*) peripheral {
    NSString *uuidString = [[peripheral identifier] UUIDString];
    NSUserDefaults* standard = [NSUserDefaults standardUserDefaults];
    [standard setObject: uuidString forKey: @"SAVED_DEVICE_UUID"];
    [standard synchronize];
}

- (void) deleteSavedDevices {
    NSUserDefaults* standard = [NSUserDefaults standardUserDefaults];
    [standard removeObjectForKey: @"SAVED_DEVICE_UUID"];
    [standard synchronize];
}

- (NSString*) savedDeviceUUID {
    NSUserDefaults* standard = [NSUserDefaults standardUserDefaults];
    return [standard stringForKey: @"SAVED_DEVICE_UUID"];
}

- (BOOL) connected {
    return (self.connectedDevice != nil);
}

- (void) startAutoConnect {
    self.autoconnect = YES;
    [self start];
}

- (void) startWithoutConnect {
    self.autoconnect = NO;
    [self start];
}

- (void) stopScan {
    [SVProgressHUD dismiss];
    if (self.connectionStatus == CONNECTING) {
        self.connectionStatus = NOT_CONNECTED;
    }
    [self.bleManager stopScan];
}

- (void) start {
    if (_discoveredDevices == nil) {
        _discoveredDevices = [NSMutableArray array];
    }
    else {
        [self.discoveredDevices removeAllObjects];
    }
    
    if (!self.isReady) {
        [[UIManager sharedManager].activeViewController showAlert: @"Bluetooth is disabled." message: @"Please enable bluetooth on your iPhone."];
        return;
    }
    
    if (!self.connectedDevice) {
        [self.bleManager startScan];
        if (self.autoconnect) {
            [SVProgressHUD showWithStatus: @"Scanning..."];
            [self setLookingForHandleTimeout: 15];
        }
    }
    else {
        [self runObserverWith: @selector(connected)];
    }
}

- (void) unPair {
    if (self.connectedDevice) {
        [self.bleManager disconnectDevice: self.connectedDevice];
        self.connectedDevice = nil;
    }
    self.connectionStatus = NOT_CONNECTED;
    [self deleteSavedDevices];
}

#pragma mark UI
- (BaseViewController*) topViewController {
    return [UIManager sharedManager].activeViewController;
}

#pragma mark ConnectionObservers
- (void) addConnectionObserver: (id<BleConnectionDelegate>) observer {
    if (_bleConnectionObservers == nil) {
        _bleConnectionObservers = [NSMutableArray array];
    }
    [_bleConnectionObservers removeObject: observer]; //check and if already exist remove it.
    [_bleConnectionObservers addObject: observer];
}

- (void) removeConnectionObserver: (id<BleConnectionDelegate>) observer {
    [_bleConnectionObservers removeObject: observer]; //check and if already exist remove it.
}

- (void) setDataReceiver:(id<BleDataDelegate>)dataReceiver {
    _dataReceiver = dataReceiver;
    [self removeConnectionObserver: _dataReceiver];
    [self addConnectionObserver: dataReceiver];
}

- (void) runObserverWith: (SEL) selector {
    int count = self.bleConnectionObservers.count;
    for (int i=count-1; i>=0; i--) {
        NSObject<BleConnectionDelegate>* delegate = self.bleConnectionObservers[i];
        if ([delegate respondsToSelector: selector]) {
            [delegate performSelector: selector withObject: nil];
        }
        if ([delegate respondsToSelector: @selector(connectionUpdated)]) {
            [delegate connectionUpdated];
        }
    }
}

- (void) setIsReady:(BOOL)isReady {
    _isReady = isReady;
    if (!_isReady) {
        [[UIManager sharedManager].activeViewController showAlert: @"Bluetooth is disabled." message: @"Please enable bluetooth on your iPhone."];
    }
}

- (void) connectToDevice: (CBPeripheral*) periperal {
    [SVProgressHUD showWithStatus: @"Connecting..."];
    [_bleManager stopScan];
    [_bleManager connectDevice: periperal];
}

#pragma mark BTManager Delegate
- (void)onBTStateUpdated: (CBManagerState)state {
    if (state == CBManagerStatePoweredOn) {
        if (self.isReady == NO) {
            self.isReady = YES;
            
            NSString* savedDevice = [self savedDeviceUUID];
            if (savedDevice == nil) {
                [[self topViewController] showPairViewController: YES];
            }
            else {
                [self startAutoConnect];
            }
        }
    }
    else {
        self.isReady = NO;
    }
}

- (void)onDataReceived:(PMVValue*)value {
    if (self.isCapturing) {
        if (self.dataReceiver != nil) {
            [self.dataReceiver dataReceived: value];
        }
    }
}

- (void) setConnectedDevice:(CBPeripheral *)connectedDevice {
    [SVProgressHUD dismiss];
    _connectedDevice = connectedDevice;
    if (_connectedDevice != nil) {
        self.connectionStatus = CONNECTED;
        [self saveDevice: _connectedDevice];
        
        if (self.discoveredDevices) {
            [self.discoveredDevices removeAllObjects];
        }
    }
    else {
        self.connectionStatus = NOT_CONNECTED;
    }
}

- (void)onDiscoverDevice:(CBPeripheral*)device {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"Device discovered.. %@", [device getJumpRopeName]);
    
    [SVProgressHUD dismiss];
    
    if (self.autoconnect) {
        NSString* savedDevice = [self savedDeviceUUID];
        if (savedDevice != nil) {
            if ([savedDevice isEqualToString: [device.identifier UUIDString]]) {
                [self connectToDevice: device];
                return;
            }
        }
    }
    else {
//        NSArray* existing = [self.discoveredDevices filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"name == %@", device.name]];
//        if (existing != nil && existing.count > 0) {
//            return;
//        }
        
        [self.discoveredDevices addObject: device];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"NEW_DEVICE_FOUND" object: nil];
    }
}

- (void)onDeviceConnected: (CBPeripheral*) device {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    self.connectedDevice = device;
    [[self topViewController]  showAlertWithoutButtons:@"" message: @"You can Start your activity now… \nYour Handle is paired." onDone:^(BOOL result) {
        [self runObserverWith: @selector(connected)];
    }];
}

- (void)onDeviceDisconnected:(CBPeripheral*)device {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[self topViewController] showAlert: @"Warnning" message: @"Device has been disconnected." onDone:^(BOOL result) {
        self.connectedDevice = nil;
        [self runObserverWith: @selector(disconnected)];
        [[self topViewController] showPairViewController: YES];
    }];
}

- (void)onConnectionFailed:(CBPeripheral*)device error:(NSError*)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [[self topViewController]  showAlert: @"Please make sure your Smart Handle is fully charged and close to your phone." message: @"" onDone:^(BOOL result) {
        [self runObserverWith: @selector(disconnected)];
        [self.bleManager startScan];
    }];
    self.connectedDevice = nil;
}

- (void) onBluetoothScanStarted {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self runObserverWith: @selector(connecting)];
    self.connectionStatus = CONNECTING;
}

- (void)setLookingForHandleTimeout:(int) seconds {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self.connectionStatus != CONNECTED) {
            [SVProgressHUD dismiss];
            [self stopScan];
            self.connectedDevice = nil;
            [[self topViewController] showAlert: @"We can't find your previous BLE. Please choose any." message: @"" onDone: ^(BOOL result) {
                [self runObserverWith: @selector(timeout)];
                [[self topViewController] showPairViewController: YES];
            }];
        }
    });
}

@end

