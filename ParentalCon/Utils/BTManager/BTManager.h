#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PMVValue.h"

@protocol BTManagerDelegate <NSObject>
@optional
- (void)onBluetoothScanStarted;
- (void)onDiscoverDevice:(CBPeripheral*)device;
- (void)onDeviceConnected:(CBPeripheral*)device;
- (void)onDeviceDisconnected:(CBPeripheral*)device;
- (void)onConnectionFailed:(CBPeripheral*)device error:(NSError*)error;
- (void)onBTStateUpdated:(CBManagerState)state;
- (void)onDataReceived:(PMVValue*)data;
- (void)onFirmwareVersionRetrieved:(NSString *)version;
- (void)onNameRetrieved:(NSString *)name;
- (void)onUpdateError:(NSString *)error;
- (void)onUpdateSuccess;
- (void)onUpdateProgressChanged:(NSInteger)progress;
@end

@interface CBPeripheral (Name)
- (NSString*) getJumpRopeName;
@end

@interface BTManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<BTManagerDelegate> delegate;

@property (nonatomic, readwrite) NSInteger lastTemperature;
@property (nonatomic) NSInteger lastHeartRate;
@property (nonatomic) NSInteger lastJumpsCount;
@property (nonatomic) NSInteger lastCaloriesCount;
@property (nonatomic) NSInteger lastPerspiration;
@property (nonatomic) NSInteger lastOxygen;
@property (nonatomic) NSInteger lastX;
@property (nonatomic) NSInteger lastY;
@property (nonatomic) NSInteger lastZ;
@property (nonatomic, assign) int batteryLevel;

@property (nonatomic, copy) NSString *firmwareVersion;

@property (nonatomic) NSData *firmwareData;
@property (nonatomic) CBCharacteristic *readCharacteristic;
@property (nonatomic) CBCharacteristic *writeCharacteristic;
@property (nonatomic) CBCentralManager *centralManager;

@property (nonatomic, strong) CBPeripheral* connectedDevice;
@property (nonatomic, strong) CBPeripheral* discoveredDevice;

- (void)startScan;
- (void)stopScan;
- (void)connectDevice:(CBPeripheral *)device;
- (void)disconnectDevice: (CBPeripheral*) device;

- (void)configure;

- (BOOL)connectRetriavablePeripheralWith: (NSString*) identifier;

- (void)getFirmwareVersion;
- (void)getName;
- (BOOL)hasNewFirmware;
- (void)requestUpdate;

- (NSString*)getDeviceModel;
- (NSString*)getLastSyncedDate;
- (NSString*)getTotalDataCollected;
@end

