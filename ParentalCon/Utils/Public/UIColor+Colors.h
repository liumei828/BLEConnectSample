#import <UIKit/UIKit.h>

@interface UIColor (Colors)

+ (UIColor*)appPrimaryColor;
+ (UIColor*)appDarkColor;
+ (UIColor *)appTextColor;

+ (UIColor*)chartPinkColor;
+ (UIColor*)chartOrangeColor;
+ (UIColor*)chartYellowColor;
+ (UIColor*)chartGreenColor;
+ (UIColor*)chartBlueColor;
+ (UIColor*)chartGreyColor;
+ (UIColor*)textGreyColor;
+ (UIColor *)turquoiseColor;
+ (UIColor *)lightGreyColor;
+ (UIColor *)lightCyanColor;

+ (UIColor *)colorFromHexString:(NSString *)hexString; 

- (UIColor *)lighter;
- (UIColor *)darker;

@end
