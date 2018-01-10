#import <UIKit/UIKit.h>

@interface UIFont (Fonts)

+ (UIFont*)appPrimaryFontSmall;
+ (UIFont*)appPrimaryFontMedium;
+ (UIFont*)appPrimaryFontBig;
+ (UIFont*)appPrimaryFontBigger;
+ (UIFont*)appPrimaryFontBold;
+ (UIFont*)appPrimaryFontBoldBig;
+ (UIFont*)appPrimaryFontBoldLarge;
+ (UIFont*)appPrimaryFontGigant;

+ (UIFont *)appPrimaryFontMediumTiny;
+ (UIFont *)appPrimaryFontMediumSmall;
+ (UIFont *)appPrimaryFontMediumBig;
+ (UIFont *)appPrimaryFontMediumLarge;

+ (UIFont *)appExtraLightFontOfSize:(int)size;
+ (UIFont *)appLightFontOfSize:(int)size;
+ (UIFont *)appMediumFontOfSize:(int)size;
+ (UIFont *)appPrimaryMediumFontOfSize:(int)size;
+ (UIFont *)appBoldFontOfSize:(int)size;

+ (UIFont*)appItalicFontSmall;
+ (UIFont*)appItalicFontMedium;
+ (UIFont*)appItalicFontBig;
+ (UIFont*)appItalicFontBigger;

+ (UIFont*)ofSize:(int)size;
+ (UIFont*)italicOfSize:(int)size;
+ (UIFont *)italicLightOfSize:(int)size;

+ (UIFont*)appPrimaryFontBiggerBold;
+ (UIFont *)boldItalicOfSize:(int)size;
+ (UIFont *)appPrimaryFontLight;
+ (UIFont *)appItalicSemiboldFontBig;
+ (UIFont *)appPrimaryFontBoldSmall;
+ (UIFont *)appPrimaryFontTiny;

@end
