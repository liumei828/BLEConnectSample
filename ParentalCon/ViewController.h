//
//  ViewController.h
//  ParentalCon
//
//  Created by Liu Jie on 1/9/18.
//  Copyright © 2018 Jella. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface ViewController : BaseViewController
{
    __weak IBOutlet UITableView *DeviceListTableView;
    __weak IBOutlet UIButton *btnDeviceScan;
    
}
- (IBAction)onDeviceScan:(id)sender;

@end

