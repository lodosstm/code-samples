//
//  SharePostVC.h
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "RefreshableProtocol.h"

@interface SharePostVC : UIViewController

- (void)setupWithPost:(Post *)post andParentVC:(id <RefreshableProtocol>)parent;

@property (weak, nonatomic) UITableView *parentViewTableView;

@end
