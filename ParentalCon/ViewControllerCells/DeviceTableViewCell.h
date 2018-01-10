//
//  DeviceTableViewCell.h
//  LifeFlow
//
//  Created by Macmini on 11/1/17.
//  Copyright © 2017 CULabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UIButton *btnSelection;
@property (nonatomic, strong) NSString* name;

+ (CGFloat) height;
@end
