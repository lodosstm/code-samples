//
//  FeedPost.h
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"


@class SoundFeedItemPostCell;
@class Song;
@class Playlist;

@interface Post : NSObject <NSCopying> 

+ (instancetype)initPostWithDict:(NSDictionary *)dict;
+ (NSString *)postIDFromDict:(NSDictionary *)dict;
- (void)reinitPostWithDict:(NSDictionary *)dict;
- (void)updateDependOnNewDictionaryFromAppreciateNotification:(NSDictionary *)dict;
- (BOOL)isEqual:(id)object;
- (BOOL)isPostIDEqualToString:(NSString *)postID;
- (BOOL)isPostIDEqualToPostIDFromDict:(NSDictionary *)dict;

@property (strong, nonatomic) NSDictionary *sourceDictionary;

@property (assign, nonatomic) NSInteger type;
@property (strong, nonatomic) NSString *identity;

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *message;

@property (strong, nonatomic) User *userAuthor;
@property (strong, nonatomic) User *userTo;

@property (strong, nonatomic) NSDate *createDate;

@property (strong, nonatomic) Song *song;

@property (strong, nonatomic) NSNumber *appreciatesCountNumber;
@property (assign, nonatomic) NSInteger appreciatesCountInt;
@property (strong, nonatomic) NSString *appreciaterFirstUserFullName;
@property (strong, nonatomic) User *appreciaterFirstUser;

@property (assign, nonatomic) BOOL appreciatedByCurrentUser;

@property (strong, nonatomic) NSNumber *commentsCountNumber;
@property (assign, nonatomic) NSInteger commentsCountInt;
@property (strong, nonatomic) NSMutableArray *comments;

@property (strong, nonatomic) NSString *linkedPostIdentity;
@property (strong, nonatomic) NSString *linkedPostAuthorFullName;

@property (strong, nonatomic) NSString *playlistTitle;

@property (strong, nonatomic) Post *repostedPost;
@property (strong, nonatomic) Playlist *mentionedPlaylist;
@property (strong, nonatomic) Post *mentionedPost;
@property (strong, nonatomic) NSArray *mentionedTaggedUser;

@property (strong, nonatomic) NSString *postKindTextNameShort;
@property (strong, nonatomic) NSString *postKindTextNameFull;

@property (strong, nonatomic) NSString *songTitle;
@property (strong, nonatomic) NSString *songYouTubeID;

@end
