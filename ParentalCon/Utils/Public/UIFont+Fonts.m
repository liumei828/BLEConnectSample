#import "UIFont+Fonts.h"

@implementation UIFont (Fonts)

const int tiny = 7;
const int small = 12;
const int medium = 15;
const int big = 17;
const int bigger = 18;
const int biggest = 21;

+ (UIFont *)appPrimaryFontSmall {
    return [UIFont fontWithName:@"Seravek-Light" size:small];
}

+ (UIFont *)appPrimaryFontTiny {
    return [UIFont fontWithName:@"Seravek-Light" size:tiny];
}

+ (UIFont *)appPrimaryFontMedium {
    return [UIFont fontWithName:@"Seravek-ExtraLight" size:medium];
}

+ (UIFont *)appPrimaryFontLight {
    return [UIFont fontWithName:@"Seravek-Light" size:medium];
}

+ (UIFont *)appPrimaryFontMediumTiny {
    return [UIFont fontWithName:@"Seravek-Medium" size:tiny];
}

+ (UIFont *)appPrimaryFontMediumSmall {
    return [UIFont fontWithName:@"Seravek-Medium" size:small];
}

+ (UIFont *)appPrimaryFontMediumBig {
    return [UIFont fontWithName:@"Seravek-Medium" size:medium];
}

+ (UIFont *)appPrimaryFontMediumLarge {
    return [UIFont fontWithName:@"Seravek-Medium" size:big];
}

+ (UIFont *)appPrimaryFontBig {
    return [UIFont fontWithName:@"Seravek-ExtraLight" size:big];
}

+ (UIFont *)appPrimaryFontBigger {
    return [UIFont fontWithName:@"Seravek-ExtraLight" size:bigger];
}

+ (UIFont *)appPrimaryFontBiggerBold {
    return [UIFont fontWithName:@"Seravek-Light" size:bigger];
}


+ (UIFont *)appPrimaryFontGigant {
    return [UIFont fontWithName:@"Seravek-Light" size:26];
}

+ (UIFont *)appPrimaryFontBoldLarge {
    return [UIFont fontWithName:@"Seravek-Bold" size:24];
}

+ (UIFont *)appPrimaryFontBoldBig {
    return [UIFont fontWithName:@"Seravek-Bold" size:18];
}

+ (UIFont *)appPrimaryFontBold {
    return [UIFont fontWithName:@"Seravek-Bold" size:13];
}

+ (UIFont *)appPrimaryFontBoldSmall {
    return [UIFont fontWithName:@"Seravek-Bold" size:small];
}


+ (UIFont *)appItalicFontSmall {
    return [UIFont fontWithName:@"Seravek-LightItalic" size:small];
}

+ (UIFont *)appItalicFontMedium {
    return [UIFont fontWithName:@"Seravek-LightItalic" size:medium];
}

+ (UIFont *)appItalicFontBig {
    return [UIFont fontWithName:@"Seravek-LightItalic" size:big];
}

+ (UIFont *)appItalicSemiboldFontBig {
    return [UIFont fontWithName:@"Seravek-Italic" size:big];
}

+ (UIFont *)appItalicFontBigger {
    return [UIFont fontWithName:@"Seravek-LightItalic" size:bigger];
}

+ (UIFont *)appExtraLightFontOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-ExtraLight" size:size];
}

+ (UIFont *)appLightFontOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-Light" size:size];
}

+ (UIFont *)appMediumFontOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek" size:size];
}

+ (UIFont *)appPrimaryMediumFontOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-Medium" size: size];
}

+ (UIFont *)appBoldFontOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-Bold" size:size];
}

+ (UIFont *)ofSize:(int)size {
    return [UIFont fontWithName:@"Seravek-ExtraLight" size:size];
}

+ (UIFont *)italicOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-LightItalic" size:size];
    
}

+ (UIFont *)italicLightOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-ExtraLightItalic" size:size];
    
}

+ (UIFont *)boldItalicOfSize:(int)size {
    return [UIFont fontWithName:@"Seravek-BoldItalic" size:size];
    
}

@end
