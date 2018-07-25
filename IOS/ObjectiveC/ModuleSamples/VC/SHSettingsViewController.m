//
//  SHSettingsViewController.m
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import "SHSettingsViewController.h"

#import "SHLoginManager.h"
#import "SHDataManager.h"
#import "SHPurchaseManager.h"
#import "SHUser+Extensions.h"

#import "SHPurchaseViewController.h"
#import "SHSettingsPushNotificationViewController.h"
#import "SHChangePasswordViewController.h"
#import "SHSocialSettingsViewController.h"
#import "SHSettingsCell.h"

#import "SHDesignHelper.h"
#import "SHGAIHelper.h"
#import "SHAppDelegate.h"
#import "SHGlobalAlertsHelper.h"

#import "UIColor+RGBColor.h"

@interface SHSettingsViewController()
{
    BOOL _showsPasswordChange;
}

@property (strong, nonatomic, readonly) NSArray *menuItems;

@end

@implementation SHSettingsViewController

static const NSInteger kSHSettingsPushNotificationsItem = 100;
static const NSInteger kSHSettingsChangePasswordItem = 101;
static const NSInteger kSHSettingsSocialItem = 102;

@synthesize menuItems = _menuItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setupNavigationBar];
        
        self.preferredContentSize = CGSizeMake(320, 480);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupNavigationBar {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Log out", @"Log out") style:UIBarButtonItemStyleBordered target:self action:@selector(logout)];
    [SHDesignHelper setupNavBarButtonItem:self.navigationItem.rightBarButtonItem];
}

+ (BOOL)shouldShowPasswordChange {
    return [SHLoginManager sharedInstance].currentUser.isPasswordSet.boolValue;
}

- (NSArray *)menuItems {
    if (_menuItems != nil) {
        return _menuItems;
    }
    
    _showsPasswordChange = NO;
    if ([SHLoginManager sharedInstance].isSkippedIn) {
        _menuItems = @[ ];
    } else {
        NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:3];
        
        [menuItems addObject:@{ @"title" : NSLocalizedString(@"Notifications", @"Notifications"), @"tag" : @(kSHSettingsPushNotificationsItem) }];
        if ([self.class shouldShowPasswordChange]) {
            [menuItems addObject:@{ @"title" : NSLocalizedString(@"Change Password", nil), @"tag" : @(kSHSettingsChangePasswordItem) }];
            _showsPasswordChange = YES;
        }
        [menuItems addObject:@{ @"title" : NSLocalizedString(@"Social Networks", @"Social Networks"), @"tag" : @(kSHSettingsSocialItem) }];
        
        _menuItems = [menuItems copy];
    }
    
    return _menuItems;
}

- (NSString *)title {
    return NSLocalizedString(@"Settings", @"Settings");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if DEBUG || ADHOC
    NSString *buildNumberString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    self.versionLabel.text = [NSString stringWithFormat:@"v.%@", buildNumberString];
    self.versionLabel.hidden = NO;
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePaidStatus) name:SHPurchaseManagerPurchaseSuccessfulNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *selectedRow = self.tableView.indexPathForSelectedRow;
    if (selectedRow != nil) {
        [self.tableView deselectRowAtIndexPath:selectedRow animated:animated];
    }

    [self updatePaidStatus];
    
    // reset menu items and reload table if password state changes
    if ([self.class shouldShowPasswordChange] != _showsPasswordChange) {
        _menuItems = nil;
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [SHGAIHelper setDefaultTrackerScreenName:@"Settings"];
}

- (void)updatePaidStatus {
    if (![SHPurchaseManager sharedInstance].isAppPurchased) {
        self.tableView.tableFooterView = self.buyView;
    } else {
        self.tableView.tableFooterView = [[UIView alloc] init];
    }
}

- (void)logout {
    [SHGlobalAlertsHelper showLogoutSequenceWithConfirmationInView:self.view];
}

- (void)requestPurchase {
    [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Purchase" action:@"PressedInSettings" label:nil value:0];
    
    [[SHAppDelegate instance] showProgressView];
    [[SHPurchaseManager sharedInstance] requestAppPurchaseWithCompletion:^(NSError *error) {
        [[SHAppDelegate instance] hideProgressView];
        
        if (error != nil) {
            if (error.code != SKErrorPaymentCancelled) {
                [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Purchase Error", @"IAP purchase error title") andError:error];
                [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Purchase" action:@"Failed" label:@(error.code).stringValue value:0];
            } else {
                [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Purchase" action:@"Cancelled" label:nil value:0];
            }
        } else {
            [SHPurchaseViewController showPurchaseSuccessfulAlert];
            
            [SHGAIHelper sendDefaultTrackerEventWithCategory:@"Purchase" action:@"Successful" label:nil value:0];
        }        
    }];
}

- (void)restorePurchase {
    [[SHAppDelegate instance] showProgressView];
    
    [[SHPurchaseManager sharedInstance] restoreAppPurchaseWithCompletion:^(NSError *error) {
        [[SHAppDelegate instance] hideProgressView];
        
        if (error != nil) {
            if (error.code != SKErrorPaymentCancelled) {
                [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Purchase Restoration Error", @"IAP purchase restoration error title") andError:error];
            }
        }
    }];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SHSettingsCell"];
    if (cell == nil) {
        cell = [SHSettingsCell cellFromNib];
    }
    
    NSDictionary *item = self.menuItems[indexPath.row];
    cell.titleLabel.text = item[@"title"];
    
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.menuItems[indexPath.row];
    switch ([item[@"tag"] integerValue]) {
        case kSHSettingsPushNotificationsItem:
        {
            SHSettingsPushNotificationViewController *vc = [[SHSettingsPushNotificationViewController alloc] initWithNibName:@"SHSettingsPushNotificationViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case kSHSettingsChangePasswordItem:
        {
            SHChangePasswordViewController *vc = [[SHChangePasswordViewController alloc] initWithNibName:@"SHChangePasswordViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case kSHSettingsSocialItem:
        {
            SHSocialSettingsViewController *vc = [[SHSocialSettingsViewController alloc] initWithNibName:@"SHSocialSettingsViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - IBAction

- (IBAction)buyPressed:(id)sender {
    if (![SHPurchaseManager canPurchase]) {
        [SHPurchaseViewController showPurchasesUnavailableAlert];
        
        return;
    }
    
    [self requestPurchase];
}

- (IBAction)restoreButtonPressed:(id)sender {
    [self restorePurchase];
}

@end
