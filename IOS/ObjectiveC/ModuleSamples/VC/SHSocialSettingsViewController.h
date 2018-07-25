//
//  SHSocialSettingsViewController.h
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHSocialSettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *facebookView;
@property (weak, nonatomic) IBOutlet UILabel *facebookMainLabel;
@property (weak, nonatomic) IBOutlet UIImageView *accessoryImageView;

- (IBAction)facebookButtonPressed:(id)sender;

@end
