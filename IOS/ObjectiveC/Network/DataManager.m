//
//  DataManager.m
//
//  Copyright © 2016 Lodossteam. All rights reserved.
//

#import "DataManager.h"
#import "UserDBobjectManager.h"
#import "UserDBobjectPrecacher.h"
#import "PostDBobjectManager.h"
#import "PostDBobjectPrecacher.h"


@implementation DataManager

+ (void)userPrecacheByID:(NSString *)userID {
    [[UserDBobjectPrecacher sharedInstance] cacheUserWithID:userID withErrorOnUserDeletedOnServerBlock:^(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict) {
        [DataManager errorResponseHandleForUserID:userID withErrorext:errorDescriptionText];
    }];
}

+ (void)postPrecacheByID:(NSString *)postID {
    [[PostDBobjectPrecacher sharedInstance] cachePostWithID:postID withErrorOnUserDeletedOnServerBlock:^(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict) {
        [DataManager errorResponseHandleForPostID:postID withErrorext:errorDescriptionText];
    }];
}

+ (void)errorResponseHandleForPostID:(NSString *)postID withErrorext:(NSString *)errorDescriptionText {
    if ([errorDescriptionText isEqualToString:kPostNotFoundMsg])
        [PostDBobjectManager deletePostDBobjectFromDBWithPostID:postID];
}

+ (void)errorResponseHandleForUserID:(NSString *)userID withErrorext:(NSString *)errorDescriptionText {
    if ([errorDescriptionText isEqualToString:kUserNotFoundMsg])
        [UserDBobjectManager deleteUserDBobjectFromDBWithUserID:userID];
}

+ (void)wipeLocalStoreRecords {
    [UserDBobjectManager clearUsersDBobjectsFromBD];
    [PostDBobjectManager clearPostsDBobjectsFromBD];
}

@end
