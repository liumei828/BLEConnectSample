#import <UIKit/UIKit.h>
#import "UIFont+Fonts.h"
#import "UIColor+Colors.h"
#import "UINavigationController+Orientation.h"

@interface BaseViewController : UIViewController <UITextFieldDelegate>

typedef void(^OnDone)(BOOL result);

- (void)setLoading:(BOOL)loading;
- (void)setLoading:(BOOL)loading message:(NSString*)message;

- (void)showAlertWithoutButtons:(NSString*)title message:(NSString*)message onDone:(OnDone)onDone;
- (void)showAlert:(NSString*)title message:(NSString*)message;
- (void)showAlert:(NSString*)title message:(NSString*)message onDone:(OnDone)onDone;
- (void)showAlertYesOrNo:(NSString*)title message:(NSString*)message result:(OnDone)onDone;
- (void)showAlertYesOrNo:(NSString*)title message:(NSString*)message yesButtonTitle: (NSString*) yesButtonTitle noButtonTitle: (NSString*) noButtonTitle onDone:(OnDone)onDone;
- (void)showVerifyEmailAlert:(OnDone)onDone;
- (void)configKeyboard;
- (void)makeBackground;
- (void)finish;

- (void) showBLEConnectionError;
- (void) showPairViewController: (BOOL) animated;

@property (nonatomic) UITapGestureRecognizer *gestureRecognizer;

@end
