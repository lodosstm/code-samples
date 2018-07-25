//
//  ChatListVC.swift
//
//  Created by dev on 12/15/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit

class ChatListVC: UIViewController, PaginationChatListItemsDelegate {
    var tableRefreshControl1 = UIRefreshControl()
    fileprivate var isRefreshing1 = false
    var tableRefreshControl2 = UIRefreshControl()
    fileprivate var isRefreshing2 = false
    
    @IBOutlet var userAvatarImageView:UIImageView!
    @IBOutlet var userPresenceView:UIView!
    @IBOutlet var changeUserPresenceButton:UIButton!
    @IBOutlet var userPresenceContainerView:UIView!
    var createNewChatButton = UIBarButtonItem()
    
    @IBOutlet var contactsChatsTableView:UITableView!
    @IBOutlet var otherConversationsTableView:UITableView!
    fileprivate var contactsChatsTableViewDelegate = ChatsContactsTableViewDelegate()
    fileprivate var otherConversationsTableViewDelegate = ChatsContactsTableViewDelegate()
    var selectedConversation = Conversation()
    
    @IBOutlet var initialsView:UIView!
    @IBOutlet var onlineLabel:UILabel!
    @IBOutlet var onlineButton:UIButton!
    @IBOutlet var awayLabel:UILabel!
    @IBOutlet var awayButton:UIButton!
    @IBOutlet var dndLabel:UILabel!
    @IBOutlet var dndButton:UIButton!
    @IBOutlet var presenceIndicators: [UIView]!
    @IBOutlet var presenceStatusLabels: [UILabel]!
    @IBOutlet var presenceStatusButtons: [UIButton]!
    
    @IBOutlet var presenceDialogView:UIView!
    @IBOutlet var shadowView:UIControl!
    @IBOutlet var presenceDialogCenterConstraint:NSLayoutConstraint!
    fileprivate var curPresence = ""
    
    @IBOutlet var otherConversationArea:UIView!
    @IBOutlet var viewTouchField:UIView!
    @IBOutlet var viewWithFullViewSize:UIView!
    @IBOutlet var otherConversationViewDragButton:UIButton!
    @IBOutlet var otherConvesationAreaOffsetFromTop: NSLayoutConstraint!
    @IBOutlet var contactsChatTableConstraitToBottom: NSLayoutConstraint!
    
    @IBOutlet var emptyContactConversationView:UIView!
    @IBOutlet var emptyContactConversationLabel:UILabel!
    @IBOutlet var emptyOtherConversationView:UIView!
    @IBOutlet var emptyOtherConversationLabel:UILabel!
    
    fileprivate var isConversationNeedToClearedWhileUpdateFlag = false
    fileprivate var isConversationLoading = false
    fileprivate var hadLoadedDataAtLeastOnce = false
    fileprivate var isAvailableForFurtherDownloading = false
    fileprivate var nowConversationsDownloading = -1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        subscribeForNotifications()
        getConversationsFromDB()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nowConversationsDownloading = 0
        isAvailableForFurtherDownloading = true
        setupPresenceView()
        getConversationsFromServer(withPagination: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableControlsWithLeaveScreenAbility()
    }
    
    deinit {
        self.unsubscribeFromNotifications()
    }
    
    //MARK: - Notifications -
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ChatListVC.handleIncomingMessage(notification:)), name: Notification.Name(LocalNotificationKey.kPresenceUpdated), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatListVC.updateContactPresence(notification:)), name: Notification.Name(LocalNotificationKey.kChatMessageReceived), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatListVC.updateConversation), name: Notification.Name(LocalNotificationKey.kChatListNeedUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatListVC.setupPresenceView), name: Notification.Name(LocalNotificationKey.kUserSettingsReceived), object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleIncomingMessage(notification:NSNotification) {
        if let userInfoDict = notification.userInfo {
            if let rpcDict = userInfoDict[LocalNotificationKey.kMessageReceivedUserInfoKey] as? [String:Any] {
                if let params = rpcDict[MessageKey.kMessageParamsKey]  as? [String:Any] {
                    let messageDate = DataFormatter.dateFrom(serverResponse:(params[MessageKey.kMessageDateKey] as! String?))
                    if let date = messageDate {
                        self.contactsChatsTableViewDelegate.updateLastMessage(text: params[MessageKey.kMessageBodyKey] as! String?, date: date, type: params[MessageKey.kMessageTypeKey] as? String, conversationID: params[MessageKey.kMessageConversationIDKey] as? String)
                        self.otherConversationsTableViewDelegate.updateLastMessage(text: params[MessageKey.kMessageBodyKey] as! String?, date: date, type: params[MessageKey.kMessageTypeKey] as? String, conversationID: params[MessageKey.kMessageConversationIDKey] as? String)
                    }
                }
            }
        }
    }
    
    func updateContactPresence(notification:NSNotification) {
        if let userInfoDict = notification.userInfo {
            let notificationUserID = userInfoDict[LocalNotificationKey.kUpdatedContactUserInfoKey] as! String
            let isMyPresenceNotification = notificationUserID == UserDB.getCurrentUserFromDB().contactID
            DispatchQueue.main.async {
                if isMyPresenceNotification {
                    setupPresenceView()
                } else {
                    contactsChatsTableView.reloadData()
                }
            }
        }
    }
    
    //MARK: - Custom Actions -
    
    func setupUI() {
        isConversationLoading = false
        setupNavBar()
        setupPresenceDialog()
        setupEmptyMessages()
        hideSeparators()
        setupTableViewDataSources()
        initOtherConversationTableMoveManager()
    }
    
    func setupNavBar() {
        if let navController = self.navigationController {
            navigationItem.title = UIConstants.kChatListScreenTitle
            let titleFont = UIFont(name: UIConstants.kFontOpenSansSemibold, size: CGFloat(UIConstants.kNavBarTitleFontSize))
            let textAttributes: [String:Any] = [NSForegroundColorAttributeName:UIColor.blue,
                                                NSFontAttributeName:titleFont]
            navController.navigationBar.titleTextAttributes = textAttributes
            
            let newChatItem = UIBarButtonItem(image: UIImage(named: UIConstants.kPlusIconImageName), style: .plain, target: self, action: #selector(ChatListVC.showNewMessageVC))
            newChatItem.tintColor = UIColor.gray
            navigationItem.rightBarButtonItem = newChatItem
            createNewChatButton = newChatItem
            
            setupPresenceView()
            let userPresenceItem = UIBarButtonItem(customView: userPresenceView)
            navigationItem.leftBarButtonItem = userPresenceItem
        }
    }
    
    func setupPresenceView() {
        setupAvatarImageView()
        
        let curUser = UserDB.getCurrentUserFromDB()
        
        if let avatar = curUser.avatarURL {
            if !avatar.isEmpty {
                hideInitialsAndShowAvatarWith(url: avatar)
            } else {
                hideAvatarAndShowInitialsFor(user: curUser)
            }
        }
        ContactsPresenceDataSource.sharedInstance.setStatusForUserWith(contactID: curUser.contactID, inView: self.userPresenceView)
    }
    
    func setupAvatarImageView() {
        userAvatarImageView.layer.cornerRadius = self.userAvatarImageView.frame.size.height / 2
        userAvatarImageView.layer.borderColor = UIColor.white.cgColor
        userAvatarImageView.layer.borderWidth = 1.0
        userAvatarImageView.clipsToBounds = true
    }
    
    func hideInitialsAndShowAvatarWith(url: String) {
        initialsView.isHidden = true
        userAvatarImageView.isHidden = false
        userAvatarImageView.setImageWith(URL(string: url)!)
    }
    
    func hideAvatarAndShowInitialsFor(user: User) {
        initialsView.isHidden = false
        userAvatarImageView.isHidden = true
        if let initialsSuperview = initialsView.superview {
            initialsView.removeFromSuperview()
            UIHelper.createDefaultAvatarFor(user: user, diameter: userAvatarImageView.frame.size.height, container: initialsSuperview)
        }
        userAvatarImageView.superview?.addSubview(initialsView)
        initialsView.frame = userAvatarImageView.frame
    }
    
    func setupRefreshControl() {
        if tableRefreshControl1.superview == nil {
            tableRefreshControl1 = UIRefreshControl()
            contactsChatsTableView.addSubview(tableRefreshControl1)
            tableRefreshControl1.addTarget(self, action: #selector(ChatListVC.refreshContactsChatData), for: .valueChanged)
        }
        if tableRefreshControl2.superview == nil {
            tableRefreshControl2 = UIRefreshControl()
            otherConversationsTableView.addSubview(tableRefreshControl2)
            tableRefreshControl2.addTarget(self, action: #selector(ChatListVC.refreshNonContactsChatData), for: .valueChanged)
        }
    }
    func hideSeparators() {
        contactsChatsTableView.tableFooterView = UIView()
        otherConversationsTableView.tableFooterView = UIView()
    }
    
    func setupTableViewDataSources() {
        if let contactsDelegate = ChatsContactsTableViewDelegate.configureWith(tableView: contactsChatsTableView, viewController: self, paginationDelegate: self) {
            contactsChatsTableViewDelegate = contactsDelegate
        }
        if let otherDelegate = ChatsContactsTableViewDelegate.configureWith(tableView: otherConversationsTableView, viewController: self, paginationDelegate: self) {
            otherConversationsTableViewDelegate = otherDelegate
        }
    }
    
    func getConversationsFromDB() {
        contactsChatsTableViewDelegate.getMyConversationsFromDBWith(emptyCompletion: {[weak self] () -> Void in
            if let weakself = self {
                weakself.setupEmptyContactsConversationMessage()
                weakself.showEmptyContactConversationView()
            }
        }) {[weak self] () -> Void in
            if let weakself = self {
                weakself.hideEmptyContactConversationView()
            }
        }
        
        otherConversationsTableViewDelegate.getNonContactsConversationsFromDBWith(emptyCompletion: {[weak self] () -> Void in
            if let weakself = self {
                weakself.setupEmptyOtherConversationMessage()
                weakself.showEmptyOtherConversationView()
            }
        }) {[weak self] () -> Void in
            if let weakself = self {
                weakself.hideEmptyOtherConversationView()
            }
        }
    }
    
    func updateConversation() {
        DispatchQueue.main.async {
            self.getConversationsFromDB()
        }
    }
    
    func getConversationsFromServer(withPagination:Bool) {
        if !isConversationLoading {
            isConversationLoading = true
            hadLoadedDataAtLeastOnce = false
            
            downloadConversations()
            setTimeoutHandler()
        }
    }
    
    func downloadConversations() {
        var indicator : UIActivityIndicatorView? = nil
        let wasAnyConversationLoaded = (contactsChatsTableViewDelegate.numberOfConversations() > 0) || (otherConversationsTableViewDelegate.numberOfConversations() > 0)
        if wasAnyConversationLoaded {
            indicator = startActivityIndicator()
        }
        
        ChatSocketsManager.getAllConversationsWith(beforeIndex: nowConversationsDownloading-1, completion: {[weak self] (responseDict) in
            if let weakself = self {
                let conversationsArray = responseDict[ChatKey.kChatConversationsKey] as! [[String:Any]]
                weakself.nowConversationsDownloading += conversationsArray.count
                if (conversationsArray.count < UIConstants.kResponsePageSize) {
                    weakself.isAvailableForFurtherDownloading = false
                }
                
                weakself.isConversationLoading = false
                weakself.hadLoadedDataAtLeastOnce = true
                if (!withPagination) {
                    ConversationDB.clearLocalConversationsListBasedOn(array: conversationsArray)
                }
                ConversationDB.saveConversationsFrom(array: conversationsArray, nonContacts: true)
                weakself.setupRefreshControl()
                if let activityInd = indicator {
                    weakself.stop(activityIndicator: activityInd)
                }
            }
        })
    }
    
    func setTimeoutHandler() {
        DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.kTimeoutInSeconds) {
            if !self.hadLoadedDataAtLeastOnce {
                print(" ### !!! 20 sec no response for getAllConversationsWithCompletion. Stopping activityIndicator on ChatListVC")
                if (!withPagination) {
                    self.setupRefreshControl()
                }
                if let activityInd = indicator {
                    self.stop(activityIndicator: activityInd)
                }
                self.isConversationLoading = false
            }
        }
    }
    
    //MARK: - Empty Data State methods -
    
    func setupEmptyMessages() {
        DispatchQueue.main.async {
            self.emptyContactConversationLabel.text = UIConstants.kLoadingConversationsMessage
            self.emptyOtherConversationLabel.text = UIConstants.kLoadingConversationsMessage
        }
        
        showEmptyContactConversationView()
        showEmptyOtherConversationView()
    }
    
    func setupEmptyContactsConversationMessage() {
        DispatchQueue.main.async {
            self.emptyContactConversationLabel.text = UIConstants.kNoMessagesToDisplayMessage
        }
    }
    
    func setupEmptyOtherConversationMessage() {
        DispatchQueue.main.async {
            self.emptyOtherConversationLabel.text = UIConstants.kNoMessagesToDisplayMessage
        }
    }
    
    func setupErrorContactsConversationMessage() {
        DispatchQueue.main.async {
            self.emptyContactConversationLabel.text = UIConstants.kChatsUnavailableMessage
        }
    }
    
    func setupErrorOtherConversationMessage() {
        DispatchQueue.main.async {
            self.emptyOtherConversationLabel.text = UIConstants.kChatsUnavailableMessage
        }
    }
    
    func showEmptyContactConversationView() {
        DispatchQueue.main.async {
            self.emptyContactConversationView.isHidden = false
            self.contactsChatsTableView.backgroundColor = UIColor.clear
        }
    }
    
    func hideEmptyContactConversationView() {
        DispatchQueue.main.async {
            self.emptyContactConversationView.isHidden = true
            self.contactsChatsTableView.backgroundColor = UIColor.white
        }
    }
    
    func showEmptyOtherConversationView() {
        DispatchQueue.main.async {
            self.emptyOtherConversationView.isHidden = false
        }
    }
    
    func hideEmptyOtherConversationView() {
        DispatchQueue.main.async {
            self.emptyOtherConversationView.isHidden = true
        }
    }
    
    //MARK: - View operations -
    
    func disableControlsWithLeaveScreenAbility() {
        createNewChatButton.isEnabled = false
        contactsChatsTableView.isUserInteractionEnabled = false
        otherConversationsTableView.isUserInteractionEnabled = false
    }
    
    func enableControlsWithLeaveScreenAbility() {
        createNewChatButton.isEnabled = true
        contactsChatsTableView.isUserInteractionEnabled = true
        otherConversationsTableView.isUserInteractionEnabled = true
    }
    
    func canNavigateToOtherScreen() -> Bool {
        return (createNewChatButton.isEnabled || contactsChatsTableView.isUserInteractionEnabled || otherConversationsTableView.isUserInteractionEnabled)
    }
    
    //MARK: - Presence dialog -
    
    func showPresenceDialog() {
        updateCurPresence()
        UIHelper.show(view: presenceDialogView, withCenterYConstraint: presenceDialogCenterConstraint, darkTransparentView: shadowView)
    }
    
    func hidePresenceDialog(animated:Bool) {
        UIHelper.hide(view: presenceDialogView, withCenterYConstraint: presenceDialogCenterConstraint, darkTransparentView: shadowView, animated: animated)
    }
    
    func setupPresenceDialog() {
        for indicator in self.presenceIndicators {
            indicator.layer.cornerRadius = indicator.frame.size.height/2
            indicator.clipsToBounds = true
        }
        self.updateCurPresence()
    }
    
    func updateCurPresence() {
        curPresence = ContactsPresenceDataSource.sharedInstance.presenceStatusStringForCurrentLoggedUser()
        enableAllStatuses()
        disableElementsFor(presence: curPresence)
    }
    
    func selectPresence(presence:String) {
        curPresence = presence
        enableAllStatuses()
        disableElementsFor(presence: curPresence)
    }
    
    func disableElementsFor(presence:String) {
        switch presence {
        case ContactKey.kContactPresenceAvailableKey:
            onlineButton.isEnabled = false
            onlineLabel.textColor = UIColor.gray
        case ContactKey.kContactPresenceAwayKey:
            awayButton.isEnabled = false
            awayLabel.textColor = UIColor.gray
        case ContactKey.kContactPresenceDNDKey:
            dndButton.isEnabled = false
            dndLabel.textColor = UIColor.gray
        }
    }
    
    func enableAllStatuses() {
        for label in presenceStatusLabels {
            label.textColor = UIColor.black
        }
        
        for button in presenceStatusButtons {
            button.isEnabled = true
        }
    }
    
    func changeUserPresence() {
        ProfileSocketsManager.changeUserStatus(status: curPresence) { (responseDict) in
            if responseDict[DictionaryKey.kErrorParameter] != nil {
                print("Failed to change presence")
            }
        }
        updateUserPresenceLocally()
    }
    
    func updateUserPresenceLocally() {
        let currentUserID = UserDB.getCurrentUserFromDB().contactID
        UserDB.changeUserPresense(presence: currentUserID!)
        ContactsPresenceDataSource.sharedInstance.save(status: curPresence, forContactWithVidaoID: currentUserID!)
        ContactsPresenceDataSource.sharedInstance.setStatusForUserWith(contactID: currentUserID!, inView: userPresenceView)
    }
    
    //MARK: - Activity Indicator -
    
    func startActivityIndicator() -> UIActivityIndicatorView? {
        let window = UIApplication.shared.keyWindow
        if let keyWindow = window {
            let indicator = UIHelper.activityIndicatorStartAt(point: CGPoint(x: keyWindow.frame.size.width/2, y: view.frame.size.height/2), container: view)
            return indicator
        }
        return nil
    }
    
    func stop(activityIndicator: UIActivityIndicatorView) {
        UIHelper.stop(activityIndicator: activityIndicator)
    }
    
    //MARK: - Pull to refresh -
    
    func refreshContactsChatData() {
        tableRefreshControl1.endRefreshing()
        isRefreshing1 = false
        nowConversationsDownloading = 0
        isAvailableForFurtherDownloading = true
        getConversationsFromServer(withPagination: false)
    }
    
    func refreshNonContactsChatData() {
        tableRefreshControl2.endRefreshing()
        isRefreshing2 = false
        nowConversationsDownloading = 0
        isAvailableForFurtherDownloading = true
        getConversationsFromServer(withPagination: false)
    }
    
    //MARK: - IBActions -
    
    @IBAction func changeUserPresenceButtonPressed(_ sender: AnyObject) {
        showPresenceDialog()
    }
    
    @IBAction func onlineButtonPressed(_ sender: AnyObject) {
        selectPresence(presence: ContactKey.kContactPresenceAvailableKey)
    }
    
    @IBAction func awayButtonPressed(_ sender: AnyObject) {
        selectPresence(presence: ContactKey.kContactPresenceAwayKey)
    }
    
    @IBAction func dndButtonPressed(_ sender: AnyObject) {
        selectPresence(presence: ContactKey.kContactPresenceDNDKey)
    }
    
    @IBAction func dialogCancelButtonPressed(_ sender: AnyObject) {
        curPresence = UserDB.getCurrentUserFromDB().presence!
        hidePresenceDialog(animated: true)
    }
    
    @IBAction func dialogUpdateButtonPressed(_ sender: AnyObject) {
        changeUserPresence()
        hidePresenceDialog(animated: true)
    }
    
    //MARK: - PaginationChatListItemsDelegate -
    
    func downloadNextPage() {
        print("### download next page request")
        if (isAvailableForFurtherDownloading) {
            getConversationsFromServer(withPagination: true)
        }
    }
    
    //MARK: - Navigation -
    
    func showNewMessageVC() {
        performSegue(withIdentifier: "NewCallTVC", sender: self)
    }
    
    func showConversationWithSelectedContact() {
        if canNavigateToOtherScreen() {
            disableControlsWithLeaveScreenAbility()
            if let conversationID = selectedConversation.cid {
                NotificationCenter.default.post(name: NSNotification.Name(LocalNotificationKey.kShowChatNotification), object: self, userInfo: [LocalNotificationKey.kShowChatConversationIDUserInfoKey : conversationID])
            } else {
                print("Warning! no sonversation ID")
                 NotificationCenter.default.post(name: NSNotification.Name(LocalNotificationKey.kShowChatNotification), object: self)
            }
        }
    }
}
