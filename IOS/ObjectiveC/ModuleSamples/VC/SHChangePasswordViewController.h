//
//  SHChangePasswordViewController.h
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextFieldWithInsets.h"

@interface SHChangePasswordViewController : UIViewController
<
	UITextFieldDelegate,
	UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UIButton *changeButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


- (IBAction)changeButtonPressed:(id)sender;

@end
