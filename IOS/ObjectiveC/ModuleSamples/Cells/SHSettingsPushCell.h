//
//  SHSettingsCell.h
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SHSettingsPushCell;

@protocol SHSettingsPushCellDelegate <NSObject>

- (void)settingPushCell:(SHSettingsPushCell *)cell didSetOn:(BOOL)on;

@end

@interface SHSettingsPushCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;

@property (weak, nonatomic) id<SHSettingsPushCellDelegate> delegate;
@property (assign, nonatomic) BOOL on;

- (IBAction)valueChanged:(id)sender;

+ (SHSettingsPushCell *)cellFromNib;

- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)setupWithTitle:(NSString *)title on:(BOOL)on;

@end
