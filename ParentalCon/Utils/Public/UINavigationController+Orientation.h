//
//  UINavigationController+ Orientation.h
//  SnapTape
//
//  Created by Macmini on 10/22/17.
//  Copyright © 2017 Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController(Orientation)
- (UIInterfaceOrientationMask) supportedInterfaceOrientations;
- (BOOL) shouldAutorotate;
@end
