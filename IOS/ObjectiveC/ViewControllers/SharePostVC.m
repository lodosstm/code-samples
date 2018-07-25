//
//  SharePostVC.m
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import "SharePostVC.h"
#import "UIPlaceHolderTextView.h"
#import "ColorsManager.h"
#import "NSString+Extensions.h"
#import "UIHelper.h"
#import "SoundFeedItemPostCell.h"
#import "NetworkManager.h"
#import "TPKeyboardAvoidingTableView.h"
#import "FollowersSearchDataSource.h"
#import "Consts.h"
#import "PlaylistDetailsVC.h"

@interface SharePostVC () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, copy) Post *post;
@property (nonatomic, weak) id <RefreshableProtocol> parent;

@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *shareButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewHeight;
@property (strong, nonatomic) IBOutlet UIPlaceHolderTextView *commentTextView;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSString *searchText;
@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingTableView *followersTableView;
@property (nonatomic, strong) NSMutableArray *taggedPeople;

@property (strong, nonatomic) IBOutlet UILabel *navigationBarTitleLabel;

@property (nonatomic) BOOL isSearchTaggedUserEnabled;
@property (nonatomic) BOOL isSearchTaggedUserPossible;
@property (nonatomic) NSRange searchRange;

@end

@implementation SharePostVC
{
    BOOL isTransitionInProgress;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self basicInit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupTextView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    isTransitionInProgress = NO;
}

#pragma mark - Init

- (void)setupWithPost:(Post *)post andParentVC:(id <RefreshableProtocol>)parent {
    self.post = post;
    self.parent = parent;
    
    if (self.post.type != MessageTypeShare) {
        self.post.type = MessageTypeShare;
        self.post.repostedPost = self.post;
    }
}

- (void)basicInit {
    self.isSearchTaggedUserEnabled = NO;
    self.isSearchTaggedUserPossible = YES;
    self.taggedPeople = [NSMutableArray array];
    [self registerCells];
    [self setupTextViewHeight];
    [self.commentTextView becomeFirstResponder];
}

- (void)setupTextView {
    self.commentTextView.placeholderColor = [ColorsManager gray9EB0BEDashLineColorWithAplha];
}

- (void)setupTextViewHeight {
    self.textViewHeight.constant = MAX(kMinTextHeight, [UIHelper heightBasedOnText: self.commentTextView.text withFont: self.commentTextView.font andItemWidth: ([UIScreen mainScreen].bounds.size.width - kTextViewHorizontalMargin)] + kTextViewVerticallMargin);
}

- (void)registerCells {
    UINib *nib = [UINib nibWithNibName:@"RepostItemCell" bundle:nil];;
    [self.tableView registerNib:nib forCellReuseIdentifier:@"RepostCellID"];
}

#pragma mark - Custom Actions

- (void)sharePostWithSender:(id)sender {
    UIButton *sendButton = (UIButton *)sender;
    sendButton.enabled = NO;
    sendButton.alpha = 0.5;
    NSString *postIDtoShare = self.post.repostedPost.identity;
    
    __weak __typeof(self)weakSelf = self;
    [NetworkManager sharePostWithID:postIDtoShare сommentText:[self taggedTextComment] taggedUsersArray:self.taggedPeople success:^(NSDictionary *postDict) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if ([strongSelf.parent respondsToSelector:@selector(insertNewPost:)]) {
                [strongSelf.parent insertNewPost:postDict];
            }
            [strongSelf.parent refreshData];
            //scroll feed tableview to the start (if we come from feed)
            [strongSelf.parentViewTableView setContentOffset:CGPointZero animated:YES];
            [strongSelf returnToPreviousScreen];
            sendButton.enabled = YES;
            sendButton.alpha = 1;
        }];
    } error:^(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict) {
        [UIHelper errorAlertWithText:errorDescriptionText];
        sendButton.enabled = YES;
        sendButton.alpha = 1;
    } cleanup:^{
        sendButton.enabled = YES;
        sendButton.alpha = 1;
    }];
}

- (void)tableViewSizeToContentSize {
    dispatch_async(dispatch_get_main_queue(), ^{
        //This code will run in the main thread:
        [self.tableView sizeToFit];
        CGRect frame = self.tableView.frame;
        frame.size.height = self.tableView.contentSize.height;
        self.tableView.frame = frame;
    });
}

#pragma mark - Tagging

- (void)searchInFollowers {
    if ([NSString isNilOrEmpty:self.searchText]) {
        return;
    }
    
    self.followersTableView.hidden = NO;
    __weak __typeof(self)weakSelf = self;
    [[FollowersSearchDataSource sharedInstance] searchFollowersWithText:self.searchText tableViewToDisplayResults:self.followersTableView alreadySelectedUsers:self.taggedPeople  andUserSelectionBlock:^(User *selectedUser) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [strongSelf handleUserForTagginSelection:selectedUser searchText:self.searchText];
        }];
    }];
}

- (void)checkTaggingInString:(NSString *)string {
    [self searchInFollowers];
}

- (void)handleUserForTagginSelection:(User *)selectedUser searchText:(NSString *)searchText {
    if (!selectedUser) {
        return;
    }
    
    
    if ([self.commentTextView.text length] < [searchText length]) {
        return;
    }
    
    [self.taggedPeople addObject:selectedUser];
    self.followersTableView.hidden = YES;
    NSString *stringToReplace = [NSString stringWithFormat:@"%@", searchText];
    
    NSRange replacementRange = NSMakeRange(self.searchRange.location, self.searchRange.length+1);
    
    self.commentTextView.text = [self.commentTextView.text stringByReplacingOccurrencesOfString:stringToReplace withString:[NSString stringWithFormat:@"%@ ", selectedUser.fullName] options:0 range:replacementRange];
    
    [self checkTextViewHeight:self.commentTextView];
    self.isSearchTaggedUserPossible = YES;
    self.isSearchTaggedUserEnabled = NO;
    self.searchText = @"";
    self.searchRange = NSMakeRange(0, 0);
    [self.commentTextView becomeFirstResponder];
}

- (BOOL)checkIfTagWasDeleted:(NSString *)editedString {
    __block User *userToDelete = nil;
    [self.taggedPeople enumerateObjectsUsingBlock:^(User *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([editedString rangeOfString:[NSString stringWithFormat:@"@%@",obj.fullName]].location == NSNotFound) {
            NSString *stringToDelete = [NSString stringWithFormat:@"@%@", obj.fullName];
            NSRange newRange = [self.commentTextView.text rangeOfString:stringToDelete];
            self.commentTextView.text = [self.commentTextView.text stringByReplacingOccurrencesOfString:stringToDelete withString:@""];
            self.commentTextView.selectedRange = NSMakeRange(newRange.location, 0);
            [self checkTextViewHeight:self.commentTextView];
            userToDelete = obj;
        }
    }];
    
    if (userToDelete) {
        [self.taggedPeople removeObject:userToDelete];
        return YES;
    }
    return NO;
}

- (NSString *) taggedTextComment {
    NSString *result = self.commentTextView.text;
    for (User *item in self.taggedPeople){
        NSString *searchedTag = [NSString stringWithFormat:@"@%@", item.fullName];
        if ([result rangeOfString:searchedTag].location != NSNotFound) {
            NSString *stringToInsert =  [NSString stringWithFormat:@"<a href=\"/u/%@\">%@</a>",item.purl, item.fullName];
            result = [result stringByReplacingOccurrencesOfString:searchedTag withString:stringToInsert];
        }
    }
    
    return result;
}

#pragma mark - IBActions

- (IBAction)cancelButtonPressed:(id)sender {
    [self returnToPreviousScreen];
}

- (IBAction)shareButtonPressed:(id)sender {
    [self sharePostWithSender:(id)sender];
}

#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SoundFeedItemPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepostCellID"];
    CGFloat height = [cell calculateHeightForRepost:self.post];
    //NSLog(@" >>> repost height: %f", height);
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SoundFeedItemPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepostCellID"];
    if (!cell) {
        cell = [[SoundFeedItemPostCell alloc] init];
    }
    
    [SoundFeedItemPostCell setupCell:cell withPost:self.post];
    
    [self tableViewSizeToContentSize];
    [self setupCellActionBlocks:cell withPost:self.post];
    
    cell.tableViewOwnerVC = self;
    cell.indexPath = indexPath;
    cell.tableView = tableView;
    
    return cell;
}

- (void)setupCellActionBlocks:(SoundFeedItemPostCell *)cell withPost:(Post *)post {
    __weak __typeof(self)weakSelf = self;
    void (^showMentionedPlaylist)(Playlist *playlist) = ^(Playlist *playlist){
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf showPlaylist:playlist];
    };
    cell.showMentionedPlaylistAction = showMentionedPlaylist;
}

#pragma mark - UITextView delegate

- (void)textViewDidChange:(UITextView *)textView {
    [self checkTextViewHeight:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@" "] || range.location == 0) {
        self.isSearchTaggedUserPossible = YES;
        self.isSearchTaggedUserEnabled = NO;
        self.searchText = @"";
        self.searchRange = NSMakeRange(0, 0);
    }
    
    if (self.isSearchTaggedUserEnabled) {
        
        BOOL isUserInputSearchName = (range.location >= self.searchRange.location) && (range.location <= self.searchRange.location + self.searchRange.length + 1);
        if (isUserInputSearchName) {
            if ([text isEqualToString:@""]) {
                self.searchRange = NSMakeRange(self.searchRange.location, self.searchRange.length-range.length);
            }else{
                self.searchRange = NSMakeRange(self.searchRange.location, self.searchRange.length+1);
            }
            self.searchText = [[textView.text stringByReplacingCharactersInRange:range withString:text] substringWithRange:NSMakeRange(self.searchRange.location+1, self.searchRange.length)];
        }else{
            self.isSearchTaggedUserEnabled = NO;
            self.searchText = @"";
            self.searchRange = NSMakeRange(0, 0);
        }
    }
    
    if ([text isEqualToString:@"@"] && self.isSearchTaggedUserPossible) {
        self.isSearchTaggedUserPossible = NO;
        self.isSearchTaggedUserEnabled = YES;
        self.searchRange = range;
    }
    
    NSString *resultString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (range.length==1 && text.length==0) {
        if ([self checkIfTagWasDeleted:resultString]) {
            return NO;
        }
    }
    
    if (textView.selectedTextRange != nil && textView.selectedTextRange.empty) {
        [self checkTaggingInString:resultString];
    }
    
    return YES;
}

- (void)checkTextViewHeight:(UITextView *)textView {
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    if (newSize.height <= [UIScreen mainScreen].bounds.size.height/4) {
        textView.scrollEnabled = NO;
        
        CGRect newFrame = textView.frame;
        newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
        textView.frame = newFrame;
        
        
        self.textViewHeight.constant = MAX(kMinTextHeight, newSize.height + kTextViewVerticallMargin);;
    } else {
        textView.scrollEnabled = YES;
        
        [self scrollTextViewToBottom:textView];
    }
}

- (void)scrollTextViewToBottom:(UITextView *)textView {
    CGPoint bottomOffset = CGPointMake(0, textView.contentSize.height - textView.bounds.size.height);
    [textView setContentOffset:bottomOffset animated:YES];
    
    if(textView.text.length > 0 ) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

#pragma mark - Navigation

- (void)returnToPreviousScreen {
    @synchronized(self) {
        if (isTransitionInProgress) return;
        isTransitionInProgress = YES;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showPlaylist:(Playlist *)playlist {
    @synchronized(self) {
        if (isTransitionInProgress) return;
        isTransitionInProgress = YES;
    }
    
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"TabBar" bundle:nil];
    PlaylistDetailsVC *playlistDetails = [secondStoryBoard instantiateViewControllerWithIdentifier:@"PlaylistDetailsVC"];
    playlistDetails.playlist = playlist;
    [self.navigationController pushViewController:playlistDetails animated:YES];
}

@end
