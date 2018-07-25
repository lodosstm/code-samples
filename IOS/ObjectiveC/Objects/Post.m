//
//  Post.m
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import "Post.h"
#import "Consts.h"
#import "DataFormatter.h"
#import "NSString+Extensions.h"
#import <HTMLReader/HTMLDocument.h>
#import <HTMLReader/HTMLReader.h>
#import "SoundFeedItemPostCell.h"
#import "NetworkManager.h"
#import "Song.h"
#import "Playlist.h"
#import "Comment.h"
#import "CurrentUserSession.h"
#import "DataManager.h"

@interface Post ()

@property (nonatomic, strong) NSMutableArray *observersArray;

@end

@implementation Post

#pragma mark - Init factory

+ (instancetype)initPostWithDict:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    Post *post = [Post initWithDict:dict];
    
    NSDictionary *repostedPostDict = dict[@"shared_from"];
    if ((repostedPostDict != nil) && ([repostedPostDict count] > 0))
        post.repostedPost = [Post initPostWithDict:repostedPostDict];
    
    return post;
}

+ (instancetype)initWithDict:(NSDictionary *)dict {
    Post *post = [[Post alloc] init];
    [post reinitPostWithDict:dict];
    
    return post;
}

#pragma mark - Lyfecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.observersArray = [[NSMutableArray alloc] init];        
        [self signInInForSocketsNotifications];
        
        if (kPostsRetainLog) [[AllocatesMonitor sharedInstance] debugPostCreated:self];
    }
    return self;
}

- (void)dealloc {
    [self signOutInForSocketsNotifications];
    
    if (kPostsRetainLog) [[AllocatesMonitor sharedInstance] debugPostDealocated:self];
}

#pragma mark - NSNotificationCenter

- (void)signInInForSocketsNotifications {
    NSNotificationCenter *notifCent = [NSNotificationCenter defaultCenter];
    __weak __typeof(self)weakSelf = self;
    id observer;

    observer = [notifCent addObserverForName:kNotificationAppreciateChanged object:nil queue:nil usingBlock:^(NSNotification * note) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf postAppreciateUpdateNotificationReceived:note];
        });
    }];
    [self.observersArray addObject:observer];
    
    observer = [notifCent addObserverForName:kNotificationCommentRemove object:nil queue:nil usingBlock:^(NSNotification * note) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf postCommentUpdateNotificationReceived:note];
        });
    }];
    [self.observersArray addObject:observer];
    
    observer = [notifCent addObserverForName:kNotificationCommentAdd object:nil queue:nil usingBlock:^(NSNotification * note) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf postCommentUpdateNotificationReceived:note];
        });
    }];
    [self.observersArray addObject:observer];    
}

- (void)signOutInForSocketsNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSNotificationCenter *notifCen = [NSNotificationCenter defaultCenter];
    
    [self.observersArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [notifCen removeObserver:obj];
    }];
    [self.observersArray removeAllObjects];
}

#pragma mark - Initialization

- (void)reinitPostWithDict:(NSDictionary *)dict {
    NSDictionary *bodyDict = dict[@"body"];
    NSDictionary *bodyAttachedDict = bodyDict[@"attached"];
    NSDictionary *userAuthorDict = dict[@"user"];
    NSDictionary *userToDict = dict[@"user_to"];
    NSDictionary *appreciatesDict = dict[@"appreciates"];
    NSArray *appreciatesUsersArray = appreciatesDict[@"first_users"];
    NSDictionary *commentsDict = dict[@"comments"];
    NSDictionary *repostedPostBodyAttachedDict = ((dict[@"shared_from"])[@"body"])[@"attached"];
    
    self.sourceDictionary = dict;
    
    self.type = [dict[@"type"] integerValue];
    
    self.identity = [Post postIDFromDict:dict];
    
    //DEPRECATED
    self.songTitle = bodyAttachedDict[@"title"];
    self.songYouTubeID = bodyAttachedDict[@"youtube_id"];
    
    if (bodyAttachedDict != nil) {
        self.song = [Song initSongWithServerResponse:bodyAttachedDict songHighlightID:self.identity];
    } else {
        self.song = [Song initSongWithServerResponse:repostedPostBodyAttachedDict songHighlightID:self.identity];
    }
    
    if (userAuthorDict != nil)
        self.userAuthor = [User initUserProfileWithServerResponse:userAuthorDict];

    if (userToDict != nil)
        self.userTo = [User initUserProfileWithServerResponse:userToDict];
    
    if (self.userAuthor.userID == nil)
        self.userAuthor.userID = dict[@"user_id"];
    if (self.userTo.userID == nil)
        self.userTo.userID = dict[@"to"];
    
    if (dict[@"created_date"] != nil)
        self.createDate = [DataFormatter dateFromJSONStringWithMS:dict[@"created_date"]];
    
    
    self.appreciatesCountNumber = appreciatesDict[@"count"];
    self.appreciatesCountInt = [self.appreciatesCountNumber integerValue];
    self.appreciaterFirstUser = [User initUserProfileWithServerResponse:(([appreciatesUsersArray firstObject])[@"user"])];
    self.appreciaterFirstUserFullName = (([appreciatesUsersArray firstObject])[@"user"])[kProfileFullName];
    self.appreciatedByCurrentUser = [((NSNumber *)appreciatesDict[@"status"]) boolValue];

    self.commentsCountNumber = commentsDict[@"count"];
    self.commentsCountInt = [self.commentsCountNumber integerValue];
    self.comments = [NSMutableArray array];
    NSArray *coms = commentsDict[@"data"];
    [coms enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Comment *temp = [Comment initCommentWithServerResponse:obj];
        if (temp) {
            [self.comments addObject:temp];
        }
    }];
    
    self.linkedPostIdentity = bodyDict[@"post_id"];
    self.linkedPostAuthorFullName = (bodyDict[@"user"])[@"full_name"];
    
    self.playlistTitle = bodyDict[@"title"];
    
    [self setupTextWithDict:dict];
    self.message = self.text;

    if ((self.song != nil) || (self.repostedPost.song != nil)) {
        self.postKindTextNameFull = @"song post";
        self.postKindTextNameShort = @"song";
    } else {
        self.postKindTextNameShort = @"activity";
        self.postKindTextNameFull = @"activity";
    }
    
    switch (self.type) {
        case 3:
        case 6:
            self.mentionedPlaylist = [Playlist initPlaylistWithServerResponse:bodyDict];
            break;
        case 4:
        case 5:
            self.mentionedPost = [Post initPostWithDict:bodyDict];
            break;
            
        default:
            break;
    }
    
    NSDictionary *repostedPostDict = dict[@"shared_from"];
    if ((repostedPostDict != nil) && ([repostedPostDict count] > 0))
        self.repostedPost = [Post initPostWithDict:repostedPostDict];
}

- (void)updateAppreciaters:(NSDictionary *)dict {
    NSDictionary *appreciatesDict = dict[@"appreciates"];
    NSArray *appreciatesUsersArray = appreciatesDict[@"first_users"];
    self.appreciatesCountNumber = appreciatesDict[@"count"];
    self.appreciatesCountInt = [self.appreciatesCountNumber integerValue];
    self.appreciaterFirstUser = [User initUserProfileWithServerResponse:(([appreciatesUsersArray firstObject])[@"user"])];
    self.appreciaterFirstUserFullName = (([appreciatesUsersArray firstObject])[@"user"])[kProfileFullName];
}

- (void)updateDependOnNewDictionaryFromAppreciateNotification:(NSDictionary *)newDict {
    NSString *likeOwnerID = (newDict[@"appreciates"])[@"changed_by"];
    BOOL isThisLikeFromMe = [likeOwnerID isEqualToString:[CurrentUserSession sharedInstance].userID];
    if (isThisLikeFromMe)
        [self reinitPostWithDict:newDict];
    else
        [self updateAppreciaters:newDict];
}

- (void)setupTextWithDict:(NSDictionary *)dict {
    NSDictionary *bodyDict = dict[@"body"];
    
    NSString *textMessage = bodyDict[@"text"];
    if (![NSString isNilOrEmpty:textMessage]) {
        textMessage = [textMessage stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
        HTMLDocument *document = [HTMLDocument documentWithString:textMessage];
        if (document != nil) {
            if (![NSString isNilOrEmpty:document.textContent]) {
                NSArray *children = [document nodesMatchingSelector:@"a"];
                for (HTMLElement *child in children){
                    child.textContent = [NSString stringWithFormat:@"@%@",child.textContent];
                }
                self.text = document.textContent;
            }
            [self searchTaggedUsersWithDocument:document];
        }
    }

    switch (self.type) {
        case MessageTypePostSong:
            break;
            
        case MessageTypeShare:
            break;

        case MessageTypeCreatePlaylist:
            self.text = [NSString stringWithFormat:@"Creates a new playlist: %@", self.playlistTitle];
            break;

        case MessageTypeComment:
            self.text = [NSString stringWithFormat:@"Commented on %@'s Song Post.", self.linkedPostAuthorFullName];
            break;
            
        case MessageTypeSongComment:
            self.text = [NSString stringWithFormat:@"Made a song comment on %@'s Song Post.", self.linkedPostAuthorFullName];
            break;
            
        case MessageTypeEditPlaylist:
            self.text = [NSString stringWithFormat:@"Edited a playlist: %@", self.playlistTitle];
            break;
            
        default:
            self.text = @"";
            break;
            
    }
}

- (void)searchTaggedUsersWithDocument:(HTMLDocument *)documentFromTextMessage {
    @try {
        HTMLElement *firstLevel = [[documentFromTextMessage childElementNodes] objectAtIndex:0];
        if (firstLevel && ([firstLevel.childElementNodes count] > 1)) {
            HTMLElement *secondLevel = [firstLevel.childElementNodes objectAtIndex:1];
            if (secondLevel && ([secondLevel.childElementNodes count] > 0)) {
                HTMLElement *thirdLevel = [secondLevel.childElementNodes objectAtIndex:0];
                if (thirdLevel && ([thirdLevel.childElementNodes count] > 0)) {
                    NSArray *taggedUsers = thirdLevel.childElementNodes;
                    NSMutableArray *mentionedTaggedUserLocal = [[NSMutableArray alloc] init];
                    
                    [taggedUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        HTMLElement *taggedUserElement = obj;
                        NSString *taggedUserTextFullname = taggedUserElement.textContent;
                        NSString *taggedUserPurl = [[taggedUserElement objectForKeyedSubscript:@"href"] stringByReplacingOccurrencesOfString:@"/u/" withString:@""];
                        
                        if ((taggedUserTextFullname != nil) && (taggedUserPurl != nil))
                            [mentionedTaggedUserLocal addObject:@{kProfileFullName: taggedUserTextFullname, kProfilePurl: taggedUserPurl}];
                    }];
                    
                    self.mentionedTaggedUser = [NSArray arrayWithArray:mentionedTaggedUserLocal];
                }
            }
        }
    }
    @catch (NSException *exception) {
    }
}

#pragma mark - Comparation

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    Post *other = object;
    return [self.identity isEqualToString: other.identity];
}

- (BOOL)isPostIDEqualToString:(NSString *)postID {
    if ([self.identity isEqualToString:postID]) {
        return YES;
    }
    return NO;
}

- (BOOL)isPostIDEqualToPostIDFromDict:(NSDictionary *)dict {
    NSString *gotIdentity = [Post postIDFromDict:dict];
    if ([self.identity isEqualToString:gotIdentity]) {
        return YES;
    }
    return NO;
}

#pragma mark - Copy

- (id)copy {
    Post *original = self;
    
    Post *newCopy = [[Post alloc] init];
    
    newCopy.type = original.type;
    newCopy.identity = [original.identity copy];
    
    newCopy.text = [original.text copy];
    newCopy.message = [original.message copy];
    
    newCopy.userAuthor = [User initUserProfileWithServerResponse:original.userAuthor.sourceDictionary];
    newCopy.userTo = [User initUserProfileWithServerResponse:original.userTo.sourceDictionary];
    
    newCopy.createDate = [original.createDate copy];
    
    newCopy.appreciatesCountNumber = [original.appreciatesCountNumber copy];
    newCopy.appreciatesCountInt = original.appreciatesCountInt;
    newCopy.appreciaterFirstUserFullName = [original.appreciaterFirstUserFullName copy];
    newCopy.appreciaterFirstUser = [User initUserProfileWithServerResponse:original.appreciaterFirstUser.sourceDictionary];
    
    newCopy.appreciatedByCurrentUser = original.appreciatedByCurrentUser;
    
    newCopy.commentsCountNumber = [original.commentsCountNumber copy];
    newCopy.commentsCountInt = original.commentsCountInt;
    newCopy.comments = [original.comments copy];
    
    newCopy.linkedPostIdentity = [original.linkedPostIdentity copy];
    newCopy.linkedPostAuthorFullName = [original.linkedPostAuthorFullName copy];
    
    newCopy.playlistTitle = [original.playlistTitle copy];
    
    newCopy.repostedPost = [original.repostedPost copy];
    newCopy.mentionedPlaylist = [Playlist initPlaylistWithServerResponse:original.mentionedPlaylist.sourceDictionary];
    newCopy.mentionedPost = [original.mentionedPost copy];
    newCopy.mentionedTaggedUser = [original.mentionedTaggedUser copy];
    
    newCopy.postKindTextNameShort = [original.postKindTextNameShort copy];
    newCopy.postKindTextNameFull = [original.postKindTextNameFull copy];
    
    newCopy.songTitle = [original.songTitle copy];
    newCopy.songYouTubeID = [original.songYouTubeID copy];
    
    return newCopy;
}

- (id)copyWithZone:(NSZone *)zone{
    Post *newCopy = [self copy];
    
    return newCopy;
}

#pragma mark - Other

+ (NSString *)postIDFromDict:(NSDictionary *)dict {
    NSString *identity;
    
    identity = dict[@"_id"];
    
    if ([NSString isNilOrEmpty:identity]) {
        if (![NSString isNilOrEmpty:dict[@"post_id"]]) {
            identity = dict[@"post_id"];
        }
    }
    
    return identity;
}

#pragma mark - Sockets Updates Notifications Handling

- (void)postAppreciateUpdateNotificationReceived:(NSNotification *)notification {
    NSDictionary *anotherPostDict = [notification userInfo];

    if (anotherPostDict != nil) {
        if ([self isPostIDEqualToPostIDFromDict:anotherPostDict]) {
            NSLog(@" ### 33 postAppreciateUpdateNotificationReceived isPostIDEqualToPostIDFromDict ###");
            [self updateDependOnNewDictionaryFromAppreciateNotification:anotherPostDict];
        }
    }
}

- (void)postCommentUpdateNotificationReceived:(NSNotification *)notification {
    NSDictionary *postDict = [notification userInfo];
    BOOL isThatPost = ([self isPostIDEqualToString:postDict[@"post_id"]]);
    if (isThatPost) {
        NSLog(@" ### 23 ThatPost for postCommentUpdateNotificationReceived ###");
        [self updatePostFromServer];
    }
}

- (void)updatePostFromServer {
    __weak __typeof(self)weakSelf = self;
    [DataManager postByID:self.identity successGotFromLocalBase:nil successGotFromNetwork:^(NSDictionary *postDict) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf reinitPostWithDict:postDict];
        }];
    } errorGotFromNetwork:nil cleanupGotFromLocalBase:nil cleanupGotFromNetwork:nil isShouldGetFromNetworkIfFoundLocaly:YES];
}

@end
