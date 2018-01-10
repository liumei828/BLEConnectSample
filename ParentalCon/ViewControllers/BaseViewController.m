#import "BaseViewController.h"
#import "MBProgressHUD.h"
#import "UIFont+Fonts.h"
#import "UIColor+Colors.h"
#import "UIManager.h"

@interface BaseViewController() {
    MBProgressHUD *hud;
    NSMutableDictionary<NSNumber*, NSAttributedString*>* placeholderArray;
}
@property (nonatomic, strong) UIAlertController* alertWithoutButtons;
@property (nonatomic, strong) OnDone alertCompletion;
@property (nonatomic, strong) UITapGestureRecognizer* tapGesture;

@end

@implementation BaseViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    placeholderArray = [NSMutableDictionary<NSNumber*, NSAttributedString*> dictionary];
   
    [self updateFonts: self.view];
}

- (void) updateFonts: (UIView*) vw {
    for (UILabel* label in vw.subviews) {
        if ([label isKindOfClass: [UILabel class]]) {
            UIFont* font = label.font;
            UIFontDescriptor *fontDescriptor = font.fontDescriptor;
            UIFontDescriptorSymbolicTraits fontDescriptorSymbolicTraits = fontDescriptor.symbolicTraits;
            BOOL isBold = (fontDescriptorSymbolicTraits & UIFontDescriptorTraitBold) != 0;
            BOOL isItalic = (fontDescriptorSymbolicTraits & UIFontDescriptorTraitItalic) != 0;
            
            if (isBold & isItalic) {
                label.font = [UIFont boldItalicOfSize: label.font.pointSize];
            }
            else if (isBold) {
                label.font = [UIFont appMediumFontOfSize: label.font.pointSize];
            }
            else if (isItalic) {
                label.font = [UIFont italicLightOfSize: label.font.pointSize];
            }
        }
        else if (label.subviews != nil && label.subviews.count > 0) {
            [self updateFonts: label];
        }
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [UIManager sharedManager].activeViewController = self;
    if (self.navigationController) {
        self.navigationController.navigationBar.translucent = NO;
    }
}

- (void)setLoading:(BOOL)loading {
    [self setLoading:loading message:@""];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if(textField.attributedPlaceholder != nil)
    {
        [placeholderArray setObject:textField.attributedPlaceholder forKey:@(textField.tag)];
        textField.attributedPlaceholder = nil;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if(placeholderArray[@(textField.tag)] != nil)
    {
        textField.attributedPlaceholder = placeholderArray[@(textField.tag)];
    }
}

- (void)setLoading:(BOOL)loading message:(NSString *)message {
    if (loading) {
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        if (window != nil) {
            hud = [MBProgressHUD showHUDAddedTo: window animated:YES];
        }
        else {
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = message;
    }
    else if (hud != nil) {
        [hud hideAnimated:YES];
    }
}

- (void) closeAlert {
    [self dismissViewControllerAnimated: YES completion:^{
        if (self.alertCompletion != nil) {
            self.alertCompletion(YES);
            self.alertWithoutButtons = nil;
        }
    }];
}

- (void)showAlertWithoutButtons:(NSString*)title message:(NSString*)message onDone:(OnDone)onDone {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    self.alertCompletion = onDone;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(closeAlert)];
    
    self.alertWithoutButtons = alert;
    [self presentViewController: alert animated: YES completion:^{
        alert.view.superview.userInteractionEnabled = YES;
        [alert.view.superview addGestureRecognizer: tapGestureRecognizer];
    }];
}

- (void)showAlert:(NSString*)title message:(NSString*)message {
    [self showAlert:title message:message onDone:nil];
}

- (void)showAlert:(NSString*)title message:(NSString*)message onDone:(OnDone)onDone {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Okay"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    if (onDone != nil) {
                                        onDone(YES);
                                    }
                                }];
    
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertYesOrNo:(NSString*)title message:(NSString*)message yesButtonTitle: (NSString*) yesButtonTitle noButtonTitle: (NSString*) noButtonTitle onDone:(OnDone)onDone {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle: yesButtonTitle
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    if (onDone != nil) {
                                        onDone(YES);
                                    }
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle: noButtonTitle
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   if (onDone != nil) {
                                       onDone(NO);
                                   }
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self presentViewController: alert animated: YES completion: nil];
}

- (void)showAlertYesOrNo:(NSString*)title message:(NSString*)message result:(OnDone)onDone{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    if (onDone != nil) {
                                        onDone(YES);
                                    }
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   if (onDone != nil) {
                                       onDone(NO);
                                   }
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showVerifyEmailAlert:(OnDone)onDone {
    [self showAlert:@"Verify your email" message:@"A six digit Verification code has been sent to your email id. Please enter the code to verify your email." onDone:onDone];
}

- (void)configKeyboard{
    _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:_gestureRecognizer];
    _gestureRecognizer.cancelsTouchesInView = NO;
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void) showBLEConnectionError {
    [self showAlert: @"Device is not connected" message: @"Please pair your smart handle first" onDone:^(BOOL result) {
        [self showPairViewController: YES];
    }];
}

- (void) showPairViewController: (BOOL) animated {
    UIViewController *vc = [[UIStoryboard storyboardWithName: @"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"DeviceListViewController"];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController: nav animated:animated completion: nil];
}

- (void)makeBackground{
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    CAGradientLayer *blueWhite = [CAGradientLayer layer];
    blueWhite.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height * 0.2);
    blueWhite.colors = @[(id)[UIColor turquoiseColor].CGColor, (id)[UIColor whiteColor].CGColor];
    [self.view.layer insertSublayer:blueWhite atIndex:0];
    
    CAGradientLayer *whiteGreen = [CAGradientLayer layer];
    whiteGreen.frame = CGRectMake(0, self.view.frame.size.height * 0.45, self.view.frame.size.width, self.view.frame.size.height);
    whiteGreen.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor appPrimaryColor].CGColor];
    [self.view.layer insertSublayer:whiteGreen atIndex:0];
}

- (void)finish {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Rotation

-(BOOL)shouldAutorotate {
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end

