//
//  DeviceTableViewCell.m
//  LifeFlow
//
//  Created by Macmini on 11/1/17.
//  Copyright © 2017 CULabs. All rights reserved.
//

#import "DeviceTableViewCell.h"
#import "UIFont+Fonts.h"

@implementation DeviceTableViewCell
+ (CGFloat) height {
    return 50;
}

- (void) awakeFromNib {
    [super awakeFromNib];
    if (self.lblDeviceName) {
        _lblDeviceName.font = [UIFont appLightFontOfSize: 16];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        _lblDeviceName.font = [UIFont appMediumFontOfSize: 16];
    }
    else {
        _lblDeviceName.font = [UIFont appLightFontOfSize: 16];
    }
    _btnSelection.selected = selected;
}

- (void) setName:(NSString *)name {
    _name = name;
    self.lblDeviceName.text = name;
}
@end
