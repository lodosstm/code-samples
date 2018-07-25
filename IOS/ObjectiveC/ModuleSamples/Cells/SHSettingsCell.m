//
//  SHSettingsCell.m
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import "SHSettingsCell.h"
#import "SHToolbox.h"

@implementation SHSettingsCell

+ (SHSettingsCell *)cellFromNib {
    return (SHSettingsCell *)[SHToolbox cellFromNibNamed:@"SHSettingsCell"];
}

+ (NSString *)reuseIdentifier {
    return @"SHSettingsCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.15f];
    self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chevron"]];
}

@end
