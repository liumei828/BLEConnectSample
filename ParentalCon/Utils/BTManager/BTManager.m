#import "BTManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

NSString *jumpRopeStringId = @"00021a10-0000-1000-8000-00805f9b0794";
NSString *readStringId = @"0003CDD1-0000-1000-8000-00805F9B0131";
NSString *writeStringId = @"0003CDD2-0000-1000-8000-00805F9B0131";

NSInteger firstByte = 0x40;
NSInteger lastByte =  0x03;

//sensor commands
NSInteger cmdAllSensors = 0x10;
NSInteger cmdHeartRate =  0x11;
NSInteger cmdGSensor =    0x12;
NSInteger cmdUV =         0x13;
NSInteger cmdThermal =    0x14;
NSInteger cmdHumidity =   0x15;
NSInteger cmdCount =      0x16;
NSInteger cmdBattery =    0x17;

//data commands
NSInteger cmdFirmware =         0x21;
NSInteger cmdName =             0x22;
NSInteger cmdSN =               0x23;
NSInteger cmdProtocol =         0x24;
NSInteger cmdManufactureDate =  0x25;
NSInteger cmdTimestamp =        0x26;
NSInteger cmdCurrentUserId =    0x27;
NSInteger cmdUserProfile =      0x28;

//sys commands
NSInteger cmdSetTimestamp = 0x31;

//sensors
NSInteger sensorHeartRate =  0x91;
NSInteger sensorGSensor =    0x92;
NSInteger sensorUV =         0x93;
NSInteger sensorThermal =    0x94;
NSInteger sensorHumidity =   0x95;
NSInteger sensorCount =      0x96;
NSInteger sensorBattery =    0x97;

//data
NSInteger dataFWVersion =        0xA1;
NSInteger dataDeviceName =       0xA2;
NSInteger dataSerialNumber =     0xA3;
NSInteger dataProtocolVersion =  0xA4;
NSInteger dataManufacture =      0xA5;
NSInteger dataTimestamp =        0xA6;
NSInteger dataCurrentUserId =    0xA7;
NSInteger dataUserProfile =      0xA8;

//firmware update commands
NSInteger firmwareUpdateRequest =  0x60;
NSInteger firmwareDataUpload =     0x61;
NSInteger firmwareUploadStatus =   0x69;

NSInteger cmdACK =  0x06;
NSInteger cmdNACK = 0x07;

NSString *const firmwareResource = @"APP_v0.2.4.5";
NSString *const newFirmwareVersion = @"v0.2.4.5";

NSString *const keySyncDate = @"KeySyncDate";
NSString *const keyTotalBytes = @"KeyTotalBytes";

uint8_t const fwVer[] = { 0x05, 0x04, 0x02, 0x00 };

typedef NS_ENUM(NSInteger, PacketPart) {
    Head,
    Command,
    DataLength,
    Data,
    End
};

@interface BTManager() <CBCentralManagerDelegate, CBPeripheralDelegate> {
    CBUUID *_serviceId;
    CBUUID *_readId;
    CBUUID *_writeId;
    PMVValue *value;
    
    BOOL isUpdating;
    NSInteger packetsCount;
    NSInteger currentPacket;
    
    BOOL byteOrderStraight;
    
    int16_t _x;
    int16_t _y;
    int16_t _z;
    BOOL hasMotionData;
    
    NSTimeInterval lastTimeStamp;
    
    NSMutableData *_currentData;
    uint8_t _currentCommand;
    uint8_t _currentDataLength;
    PacketPart _nextPacketPart;
    
    BOOL _isCollectingData;
    NSTimeInterval _connectedTime;
}
@end

@implementation BTManager

@synthesize lastTemperature;

+ (instancetype)sharedManager {
    static BTManager *instance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        instance = [[BTManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void) configure {
    byteOrderStraight = YES;
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(YES)}];
    _serviceId = [CBUUID UUIDWithString:jumpRopeStringId];
    _readId = [CBUUID UUIDWithString:readStringId];
    _writeId = [CBUUID UUIDWithString:writeStringId];
    
    [self cleanValue];
    
    _nextPacketPart = Head;
    _isCollectingData = YES;
    
    // for testing collectData
    //[[NSUserDefaults standardUserDefaults] setObject:@(1509058800) forKey:keySyncDate];
}

- (void)connectDevice:(CBPeripheral *)device {
    [_centralManager connectPeripheral:device options:nil];
    [_centralManager stopScan];
}

- (void)disconnectDevice: (CBPeripheral*) device {
    if (device != nil) {
        [_centralManager cancelPeripheralConnection: device];
    }
}

- (void) startScan {
    self.discoveredDevice = nil;
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onBluetoothScanStarted)]) {
        [_delegate onBluetoothScanStarted];
    }
    
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
    [self logBT:@"Scanning" message:@"started"];
}

- (void) stopScan {
    [_centralManager stopScan];
    [self logBT:@"Scanning" message:@"stopped"];
}

#pragma mark - CBCentralManagerDelegate Implementation

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (self.delegate != nil && [self.delegate respondsToSelector: @selector(onBTStateUpdated:)]) {
        [self.delegate onBTStateUpdated: central.state];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
#ifdef TEST_BLE
    self.discoveredDevice = peripheral;
    [self logBT:[peripheral getJumpRopeName] message:@"discovered"];
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onDiscoverDevice:)]) {
        [_delegate onDiscoverDevice: self.discoveredDevice];
    }
#else
    NSData *manufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    NSString *manufacturerString = [manufacturerData base64EncodedStringWithOptions:0];
    if ([manufacturerString isEqualToString:@"MQE7BA=="]) {
        [self logBT: [peripheral getJumpRopeName] message:@"discovered"];
        self.discoveredDevice = peripheral;
        if (_delegate != nil && [_delegate respondsToSelector:@selector(onDiscoverDevice:)]) {
            [_delegate onDiscoverDevice: self.discoveredDevice];
        }
    }
#endif
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self logBT:[peripheral getJumpRopeName] message:@"connected"];
    
    self.connectedDevice = peripheral;
    _connectedDevice.delegate = self;
    self.discoveredDevice = nil;
    
    if (_delegate != nil && [_delegate respondsToSelector: @selector(onDeviceConnected:)]) {
        [_delegate onDeviceConnected: _connectedDevice];
    }
    [_connectedDevice discoverServices:nil];
    _connectedTime = [[NSDate date] timeIntervalSince1970];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self logBT:[peripheral getJumpRopeName]  message:@"disconnected"];
    
    self.discoveredDevice = nil;
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onDeviceDisconnected:)]) {
        [_delegate onDeviceDisconnected:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self logBT: [peripheral getJumpRopeName]  message:@"connection failed"];
    
    self.discoveredDevice = nil;
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onConnectionFailed:error:)]) {
        [_delegate onConnectionFailed: peripheral error:error];
    }}

#pragma mark - CBPeripheralDelegate Implementation

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    [self logBT: [peripheral getJumpRopeName]  message:@"discovered services"];
    
    if (peripheral == _connectedDevice) {
        for (CBService *service in peripheral.services) {
            [self logBT:@"Service:" message:[service.UUID UUIDString]];
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self logBT: [peripheral getJumpRopeName]  message:[NSString stringWithFormat:@"Discover Characteristic %@ For Service %@", characteristic.UUID, service.UUID]];
        
        if ([characteristic.UUID isEqual:_writeId]) {
            _writeCharacteristic = characteristic;
        }
        else if ([characteristic.UUID isEqual:_readId]) {
            _readCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
#ifndef TEST
    [self sendInitCommands];
#endif
}

- (void)sendInitCommands {
    [self sendCommand:[self timestampSetCommand]];
    [self sendCommand:[self firmwareVersionCommand]];
}

- (void)sendCommand:(NSData *)data {
    if (_connectedDevice != nil && _writeCharacteristic != nil) {
        [_connectedDevice writeValue:data
                   forCharacteristic:_writeCharacteristic
                                type:CBCharacteristicWriteWithoutResponse];
        
        NSLog(@"[DeviceManager] command: %@", data);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"didWriteValueForCharacteristic");
}

- (void)collectData {
    NSNumber* syncDate = [[NSUserDefaults standardUserDefaults] valueForKey: keySyncDate];
    if (syncDate != nil) {
        NSTimeInterval seconds = [syncDate doubleValue];
        NSLog(@"Collect data for: %@", [NSDate dateWithTimeIntervalSince1970: seconds]);
        
        if (seconds < _connectedTime) {
            [self sendCommand:[self getAllSensorsCommandWithTimestamp:seconds duration:1]];
        }
        else {
            _isCollectingData = NO;
        }
    }
    else {
        _isCollectingData = NO;
    }
}

- (void)setTimestampBytes:(uint8_t *)bytes
                    start:(NSUInteger)start
                   length:(NSUInteger)length
                timestamp:(NSTimeInterval)timestamp {
    NSString *time = [NSString stringWithFormat:@"%.2f", timestamp];
    NSArray *timeComponents = [time componentsSeparatedByString:@"."];
    uint64_t seconds = [timeComponents[0] longLongValue];
    
    bytes[start] = seconds & 0xFF;
    bytes[start + 1] = (seconds >> 8) & 0xFF;
    bytes[start + 2] = (seconds >> 16) & 0xFF;
    bytes[start + 3] = (seconds >> 24) & 0xFF;
    
    if (length > 4) {
        uint8_t subseconds = [timeComponents[1] intValue];
        bytes[start + 4] = subseconds & 0xFF;
    }
}

- (void)setSysTimestampBytes:(uint8_t *)bytes {
    [self setTimestampBytes:bytes start:3 length:4 timestamp:[[NSDate date] timeIntervalSince1970]];
}

- (void)setGSDTimestampBytes:(uint8_t *)bytes timestamp:(NSTimeInterval)timestamp {
    [self setTimestampBytes:bytes start:3 length:5 timestamp:timestamp];
}

- (NSTimeInterval)timeIntervalFromTimestampBytes:(const uint8_t *)bytes {
    uint64_t seconds = bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
    NSTimeInterval timeInterval = seconds + bytes[4] / 100.0;
    return timeInterval;
}

- (NSData *)timestampSetCommand {
    uint8_t bytes[] = {
        firstByte, cmdSetTimestamp, 0x04,
        0x00, 0x00, 0x00, 0x00,
        lastByte
    };
    
    [self setSysTimestampBytes:bytes];
    
    return [NSData dataWithBytes:bytes length:8];
}

- (NSData *)getAllSensorsCommandWithTimestamp:(NSTimeInterval)timestamp
                                     duration:(NSInteger)duration {
    uint8_t durationByte = duration;
    uint8_t bytes[] = {
        firstByte, cmdAllSensors, 0x06,
        0x00, 0x00, 0x00, 0x00, 0x00,
        durationByte,
        lastByte
    };
    
    [self setGSDTimestampBytes:bytes timestamp:timestamp];
    
    return [NSData dataWithBytes:bytes length:10];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString* deviceId = [[peripheral identifier] UUIDString];
    
    if (error) {
        [self logBT:@"Error:" message:@"didUpdateValueForCharacteristic error"];
        return;
    }
    
    //NSLog(@"Data packet: %@", characteristic.value);
    
    [characteristic.value enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        for (int i = 0; i < byteRange.length; i++) {
            uint8_t currentByte = ((uint8_t *)bytes)[i];
            if (_nextPacketPart == Head) {
                if (currentByte == firstByte) {
                    _nextPacketPart = Command;
                }
                else {
                    break;
                }
            }
            else if (_nextPacketPart == Command) {
                _currentCommand = currentByte;
                _nextPacketPart = DataLength;
            }
            else if (_nextPacketPart == DataLength) {
                _currentDataLength = currentByte;
                _currentData = [NSMutableData dataWithCapacity:_currentDataLength];
                _nextPacketPart = Data;
            }
            else if (_nextPacketPart == Data) {
                [_currentData appendBytes:&currentByte length:1];
                if (_currentData.length == _currentDataLength) {
                    _nextPacketPart = End;
                }
            }
            else if (_nextPacketPart == End) {
                if (currentByte == lastByte) {
                    [self handleCommand:_currentCommand data:_currentData];
                }
                _nextPacketPart = Head;
            }
        }
    }];
    
    NSNumber *totalBytesNumber = [[NSUserDefaults standardUserDefaults] valueForKey:keyTotalBytes];
    double totalBytes = 0;
    if (totalBytesNumber != nil) {
        totalBytes = [totalBytesNumber doubleValue];
    }
    totalBytes += characteristic.value.length;
    [[NSUserDefaults standardUserDefaults] setObject:@(totalBytes) forKey:keyTotalBytes];
}

- (void)handleCommand:(uint8_t)command data:(NSData *)data {
    //    NSLog(@"handleCommand: 0x%x, data: %@", _currentCommand, _currentData);
    //NSLog(@"handleCommand: 0x%x, data: %@", _currentCommand, _currentData);
    const uint8_t *bytes = data.bytes;
    value = [PMVValue new];
    if (command == sensorHeartRate) {
        value.type = HeartRate;
        [value addNumber: (int16_t)bytes[5]];
#ifdef BLE_LOG_ENABLED
        NSLog(@"Heart rate = %d", (int)[value number]);
#endif
    }
    else if (command == sensorGSensor) {
        value.type = Motion;
        [value addNumber: (int16_t)((bytes[6] << 8) | bytes[5])]; //x
        [value addNumber: (int16_t)((bytes[8] << 8) | bytes[7])]; //y
        [value addNumber: (int16_t)((bytes[10] << 8) | bytes[9])]; //z
#ifdef BLE_LOG_ENABLED
        NSLog(@"G Sensor = %.f, %.f, %.f", [value numberAt: 0], [value numberAt: 1], [value numberAt: 2]);
#endif
    }
    else if (command == sensorUV) {
        value.type = UV;
        [value addNumber: (int16_t)bytes[5]];
#ifdef BLE_LOG_ENABLED
        NSLog(@"UV = %d", (int)[value number]);
#endif
    }
    else if (command == sensorThermal) {
        value.type = Temporature;
        [value addNumber: (double)(((bytes[6] << 8) | bytes[5]) * 0.1)];
#ifdef BLE_LOG_ENABLED
        NSLog(@"Thermal = %.1f", [value number]);
#endif
    }
    else if (command == sensorHumidity) {
        value.type = Humidity;
        [value addNumber: (int16_t)bytes[5]];
#ifdef BLE_LOG_ENABLED
        NSLog(@"Humidity = %d", (int)[value number]);
#endif
    }
    else if (command == sensorCount) {
        value.type = Counter;
#ifdef BLE_LOG_ENABLED
#endif
        //        NSLog(@"Counter = 1");
        [value addNumber: 1];
    }
    else if (command == sensorBattery) {
        value.type = Battery;
        [value addNumber: (int16_t)bytes[5]];
        int battery = [value number];
        if (battery != self.batteryLevel) {
            self.batteryLevel = battery;
            [[NSNotificationCenter defaultCenter] postNotificationName: @"BatteryStatusUpdated" object: nil];
        }
        self.batteryLevel = battery;
#ifdef BLE_LOG_ENABLED
        NSLog(@"Battery = %d", (int)[value number]);
#endif
    }
    else if (command == dataFWVersion) {
        NSString *version = @"v";
        
        for (NSUInteger i = data.length - 1; i > 0; i--) {
            version = [version stringByAppendingString:[NSString stringWithFormat:@"%d.", (int16_t)bytes[i]]];
        }
        version = [version stringByAppendingString:[NSString stringWithFormat:@"%d", (int16_t)bytes[0]]];
        
        _firmwareVersion = version;
        NSLog(@"[DeviceManager] firmwareVersion: %@", _firmwareVersion);
        
        if (_delegate != nil && [_delegate respondsToSelector:@selector(onFirmwareVersionRetrieved:)]) {
            [_delegate onFirmwareVersionRetrieved:_firmwareVersion];
        }
    }
    else if (command == dataDeviceName){
        NSLog(@"device name");
    }
    else if (command == dataSerialNumber) {
        NSLog(@"serial number");
    }
    else if (command == dataProtocolVersion) {
        NSLog(@"protocol version");
    }
    else if (command == dataManufacture) {
        NSLog(@"manufacture data");
    }
    else if (command == dataTimestamp) {
        NSLog(@"dataTimestamp");
    }
    else if (command == dataCurrentUserId) {
        NSLog(@"current user id");
    }
    else if (command == dataUserProfile) {
        NSLog(@"user profile");
    }
    else if (command == cmdACK) {
        [self onAcknowledge];
    }
    else if (command == cmdNACK) {
        [self onNegativeAcknowledge];
    }
    else if (command == firmwareUploadStatus) {
        uint8_t status = bytes[0];
        NSLog(@"Firmware upload status = %d", status);
        [self onStatusUpdated:status];
    }
    
    if (0x91 <= command && command <= 0x96) {
        value.timestamp = [self timeIntervalFromTimestampBytes:bytes];
        //        NSLog(@"Timestamp: %@", [NSDate dateWithTimeIntervalSince1970: value.timestamp]);
        
        /*
         if (command == sensorHeartRate) {
         NSLog(@"Timestamp: %@, Heart rate = %d", [NSDate dateWithTimeIntervalSince1970: value.timestamp], (int)[value number]);
         }
         else if (command == sensorGSensor) {
         NSLog(@"Timestamp: %@, G Sensor = %.f, %.f, %.f", [NSDate dateWithTimeIntervalSince1970: value.timestamp], [value numberAt: 0], [value numberAt: 1], [value numberAt: 2]);
         }
         else if (command == sensorUV) {
         NSLog(@"Timestamp: %@, UV = %d", [NSDate dateWithTimeIntervalSince1970: value.timestamp], (int)[value number]);
         }
         else if (command == sensorThermal) {
         NSLog(@"Timestamp: %@, Thermal = %.1f", [NSDate dateWithTimeIntervalSince1970: value.timestamp], [value number]);
         }
         else if (command == sensorHumidity) {
         NSLog(@"Timestamp: %@, Humidity = %d", [NSDate dateWithTimeIntervalSince1970: value.timestamp], (int)[value number]);
         }
         else if (command == sensorCount) {
         NSLog(@"Timestamp: %@, Counter = 1", [NSDate dateWithTimeIntervalSince1970: value.timestamp]);
         }*/
        

//        if (_isCollectingData) {
//            if (command == sensorHeartRate) {
//                NSLog(@"Downloading Timestamp: %@, Heart rate = %d", [NSDate dateWithTimeIntervalSince1970: value.timestamp], (int)[value number]);
//            }
//            else if (command == sensorGSensor) {
//                NSLog(@"Downloading Timestamp: %@, G Sensor = %.f, %.f, %.f", [NSDate dateWithTimeIntervalSince1970: value.timestamp], [value numberAt: 0], [value numberAt: 1], [value numberAt: 2]);
//            }
//            else if (command == sensorUV) {
//                NSLog(@"Downloading Timestamp: %@, UV = %d", [NSDate dateWithTimeIntervalSince1970: value.timestamp], (int)[value number]);
//            }
//            else if (command == sensorThermal) {
//                NSLog(@"Downloading Timestamp: %@, Thermal = %.1f", [NSDate dateWithTimeIntervalSince1970: value.timestamp], [value number]);
//            }
//            else if (command == sensorHumidity) {
//                NSLog(@"Downloading Timestamp: %@, Humidity = %d", [NSDate dateWithTimeIntervalSince1970: value.timestamp], (int)[value number]);
//            }
//            else if (command == sensorCount) {
//                NSLog(@"Downloading Timestamp: %@, Counter = 1", [NSDate dateWithTimeIntervalSince1970: value.timestamp]);
//            }
//        }
//        else {
            [self pushValues];
//        }
    }
    
}

- (short)getCoordinate:(signed char)b1 b2:(signed char)b2 {
    return b2 << 8 | b1;
}

- (int)convertToSignedInt:(uint8_t)v{
    if ((v & 0x80) > 0) {
        v = 0x80 - v;
        return v;
    }
    return v;
}

- (void)cleanValue {
    value = nil;
    value = [[PMVValue alloc] init];
    lastTimeStamp = [[NSDate date] timeIntervalSince1970];
}

- (void)pushValues {
    if (value == nil) {
        value = [[PMVValue alloc] init];
    }
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onDataReceived:)]) {
        if (value.numbers.count > 0) {
            value.timestamp = [[NSDate date] timeIntervalSince1970];
            [_delegate onDataReceived:value];
            [self cleanValue];
        }
    }
}

- (void)getFirmwareVersion {
    [self sendCommand:[self firmwareVersionCommand]];
    [self sendCommand:[self timestampCommand]];
    [self sendCommand:[self nameCommand]];
    [self sendCommand:[self serialNumberCommand]];
    [self sendCommand:[self protocolCommand]];
    [self sendCommand:[self manufactureDateCommand]];
    [self sendCommand:[self currentUserIdCommand]];
    [self sendCommand:[self userProfileCommand]];
}

- (void)getName {
    [self sendCommand:[self nameCommand]];
}

- (BOOL)hasNewFirmware {
    for (int i=0; i<_firmwareVersion.length; i++) {
        if ([newFirmwareVersion characterAtIndex:i] > [_firmwareVersion characterAtIndex:i]) {
            return YES;
        }
    }
    return NO;
}

- (NSData *)firmwareVersionCommand {
    uint8_t bytes[] = {
        firstByte, cmdFirmware, 0x01, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:5];
}

- (NSData *)nameCommand {
    uint8_t bytes[] = {
        firstByte, cmdName, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)serialNumberCommand {
    uint8_t bytes[] = {
        firstByte, cmdSN, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)protocolCommand {
    uint8_t bytes[] = {
        firstByte, cmdProtocol, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)manufactureDateCommand {
    uint8_t bytes[] = {
        firstByte, cmdManufactureDate, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)timestampCommand {
    uint8_t bytes[] = {
        firstByte, cmdTimestamp, 0x01, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)currentUserIdCommand {
    uint8_t bytes[] = {
        firstByte, cmdCurrentUserId, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)userProfileCommand {
    uint8_t bytes[] = {
        firstByte, cmdUserProfile, 0x00, lastByte
    };
    return [NSData dataWithBytes:bytes length:4];
}

- (void)requestUpdate {
    NSURL *firmwareURL = [[NSBundle mainBundle] URLForResource:firmwareResource
                                                 withExtension:@"bin"
                                                  subdirectory:@"Firmwares"];
    
    _firmwareData = [NSData dataWithContentsOfFile:firmwareURL.path];
    
    packetsCount = ((_firmwareData.length - 1) / 14) + 1;
    
    NSData *packetNumber = [NSData dataWithBytes:&packetsCount length:2];
    uint8_t num[2];
    [packetNumber getBytes:num range:NSMakeRange(0, 2)];
    
    uint8_t bytes[] = {
        firstByte, firmwareUpdateRequest, 0x08,
        num[byteOrderStraight ? 0 : 1], num[byteOrderStraight ? 1 : 0],  //packet count
        fwVer[0], fwVer[1], fwVer[2], fwVer[3],                          //firmware version
        0x01,                                                            //force flag
        0x00,                                                            //reserve
        lastByte
    };
    
    isUpdating = YES;
    currentPacket = 0;
    
    NSData *command = [NSData dataWithBytes:bytes length:12];
    [self sendCommand:command];
}

- (void)onAcknowledge {
    NSLog(@"onAcknowledge");
    if (isUpdating) {
        [self beginUpdate];
    }
    
    if (_isCollectingData) {
        NSNumber *syncDate = [[NSUserDefaults standardUserDefaults] valueForKey: keySyncDate];
        if (syncDate != nil) {
            NSTimeInterval seconds = [syncDate doubleValue];
            seconds += 600;
            [[NSUserDefaults standardUserDefaults] setObject:@(seconds) forKey: keySyncDate];
        }
        [self collectData];
    }
}

- (void)onNegativeAcknowledge {
    NSLog(@"onNegativeAcknowledge");
    isUpdating = NO;
}

- (void)onStatusUpdated:(NSInteger)status {
    if (status == 0x10) {
        if (_delegate != nil && [_delegate respondsToSelector:@selector(onUpdateSuccess)]) {
            [_delegate onUpdateSuccess];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FirmwareUpdateSuccess" object:self userInfo:@{}];
    }
    else if (status == 0x11) {
        NSString *error = @"F/w Upload completed but is crashed (CRC failed)";
        if (_delegate != nil && [_delegate respondsToSelector:@selector(onUpdateError:)]) {
            [_delegate onUpdateError:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FirmwareUpdateError" object:self userInfo:@{@"error":error}];
    }
    else if (status == 0x12) {
        NSString *error = @"F/w Upload incomplete, some packet lost. Or timeout";
        if (_delegate != nil && [_delegate respondsToSelector:@selector(onUpdateError:)]) {
            [_delegate onUpdateError:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FirmwareUpdateError" object:self userInfo:@{@"error":error}];
    }
}

- (void)beginUpdate {
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(onUpdateProgressChanged:)]) {
        [_delegate onUpdateProgressChanged:0];
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        for (int i = 0; i < packetsCount; i++) {
            
            [self sendPacket:i];
            
            int progress = i * 100 / packetsCount;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                if (_delegate != nil && [_delegate respondsToSelector:@selector(onUpdateProgressChanged:)]) {
                    [_delegate onUpdateProgressChanged:progress];
                }
            }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FirmwareUpdateProgress" object:self userInfo:@{@"progress":@(progress)}];
            
            if (i % 8 == 0) {
                [NSThread sleepForTimeInterval:0.02f];
            }
            else {
                [NSThread sleepForTimeInterval:0.001f];
            }
        }
    });
}

- (void)sendPacket:(NSInteger)packetNumber {
    
    NSInteger cmdNumber = packetNumber + 1;
    NSData *numberData = [NSData dataWithBytes:&cmdNumber length:2];
    
    NSInteger length = 14;
    if (packetNumber == packetsCount - 1) {
        length = _firmwareData.length % 14;
    }
    
    const uint8_t *packetNumberBytes = numberData.bytes;
    const uint8_t *firmwareBytes = _firmwareData.bytes;
    
    uint8_t bytes1[length + 6];
    
    bytes1[0] = firstByte;
    bytes1[1] = firmwareDataUpload;
    bytes1[2] = length + 2;
    
    bytes1[3] = packetNumberBytes[0];
    bytes1[4] = packetNumberBytes[1];
    
    for (int i=0; i<length; i++) {
        bytes1[5 + i] = firmwareBytes[packetNumber * 14 + i];
    }
    
    bytes1[length+5] = lastByte;
    
    NSLog(@"Sending packet %ld of %ld", (long)(currentPacket + 1), (long)packetsCount);
    currentPacket++;
    
    NSData *command = [NSData dataWithBytes:bytes1 length:length + 6];
    [self sendCommand:command];
}

- (NSString*)getDeviceModel {
    if (_connectedDevice != nil)
    {
        return [_connectedDevice getJumpRopeName];
    }
    return @"";
}

- (NSString*)getLastSyncedDate {
    NSNumber *seconds = [[NSUserDefaults standardUserDefaults] valueForKey:keySyncDate];
    if (seconds != nil) {
        NSTimeInterval time = (NSTimeInterval) [seconds doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
        NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
        [dateFormater setTimeZone:[NSTimeZone localTimeZone]];
        [dateFormater setDateFormat:@"MMMM dd, yyy"];
        NSString *result = [dateFormater stringFromDate:date];
        return result;
    }
    return @"Never";
}

- (NSString*)getTotalDataCollected {
    NSNumber *totalBytes = [[NSUserDefaults standardUserDefaults] valueForKey:keyTotalBytes];
    NSString *mod = @"B";
    double result = 0;
    if (totalBytes != nil) {
        result = [totalBytes doubleValue];
        if (result > 1024 * 1024 * 1024) {
            result /= (1024 * 1024 * 1024);
            mod = @"GB";
        }
        if (result > 1024 * 1024) {
            result /= (1024 * 1024);
            mod = @"MB";
        }
        else if (result > 1024) {
            result /= 1024;
            mod = @"KB";
        }
    }
    return [NSString stringWithFormat:@"%.f %@", result, mod];
}

#pragma mark Logging
- (void)showErrorAlert:(NSString*)message {
    [self logBT:@"BT error:" message:message];
}

- (void)logBT:(NSString*)name message:(NSString*)message {
    BOOL debug = YES;
    if (debug) {
        NSLog(@"[Bluetooth] Device %@ %@", name, message);
    }
}

@end


@implementation CBPeripheral (Name)
- (NSString*) getJumpRopeName {
    NSString* name = self.name;
    NSRange range = [name.lowercaseString rangeOfString: @"jumprope"];
    if (range.length > 0) {
        name = [name stringByReplacingCharactersInRange: range withString: @"LFSH ID "];
    }
    
    if ([name containsString: @"_XXXX"] || [name containsString: @"_xxxx"]) {
        NSString* identifier = self.identifier.UUIDString;
        identifier =[@" " stringByAppendingString: [identifier substringFromIndex: identifier.length - 4]];
        name = [name stringByReplacingOccurrencesOfString: @"_XXXX" withString: identifier];
        name = [name stringByReplacingOccurrencesOfString: @"_xxxx" withString: identifier];
    }
    return name;
}
@end
