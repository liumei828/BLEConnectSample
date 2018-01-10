//
//  UINavigationController+ Orientation.m
//  SnapTape
//
//  Created by Macmini on 10/22/17.
//  Copyright © 2017 Eddy. All rights reserved.
//

#import "UINavigationController+Orientation.h"

@implementation UINavigationController(Orientation)

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (BOOL) shouldAutorotate
{
    return YES;
}

@end
