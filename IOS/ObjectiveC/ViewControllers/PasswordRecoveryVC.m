//
//  PasswordRecoveryVC.m
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import "PasswordRecoveryVC.h"
#import "NetworkManager.h"
#import "NSString+Extensions.h"
#import "ColorsManager.h"
#import "DataValidator.h"

@interface PasswordRecoveryVC () <UITextViewDelegate, UITextFieldDelegate>

- (IBAction)backButtonPress:(UIButton *)sender;
- (IBAction)resetPasswordButtonPress:(UIButton *)sender;
- (IBAction)editFieldTextChanged:(UITextField *)sender;

@property (strong, nonatomic) IBOutlet UITextField *emailAdressTextField;

@property (strong, nonatomic) IBOutlet UIButton *resetPasswordButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *errorMessagesOutputLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainTopLabel;
@property (strong, nonatomic) IBOutlet UIView *emailAdressTextFieldUnderliner;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *resetPasswordButtonTopMargin;

@property (strong, nonatomic) IBOutlet UIButton *emailConfirmationButton;
@property (strong, nonatomic) IBOutlet UILabel *emailWarningLabel;

@end

@implementation PasswordRecoveryVC

#pragma mark - VC Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupButtonsStyle];
    [self setupInputIndicatorColors];
    [self setupFieldsTextChangeHandlers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Init

- (void)setupButtonsStyle {
    [self setupResetPasswordButtonStyle];
}

- (void)setupResetPasswordButtonStyle {
    self.resetPasswordButton.layer.cornerRadius = self.resetPasswordButton.frame.size.height / 6;
}

- (void)setupInputIndicatorColors {
    UIColor *inputFieldInputIndicatorColor = [ColorsManager blue2D87D7AppMainColor];
    self.emailAdressTextField.tintColor = inputFieldInputIndicatorColor;
}


- (void)setupFieldsTextChangeHandlers {
    [self.emailAdressTextField addTarget:self
                                  action:@selector(editFieldTextChanged:)
                        forControlEvents:UIControlEventEditingChanged];
    
    [self editFieldTextChanged:nil];
}

#pragma mark - IBActions

- (IBAction)backButtonPress:(UIButton *)sender {
    [self dismissView];
}

- (IBAction)resetPasswordButtonPress:(UIButton *)sender {
    [self resetErrorMessagesOutput];
    [self resetPassword];
}

- (IBAction)editFieldTextChanged:(UITextField *)sender {
    BOOL isCanEnableMainButton = (![NSString isNilOrEmpty:self.emailAdressTextField.text]);
    if (isCanEnableMainButton) {
        isCanEnableMainButton = [DataValidator stringIsValidEmail:_emailAdressTextField.text];
    }
    
    if (isCanEnableMainButton) {
        if (!_emailWarningLabel.hidden) {
            _emailWarningLabel.hidden = YES;
            [self updateConstraintsAndColor];
            [self updateConfirmImages];
        }
        self.resetPasswordButton.enabled = YES;
        self.resetPasswordButton.alpha = 1;
    } else {
        self.resetPasswordButton.enabled = NO;
        self.resetPasswordButton.alpha = 0.5;
    }
}

#pragma mark - Actions

- (void)resetPassword {
    NSString *email = self.emailAdressTextField.text;
    [self resetPasswordForEmail:email];
}

- (void)resetPasswordForEmail:(NSString *)email {
    UIActivityIndicatorView *indicator = [self disableLoginControls];
    
    __weak __typeof(self)weakSelf = self;
    [NetworkManager passwordRecoveryForEmail:email success:^(NSDictionary *resonseDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf enableLoginControls:indicator];
            [strongSelf successfullySendRecovery:^{
            }];
        });
    } error:^(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf enableLoginControls:indicator];
            [strongSelf setErrorMessagesText:errorDescriptionText];
        });
    } cleanup:^{}];
}

- (void)successfullySendRecovery:(void (^)())cleanup {
    self.emailAdressTextField.enabled = NO;
    self.resetPasswordButton.hidden = YES;
    self.emailAdressTextFieldUnderliner.hidden = YES;
    self.mainTopLabel.text = kSuccessfulSendTiEMailMessage;
}

- (void)resetErrorMessagesOutput {
    self.errorMessagesOutputLabel.text = @"";
}

- (void)setErrorMessagesText:(NSString *)errorMessage {
    if ([errorMessage isEqualToString:kNoSuchUserErrorMsg]) {
        _emailWarningLabel.text = kNotRegisteredEmailWarning;
        _emailWarningLabel.hidden = NO;

        self.resetPasswordButton.enabled = NO;
        self.resetPasswordButton.alpha = 0.5;
 
        [self updateConstraintsAndColor];
        [self updateConfirmImages];
    }
}

- (UIActivityIndicatorView *)disableLoginControls {
    self.emailAdressTextField.enabled = NO;
    self.resetPasswordButton.enabled = NO;
    self.resetPasswordButton.alpha = 0.5;
    
    CGRect defFrame = CGRectMake(0, 0, 50, 50);
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:defFrame];
    indicator.center = CGPointMake((self.resetPasswordButton.center.x / 2), self.resetPasswordButton.center.y);
    indicator.hidesWhenStopped = YES;
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.scrollView addSubview:indicator];
    [indicator startAnimating];
    
    return indicator;
}

- (void)enableLoginControls:(UIActivityIndicatorView *)indicator {
    self.emailAdressTextField.enabled = YES;
    self.resetPasswordButton.enabled = YES;
    self.resetPasswordButton.alpha = 1;
    
    [indicator stopAnimating];
    [indicator removeFromSuperview];
}

- (void) updateConstraintsAndColor {
    if (_emailWarningLabel.hidden) {
        _emailAdressTextFieldUnderliner.backgroundColor = [ColorsManager grayE1E3E0TextViewBorder];
    } else {
        if ([_emailWarningLabel.text isEqualToString:kNotRegisteredEmailWarning]) {
            _emailAdressTextFieldUnderliner.backgroundColor = [ColorsManager redEC6A5D];
        } else {
            _emailAdressTextFieldUnderliner.backgroundColor = [ColorsManager redEC6A5D];
        }
    }
}

- (void) updateConfirmImages {
    if (_emailWarningLabel.hidden) {
        if ([NSString isNilOrEmpty:_emailAdressTextField.text]) {
            _emailConfirmationButton.hidden = YES;
        } else {
            [_emailConfirmationButton setImage:[UIImage imageNamed:@"Selected"] forState:UIControlStateNormal];
            _emailConfirmationButton.hidden = NO;
        }
    } else {
        [_emailConfirmationButton setImage:[UIImage imageNamed:@"Warning"] forState:UIControlStateNormal];
        _emailConfirmationButton.hidden = NO;
    }
}

#pragma mark - Other

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([_emailWarningLabel.text isEqualToString:kNotRegisteredEmailWarning]) {
        _emailWarningLabel.hidden = YES;
        [self updateConstraintsAndColor];
        [self updateConfirmImages];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (![_emailAdressTextField.text isEqualToString:@""]) {
        if ([DataValidator stringIsValidEmail:_emailAdressTextField.text]) {
            _emailWarningLabel.hidden = YES;
        } else {
            _emailWarningLabel.text = kInvalidEmailWarning;
            _emailWarningLabel.hidden = NO;
        }
    }
    
    [self updateConstraintsAndColor];
    [self updateConfirmImages];
}

#pragma mark - Segues

- (void)dismissView {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
