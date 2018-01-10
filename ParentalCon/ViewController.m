//
//  ViewController.m
//  ParentalCon
//
//  Created by Liu Jie on 1/9/18.
//  Copyright © 2018 Jella. All rights reserved.
//

#import "ViewController.h"
#import "DeviceTableViewCell.h"
#import "BleConnectionManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, BleConnectionDelegate>
@property (weak, nonatomic) NSMutableArray* devices;
@property (nonatomic, strong) CBPeripheral* selectedDevice;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[BleConnectionManager sharedManager] configure];
    
    btnDeviceScan.layer.borderColor = [UIColor colorWithRed:60.0f/255.0f green:210.0f/255.0f blue:255.0f/255.0f alpha:1.0f].CGColor;
    btnDeviceScan.layer.cornerRadius = 15.0f;
    btnDeviceScan.layer.borderWidth = 1.0f;
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDeviceDiscovered:) name: @"NEW_DEVICE_FOUND" object: nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[BleConnectionManager sharedManager] addConnectionObserver: self];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[BleConnectionManager sharedManager] removeConnectionObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onDeviceScan:(id)sender {
    [[BleConnectionManager sharedManager] startAutoConnect];
}
#pragma mark BleConnectionDelegate
- (void ) connected {
    [SVProgressHUD dismiss];
    [self dismissViewControllerAnimated: NO completion: nil];
}

- (void) timeout {
    [SVProgressHUD dismiss];
}

- (void) failed {
    [SVProgressHUD dismiss];
}

- (void) disconnected {
    [SVProgressHUD dismiss];
}

- (void) onDeviceDiscovered: (id) sender {
    self.devices = [BleConnectionManager sharedManager].discoveredDevices;
    [DeviceListTableView reloadData];
}

#pragma mark UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.devices != nil ? self.devices.count : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DeviceTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"DEVICE_CELL"];
    if (cell) {
        CBPeripheral* currentOne = self.devices[indexPath.row];
        cell.name = [currentOne getJumpRopeName];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [DeviceTableViewCell height];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedDevice = self.devices[indexPath.row];
}
@end
