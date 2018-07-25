//
//  SHSettingsCell.m
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import "SHSettingsPushCell.h"
#import "SHToolbox.h"
#import "UIColor+SHPalette.h"

@implementation SHSettingsPushCell

+ (SHSettingsPushCell *)cellFromNib {
    return (SHSettingsPushCell *)[SHToolbox cellFromNibNamed:@"SHSettingsPushCell"];
}

+ (NSString *)reuseIdentifier {
    return @"SHSettingsPushCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
}

- (BOOL)on {
    return self.notificationSwitch.on;
}

- (void)setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    [self.notificationSwitch setOn:on animated:animated];
}

- (void)setupWithTitle:(NSString *)title on:(BOOL)on {
    self.titleLabel.text = title;
    [self setOn:on animated:NO];
}

- (IBAction)valueChanged:(id)sender {
    [self.delegate settingPushCell:self didSetOn:self.notificationSwitch.on];
}

@end
