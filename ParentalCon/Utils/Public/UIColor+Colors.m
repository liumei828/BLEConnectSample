#import "UIColor+Colors.h"

@implementation UIColor (Colors)

+ (UIColor *)appPrimaryColor {
    return [UIColor colorFromHexString: @"#94D500"];
}

+ (UIColor *)appDarkColor {
    return [UIColor colorFromHexString: @"#3E1051"];
}

+ (UIColor *)chartPinkColor {
    return [UIColor colorFromHexString: @"#FE7BAB"];
}

+ (UIColor *)chartOrangeColor {
    return [UIColor colorFromHexString: @"#FAAF3A"];
}

+ (UIColor *)chartYellowColor {
    return [UIColor colorFromHexString: @"#FFFF00"];
}

+ (UIColor *)chartGreenColor {
    return [UIColor colorFromHexString: @"#7AD2AA"];
}

+ (UIColor *)chartBlueColor {
    return [UIColor colorFromHexString: @"#54BAE7"];
}

+ (UIColor *)chartGreyColor {
    return [UIColor colorFromHexString: @"#A9A9A9"];
}

+ (UIColor *)textGreyColor {
    return [UIColor colorFromHexString: @"#808080"];
}

+ (UIColor *)lightGreyColor {
    return [UIColor colorFromHexString: @"#C0C0C0"];
}

+ (UIColor *)appTextColor {
    return [UIColor colorFromHexString: @"#361148"];
}

+ (UIColor *)turquoiseColor {
    return [UIColor colorFromHexString: @"#29C5CF"];
}

+ (UIColor *)lightCyanColor {
    return [UIColor colorFromHexString: @"#DEF7F8"];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (UIColor *)lighter
{
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darker
{
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}
@end
