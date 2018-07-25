//
//  SHSettingsCell.h
//
//  Copyright (c) 2013 Lodoss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHSettingsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

+ (SHSettingsCell *)cellFromNib;

@end
