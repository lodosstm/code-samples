//
//  SHChangePasswordViewController.m
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import "SHChangePasswordViewController.h"
#import "SHDesignHelper.h"
#import "SHToolbox.h"
#import "SHLoginManager.h"
#import "NSString+Tools.h"
#import "MBProgressHUD+Conveniency.h"
#import "SHGAIHelper.h"
#import "SHTextFieldCell.h"
#import "UIColor+SHPalette.h"

typedef enum : NSInteger
{
	SHTextViewTag_old = 0,
	SHTextViewTag_new,
	SHTextViewTag_confirm,
} SHTextViewTag;

@interface SHChangePasswordViewController ()

- (void) giveFirstResponderToUsernameTextField;
- (UITextField *) textFieldWithTag:(SHTextViewTag) tag;
- (void) registerNibForCell;
- (void) tableView:(UITableView *)tableView configureCell:(SHTextFieldCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation SHChangePasswordViewController

- (NSString *)title {
    return NSLocalizedString(@"Change Password", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self registerNibForCell];
}

- (void) registerNibForCell {
	UINib *nib = [UINib nibWithNibName:NSStringFromClass([SHTextFieldCell class])
								bundle:nil];
	[self.tableView registerNib:nib forCellReuseIdentifier:[SHTextFieldCell reuseIdentifier]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [SHGAIHelper sendDefaultTrackerScreenViewWithName:@"ChangePassword"];
}

- (void) giveFirstResponderToUsernameTextField {
	UITextField *field = [self textFieldWithTag:SHTextViewTag_old];
	
	[field becomeFirstResponder];
}

#pragma mark - UITableViewDelegate methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ( section == 0 ) ?3 :0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	SHTextFieldCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:[SHTextFieldCell reuseIdentifier]
										   forIndexPath:indexPath];
	NSParameterAssert( cell );
	[self tableView:tableView configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void) tableView:(UITableView *)tableView configureCell:(SHTextFieldCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	NSArray *dictPlaceholder = @
	[
		NSLocalizedString( @"Old Password", nil ),
		NSLocalizedString( @"New Password", nil ),
		NSLocalizedString( @"Confirm New Password", nil ),
	];
	
	SHTextViewTag tag = SHTextViewTag_old + indexPath.row;
	BOOL returnButtonIsNext = ( tag != SHTextViewTag_confirm );
	
	cell.contextText.tag = tag;
	cell.contextText.delegate = self;
	cell.contextText.placeholder = dictPlaceholder[ indexPath.row ];
	cell.contextText.secureTextEntry = YES;
	cell.contextText.returnKeyType = ( returnButtonIsNext )
			?UIReturnKeyNext
			:UIReturnKeyDone;
    
    if (indexPath.row == 0) {
        cell.cornerMask = UIRectCornerTopLeft|UIRectCornerTopRight;
    }
    if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
        cell.cornerMask = UIRectCornerBottomLeft|UIRectCornerBottomRight;
    }
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:cell.contextText attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:43.0];
    [cell.contextText addConstraint:heightConstraint];
}

#pragma mark - IBAction

- (IBAction)changeButtonPressed:(id)sender {
    [self validateAndChangePassword];
}

- (void)validateAndChangePassword {
    NSAssert(![SHLoginManager sharedInstance].isSkippedIn, @"Shouldn't be able to change password in skip mode!");
    
    UITextField *textField_old        = [self textFieldWithTag:SHTextViewTag_old];
    UITextField *textField_new        = [self textFieldWithTag:SHTextViewTag_new];
    UITextField *textField_confirm    = [self textFieldWithTag:SHTextViewTag_confirm];
    
    NSString *oldPassword            = [textField_old.text cleanString];
    NSString *newPassword            = [textField_new.text cleanString];
    NSString *confirmPassword        = [textField_confirm.text cleanString];
    
    if( oldPassword.length == 0 ) {
        [self handleOldPasswordInvalid];
    } else if( newPassword.length == 0 ) {
        [self handleNewPasswordInvalid];
    } else if( ![SHLoginManager isPasswordStrong:newPassword] ) {
        [self handleWeakPassword];
    } else if( ![newPassword isEqualToString:confirmPassword] ) {
        [self handlePasswordsDontMatch];
    } else {
        [self.view endEditing:YES];
        [self updatePassword:oldPassword with:newPassword];
    }
}

- (void)handleOldPasswordInvalid {
    UITextField *textField_old = [self textFieldWithTag:SHTextViewTag_old];
    NSString *desc = NSLocalizedString( @"Please enter your old password.", nil );
    [SHToolbox showErrorAlertWithTitle:nil andDescription:desc];
    [textField_old becomeFirstResponder];
}

- (void)handleNewPasswordInvalid {
    UITextField *textField_new = [self textFieldWithTag:SHTextViewTag_new];
    NSString *desc = NSLocalizedString( @"Please enter your new password.", nil );
    [SHToolbox showErrorAlertWithTitle:nil andDescription:desc];
    [textField_new becomeFirstResponder];
}

- (void)handleWeakPassword {
    UITextField *textField_new = [self textFieldWithTag:SHTextViewTag_new];
    NSString *desc = NSLocalizedString(@"Password must have not less then 6 with one digit and one character.", nil);
    [SHToolbox showErrorAlertWithTitle:nil andDescription:desc];
    [textField_new becomeFirstResponder];
}

- (void)handlePasswordsDontMatch {
    UITextField *textField_new = [self textFieldWithTag:SHTextViewTag_new];
    UITextField *textField_confirm = [self textFieldWithTag:SHTextViewTag_confirm];
    NSString *desc = NSLocalizedString(@"Passwords don't match. Please enter your password again.", nil);
    [SHToolbox showErrorAlertWithTitle:nil andDescription:desc];
    textField_new.text = @"";
    textField_confirm.text = @"";
    [textField_new becomeFirstResponder];
}

- (void)updatePassword: (NSString *)oldPassword with: (NSString *)newPassword {
    __weak MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view withLabelText:NSLocalizedString(@"Changing Password...", @"Password change progress title") animated:YES];
    
    [[SHLoginManager sharedInstance] updatePassword:oldPassword withPassword:newPassword withCompletion:^(NSError *error) {
        [hud hide:NO];
        if (error != nil) {
            [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Error", @"Error") andError:error];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
            [SHToolbox showErrorAlertWithTitle:nil andDescription:NSLocalizedString(@"Password changed successfully.", @"Password Change successful message")];
            
            [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Login" action:@"ChangedPassword" label:nil value:0];
        }
    }];
}

#pragma mark - UITextFieldDelegate methods

- (UITextField *) textFieldWithTag:(SHTextViewTag) tag {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:( tag - SHTextViewTag_old )
                                                inSection:0];
    SHTextFieldCell *cell = (SHTextFieldCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    return cell.contextText;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	SHTextViewTag tag = (SHTextViewTag)textField.tag;
	if( tag == SHTextViewTag_old ) {
		[[self textFieldWithTag:SHTextViewTag_new] becomeFirstResponder];
	} else if( tag == SHTextViewTag_new ) {
		[[self textFieldWithTag:SHTextViewTag_confirm] becomeFirstResponder];
	} else {
		[self changeButtonPressed:textField];
	}
	return NO;
}

@end
