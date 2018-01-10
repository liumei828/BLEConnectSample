//
//  UIManager.m
//  LifeFlow
//
//  Created by Macmini on 10/29/17.
//  Copyright © 2017 CULabs. All rights reserved.
//

#import "UIManager.h"

@implementation UIManager
+ (instancetype) sharedManager {
    static UIManager *instance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        instance = [[UIManager alloc] init];
    });
    
    return instance;
}

- (ScreenSize) deviceType {
    if (IS_IPHONE_4_OR_LESS || IS_IPHONE_5) {
        return SMALL;
    }
    else if (IS_IPHONE_6) {
        return MEDIUM;
    }
    else if (IS_IPHONE_6P) {
        return LARGE;
    }
    else {
        return EXLARGE;
    }
}
@end

