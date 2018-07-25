//
//  ChatsContactsTableViewDelegate.swift
//
//  Created by dev on 12/15/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit
import SWRevealTableViewCell

protocol PaginationChatListItemsDelegate {
    func downloadNextPage()
}

class ChatsContactsTableViewDelegate : NSObject {
    
    fileprivate var conversations = [Conversation]()
    fileprivate var targetTableView = UITableView()
    fileprivate var targetVC = ChatListVC()
    var delegate:PaginationChatListItemsDelegate? = nil
    
    class func configureWith(tableView:UITableView?, viewController:ChatListVC?, paginationDelegate: PaginationChatListItemsDelegate?) -> ChatsContactsTableViewDelegate? {
        delegate = paginationDelegate
        if let targetTV = tableView, let targetVC = viewController {
            let ds = ChatsContactsTableViewDelegate()
            ds.targetVC = targetVC
            ds.targetTableView = targetTV
            ds.targetTableView.dataSource = ds
            ds.targetTableView.delegate = ds
            DispatchQueue.main.async {
                ds.targetTableView.reloadData()
            }
            return ds
        }
        return nil
    }
    
    //MARK: - Interface methods -
    
    func getMyConversationsFromDBWith(emptyCompletion:(()->Void)?, fullCompletion:(()->Void)?) {
        conversations.removeAll()
        conversations.append(contentsOf: ConversationDB.getMyContactsConversations())
        DispatchQueue.main.async {
            self.targetTableView.reloadData()
            if (self.conversations.count > 0) {
                if let full = fullCompletion {
                    full()
                }
            } else {
                if let empty = emptyCompletion {
                    empty()
                }
            }
        }
    }
    
    func getNonContactsConversationsFromDBWith(emptyCompletion:(()->Void)?, fullCompletion:(()->Void)?) {
        conversations.removeAll()
        conversations.append(contentsOf: ConversationDB.getNonContactsConversations())
        DispatchQueue.main.async {
            self.targetTableView.reloadData()
            if (self.conversations.count > 0) {
                if let full = fullCompletion {
                    full()
                }
            } else {
                if let empty = emptyCompletion {
                    empty()
                }
            }
        }
    }
    
    func numberOfConversations() -> Int {
        return conversations.count
    }
    
    func updateLastMessage(text:String?, date:Date?, type:String?, conversationID:String?) {
        if let lastMessageText = text, let cid = conversationID, let messageType = type {
            var curConversation = getConversationWith(conversationID: cid)
            
            if (messageType == MessageKey.kMessageTypeFileKey) {
                curConversation.lastMessageText = String("\(MessageKey.kMessageFileDefaultPrefix)\(lastMessageText)")
            } else {
                curConversation.lastMessageText = lastMessageText
            }
            
            var lastMessageDate = (date == nil) ? Date() : date!
            curConversation.lastMessageDate = lastMessageDate
            
            conversation.sort{
                $0.lastMessageDate > $1.lastMessageDate
            }
            
            DispatchQueue.main.async {
                self.targetTableView.reloadData()
            }
        }
    }
    
    func getConversationWith(conversationID: String) -> Conversation {
        for (_, conversation) in self.conversations.enumerated() {
            if (conversation.cid == conversationID) {
                return conversation
            }
        }
        return Conversation()
    }
    
    func requestFileMessageMetadataIfNeeded(conversation:Conversation) {
        if let lastText = conversation.lastMessageText {
            if (lastText.hasPrefix(MessageKey.kMessageFileDefaultPrefix)) {
                var fileID = lastText
                fileID = fileID.replacingOccurrences(of: MessageKey.kMessageFileDefaultPrefix, with: "")
                getMetadataForFileWith(fileID: fileID)
            }
        }
    }
    
    //MARK: - Private methods -
    
    func getMetadataForFileWith(fileID: String) {
        DriveNetworkManager.getMetadataForFileWith(idString: fileID, success: { [weak self] (responseObject) in
            DispatchQueue.main.async {
                if let dict = DataFormatter.dictionatyFrom(JSONString: responseObject as? String) {
                    if let list = dict[DriveKey.kDriveListKey] as? [[String:Any]], let drive = list.first {
                        conversation.lastMessageText = fileMessageFor(drive: drive)
                        if let weakself = self {
                            weakself.targetTableView.reloadData()
                        }
                    }
                }
            }
            }, failure: nil)
    }
    
    func fileMessageFor(drive: [String:Any]) -> String {
        let messageDrive = DriveDB.createDriveUsing(info: drive)
        
        switch (messageDrive.filetype) {
        case DriveKey.kDriveTypePhotoKey:
            return UIConstants.kFileMessagePhotoText
        case DriveKey.kDriveTypeVideoKey:
            return UIConstants.kFileMessageVideoText
        case DriveKey.kDriveTypeAudioKey:
            return UIConstants.kFileMessageAudioText
        default:
            return UIConstants.kFileMessageDefaultText
        }
    }
    
    
    //MARK: - Revealing Cell Buttons actions -
    
    func muteContactWith(idString:String) {
        ChatSocketsManager.muteContactWith(contactID: idString) { (response) in
            print("Muted conversation")
        }
    }
    
    func unmuteContactWith(idString:String) {
        ChatSocketsManager.unmuteContactWith(contactID: idString) { (response) in
            print("Unmuted conversation")
        }
    }
    
    func deleteConversationAt(index:Int) {
        if index < conversations.count {
            let conversationToDelete = conversations[index]
            deleteConversationWith(id: conversationToDelete.cid!)
            conversations.remove(at:index)
        }
    }
    
    func deleteConversationWith(id: String) {
        ChatSocketsManager.deleteConversationWith(conversationID: id, completion: {[weak self] (response) in
            if (response[DictionaryKey.kErrorParameter] == nil) {
                if let weakself = self {
                    ConversationDB.deleteConversationWith(id: id)
                    DispatchQueue.main.async {
                        weakself.targetTableView.reloadData()
                    }
                }
            }
        })
    }
}

//MARK: - TableView methods -

extension ChatsContactsTableViewDelegate: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(UIConstants.kDefaultContactsTableViewRowHeight)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : ChatTVCell? = tableView.dequeueReusableCell(withIdentifier: "chatTVCellIdentifier", for: indexPath) as? ChatTVCell
        if (cell == nil) {
            cell = ChatTVCell()
        }
        
        cell?.delegate = self
        cell?.dataSource = self
        cell?.cellRevealMode = .normal
        
        let curConversation = conversations[indexPath.row]
        requestFileMessageMetadataIfNeeded(conversation: curConversation)
        cell?.setupCellWith(conversation: curConversation)
        
        let row = indexPath.row
        let limit = self.conversations.count - 5
        
        if (row > limit) {
            if let delegate = self.delegate {
                delegate.downloadNextPage()
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        targetVC.selectedConversation = conversations[indexPath.row]
        targetVC.showConversationWithSelectedContact()
    }
}

//MARK: - SWRevealTableViewCell methods -

extension ChatsContactsTableViewDelegate: SWRevealTableViewCellDelegate, SWRevealTableViewCellDataSource {
    
    func revealTableViewCell(_ revealTableViewCell: SWRevealTableViewCell!, willMoveTo position: SWCellRevealPosition) {
        if (position == .center) {
            return
        }
        
        for cell in self.targetTableView.visibleCells {
            if ( cell == revealTableViewCell ) {
                continue
            }
            (cell as! SWRevealTableViewCell).setRevealPosition(.center, animated: true)
        }
    }
    
    func rightButtonItems(in revealTableViewCell: SWRevealTableViewCell!) -> [Any]! {
        var items = [Any]()
        let indexPath = self.targetTableView.indexPath(for: revealTableViewCell)!
        
        if let delete = deleteItem() {
            items.append(delete)
        }
        
        let chat = self.conversations[indexPath.row]
        
        if (chat.type == ChatKey.kChatTypePrivate) {
            let participant = ContactsDB.getContactBy(contactID: chat.participantId)
            if let chatPartner = participant {
                if let mute = muteItem(isMuted: chatPartner.isBlocked) {
                    items.append(mute)
                }
            }
        }
        
        return items
    }
    
    func deleteItem() -> SWCellButtonItem? {
        let deleteItem = SWCellButtonItem(title: UIConstants.kDeleteButtonTitle) {[weak self] (item, cell) -> Bool  in
            if let weakself = self {
                weakself.deleteConversationWith(index: indexPath.row)
            }
            return true
        }
        
        deleteItem?.backgroundColor = UIColor.red
        deleteItem?.image = UIImage(named: UIConstants.kDeleteButtonIconName)
        deleteItem?.tintColor = UIColor.white
        deleteItem?.width = CGFloat(UIConstants.kRevealButtonDefaultWidth)
        
        return deleteItem
    }
    
    func muteItem(isMuted: Bool) -> SWCellButtonItem? {
        let titleString = isMuted ? UIConstants.kUnmuteButtonTitle : UIConstants.kMuteButtonTitle
        
        let muteItem = SWCellButtonItem(title: titleString) {[weak self] (item, cell) -> Bool in
            if let weakself = self {
                if (isMuted) {
                    ContactsDB.change(muteStatus: false, contact: chatPartner)
                    weakself.unmuteContactWith(idString: chatPartner.contactID)
                    item?.title = UIConstants.kUnmuteButtonTitle
                } else {
                    ContactsDB.change(muteStatus: true, contact: chatPartner)
                    weakself.muteContactWith(idString: chatPartner.contactID)
                    item?.title = UIConstants.kMuteButtonTitle
                }
            }
            return true
        }
        
        muteItem?.backgroundColor = UIColor.yellow
        muteItem?.image = UIImage(named: UIConstants.kMuteButtonIconName)
        muteItem?.tintColor = UIColor.white
        muteItem?.width = CGFloat(UIConstants.kRevealButtonDefaultWidth)
        
        return muteItem
    }
}
