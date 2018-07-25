//
//  SHSocialSettingsViewController.m
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import "SHSocialSettingsViewController.h"
#import "SHLoginManager.h"
#import "SHDataManager.h"
#import "SHFacebookManager.h"
#import "SHDesignHelper.h"
#import "SHGAIHelper.h"
#import "MBProgressHUD+Conveniency.h"
#import "SHGlobalAlertsHelper.h"
#import <UIActionSheet+Blocks.h>
#import "UIColor+RGBColor.h"
#import "UIColor+SHPalette.h"

@implementation SHSocialSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.preferredContentSize = CGSizeMake(320, 480);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)title {
    return NSLocalizedString(@"Social Networks", @"Social Networks");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupFacebookUI];
    [self setupSeparators];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupFacebookUI) name:SHFacebookUserDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [SHGAIHelper sendDefaultTrackerScreenViewWithName:@"SocialSettings"];
}

- (void)setupFacebookUI {
    if ([SHFacebookManager sharedInstance].isSessionOpen) {
        [self setupFacebookUIForOpenSession];
    } else {
        [self setupFacebookUIForNotOpenedSession];
    }
}

- (void)setupFacebookUIForOpenSession {
    self.facebookMainLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Connected", @"Connected")];
    self.facebookMainLabel.textColor = [UIColor orangeColor_SH];
    self.accessoryImageView.image = [UIImage imageNamed:@"ic_ok"];
}

- (void)setupFacebookUIForNotOpenedSession {
    self.facebookMainLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Connected", @"Connected")];
    self.facebookMainLabel.textColor = [UIColor orangeColor_SH];
    self.accessoryImageView.image = [UIImage imageNamed:@"ic_ok"];
}

- (void)setupSeparators {
    CGFloat separatorHeight = 1.0f / [[UIScreen mainScreen] scale];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, self.facebookView.bounds.size.height - separatorHeight, 320, separatorHeight)];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        view.backgroundColor = [UIColor colorWithHexString:@"dfdfe7"];
    } else {
        view.backgroundColor = [UIColor colorWithHexString:@"c8c7cc"];
    }
    [self.facebookView addSubview:view];
}

- (void)connectFacebook {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view withLabelText:NSLocalizedString(@"Connecting Facebook...", @"Connecting Facebook spinner") animated:YES];
    hud.dimBackground = YES;
    
    [[SHFacebookManager sharedInstance] authorizeFacebookAndLoadProfileFromController:self withCompletion:^(BOOL completed, NSError *error) {
        if (!completed && error == nil) {
            [hud hide:YES];
            
            return;
        }
        if (!completed || error != nil) {
            [hud hide:NO];
            [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Facebook Error", @"Facebook Error") andError:error];
            
            return;
        }
        
        [[SHFacebookManager sharedInstance] sendFacebookConnectIfNecessaryWithCompletion:^(NSError *connectError) {
            [hud hide:(connectError == nil)];
            if (connectError != nil) {
                [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Error", @"Error") andError:connectError];
            }
            // view will be refreshed due to notification if authentication is successful
        }];
    }];
}

- (void)disconnectFacebook {
    UIActionSheet *actionSheet = nil;
    
    if ([SHLoginManager sharedInstance].isLoggedInViaFacebook) {
        actionSheet = [self disconnectFacebookUserActionSheet];
        [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Login" action:@"Logout" label:nil value:0];
    } else {
        actionSheet = [self disconnectOrdinaryUserActionSheet];
        [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Social" action:@"DisconnectFacebook" label:nil value:0];
    }
    
    [self show:actionSheet];
}

- (UIActionSheet *)disconnectFacebookUserActionSheet {
    // if user is logged in using Facebook, offer logging out
    UIActionSheet *actionSheet = nil;
    actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"$Facebook_Login_Disconnect$", @"Facebook login disconnect prompt") delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:NSLocalizedString(@"Log out", @"Log out") otherButtonTitles:nil];
    actionSheet.tapBlock = ^(UIActionSheet *anActionSheet, NSInteger buttonIndex) {
        if (buttonIndex == anActionSheet.cancelButtonIndex) {
            return;
        }
        [SHGlobalAlertsHelper showLogoutSequence];
    };
    
    return actionSheet;
}

- (UIActionSheet *)disconnectOrdinaryUserActionSheet {
    // just show disconnect prompt
    UIActionSheet *actionSheet = nil;
    __weak typeof(self) weakSelf = self;
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:NSLocalizedString(@"Disconnect", @"Facebook disconnect") otherButtonTitles:nil];
    actionSheet.tapBlock = ^(UIActionSheet *anActionSheet, NSInteger buttonIndex) {
        if (buttonIndex == anActionSheet.cancelButtonIndex) {
            return;
        }
        
        [weakSelf disconnectFacebookAccount];
    };
    
    return actionSheet;
}

- (void)disconnectFacebookAccount {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view withLabelText:NSLocalizedString(@"Disconnecting...", @"Facebook disconnect spinner") animated:YES];
    hud.dimBackground = YES;
    
    [[SHDataManager sharedInstance] disconnectFacebookAccountWithCompletion:^(NSError *error) {
        [hud hide:(error == nil)];
        if (error == nil) {
            // actually logout from Facebook only if disconnect was successful
            [[SHFacebookManager sharedInstance] logoutFacebook];
            // view will be refreshed due to notification
        } else {
            [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Error", @"Error") andError:error];
        }
    }];
}

- (void)show: (UIActionSheet *)actionSheet {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [actionSheet showInView:self.view];
    } else {
        [actionSheet showInView:self.tabBarController.view];
    }
}

- (IBAction)facebookButtonPressed: (id)sender {
    if (![SHFacebookManager sharedInstance].isSessionOpen) {
        [self connectFacebook];
        [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Social" action:@"ConnectFacebookFromSettings" label:nil value:0];
    } else {
        [self disconnectFacebook];
    }
}

@end
