//
//  SHSettingsPushNotificationViewController.m
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import "SHSettingsPushNotificationViewController.h"
#import "SHSettingsPushCell.h"

#import "SHDesignHelper.h"
#import "SHToolbox.h"
#import "SHCommon.h"
#import "SHDataManager.h"
#import "SHLoginManager.h"
#import "NSManagedObjectContext+Extensions.h"
#import "SHGAIHelper.h"
#import "UIColor+RGBColor.h"

@interface SHSettingsPushNotificationViewController () <SHSettingsPushCellDelegate>
{
    SHNotificationsMask _currentMask;
    BOOL _changesPending;
}

@end

@implementation SHSettingsPushNotificationViewController

static NSArray *notificationTypeMasks;
static NSDictionary *notificationTypeTitles;

+ (void)initialize {
    notificationTypeMasks = @[ @(SHFriendMakeNotificationMask), @(SHFriendAcceptNotificationMask), @(SHFriendRejectNotificationMask), @(SHFriendUnfriendNotificationMask), @(SHListShareNotificationMask), @(SHListUnshareNotificationMask), @(SHListUnshareMeNotificationMask), @(SHListChangedNotificationMask), @(SHListRemovedNotificationMask) ];
    notificationTypeTitles = @{ @(SHFriendMakeNotificationMask) : NSLocalizedString(@"Somebody wants to be your friend", @"Notification type"),
                                @(SHFriendAcceptNotificationMask) : NSLocalizedString(@"Somebody confirmed offer", @"Notification type"),
                                @(SHFriendRejectNotificationMask) : NSLocalizedString(@"Somebody rejected offer", @"Notification type"),
                                @(SHFriendUnfriendNotificationMask) : NSLocalizedString(@"Somebody removed you from friendlist", @"Notification type"),
                                @(SHListShareNotificationMask) : NSLocalizedString(@"Friend shared list with you", @"Notification type"),
                                @(SHListUnshareNotificationMask) : NSLocalizedString(@"Friend removed you from a list", @"Notification type"),
                                @(SHListUnshareMeNotificationMask) : NSLocalizedString(@"Friend removed himself from your list", @"Notification type"),
                                @(SHListChangedNotificationMask) : NSLocalizedString(@"Friend changed a list", @"Notification type"),
                                @(SHListRemovedNotificationMask) : NSLocalizedString(@"Friend removed a list", @"Notification type") };
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.preferredContentSize = CGSizeMake(320, 480);
        _currentMask = [SHLoginManager sharedInstance].currentUser.notificationsMask.integerValue;
    }
    
    return self;
}

- (NSString *)title {
    return NSLocalizedString(@"Notifications", @"Notifications");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [SHGAIHelper sendDefaultTrackerScreenViewWithName:@"PushNotificationsSettings"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveChangesIfNecessary];
}

#pragma mark - Saving changes

- (void)saveChangesIfNecessary {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    if (!_changesPending) {
        return;
    }
    
    _changesPending = NO;
    NSManagedObjectContext *scratchContext = [[SHDataManager sharedInstance] newScratchContext];
    SHUser *scratchUser = (SHUser *)[scratchContext instanceOfManagedObject:[SHLoginManager sharedInstance].currentUser];
    if (_currentMask == scratchUser.notificationsMask.integerValue) {
        return;
    }
    
    [self saveChangesForUser:scratchUser];
}

- (void)saveChangesForUser: (SHUser *)user {
    user.notificationsMask = @(_currentMask);
    
    [[SHDataManager sharedInstance] updateUser:user withCompletion:^(NSError *error) {
        if (error != nil) {
            [SHToolbox showErrorAlertWithTitle:NSLocalizedString(@"Failed to save", @"User save error") andError:error];
        }
    }];
}

- (void)saveChangesDeferred {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveChangesIfNecessary) object:nil];
    [self performSelector:@selector(saveChangesIfNecessary) withObject:nil afterDelay:1.0];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return notificationTypeMasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHSettingsPushCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SHSettingsPushCell"];
    if (cell == nil) {
        cell = [SHSettingsPushCell cellFromNib];
        cell.delegate = self;
    }
    
    NSNumber *maskNumber = notificationTypeMasks[indexPath.row];
    NSString *title = notificationTypeTitles[maskNumber];

    NSInteger maskValue = maskNumber.integerValue;
    BOOL isActive = (_currentMask & maskValue) > 0;

    [cell setupWithTitle:title on:isActive];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHSettingsPushCell *cell = (SHSettingsPushCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setOn:!cell.on animated:YES];
    
    [self settingPushCell:cell didSetOn:cell.on];
}

- (void)settingPushCell:(SHSettingsPushCell *)cell didSetOn:(BOOL)on {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSInteger maskValue = [notificationTypeMasks[indexPath.row] integerValue];
    
    if (on) {
        _currentMask |= maskValue;
    } else {
        _currentMask &= ~maskValue;
    }
    
    _changesPending = YES;
    [self saveChangesDeferred];
}

@end
