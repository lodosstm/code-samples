//
//  DataManager.h
//
//  Copyright © 2016 Lodossteam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkManager.h"

@interface DataManager : NSObject

+ (void)userPrecacheByID:(NSString *)userID;
+ (void)postPrecacheByID:(NSString *)postID;

+ (void)wipeLocalStoreRecords;

@end
