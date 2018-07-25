//
//  SHSettingsViewController.h
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIView *progressView;

@property (strong, nonatomic) IBOutlet UIView *buyView;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

- (IBAction)buyPressed:(id)sender;
- (IBAction)restoreButtonPressed:(id)sender;

@end
