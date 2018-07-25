//
//  ContactsPresenceDataSource.swift
//
//  Created by dev on 12/20/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit

class ContactsPresenceDataSource : NSObject {
    var statusDict = [String: String]()
    static let sharedInstance = ContactsPresenceDataSource()
    
    //MARK: - Init -
    override init() {
        super.init()
        initCurrentUserPresence()
    }
    
    func initCurrentUserPresence() {
        let curUser = UserSession.getCurrentUser()
        if let userID = curUser.contactID, let userPres = curUser.presence {
            statusDict[userID] = userPres
        }
    }
    
    //MARK: - Set and get presence -
    func setStatusFor(contact:Contact?, inView:UIView) {
        if let requestedContact = contact {
            setStatusForUserWith(contactID: requestedContact.contactID, inView: inView)
        }
    }
    
    func setStatusForUserWith(contactID: String?, inView: UIView) {
        inView.isHidden = false
        inView.layer.cornerRadius = 1.0
        let presenseString = presenceStatusStringFor(contactID: contactID)
        
        switch presenseString {
        case ContactKey.kContactPresenceAvailableKey:
            inView.backgroundColor = UIColor.green
        case ContactKey.kContactPresenceAwayKey || presenseString == ContactKey.kContactPresenceXAKey:
            inView.backgroundColor = UIColor.yellow
        case ContactKey.kContactPresenceDNDKey:
            inView.backgroundColor = UIColor.red
        default:
            inView.backgroundColor = UIColor.gray
        }
    }
    
    func presenceStatusStringFor(contact: Contact?) -> String {
        if let requestedContact = contact {
            return presenceStatusStringFor(contactID: requestedContact.contactID)
        }
        return ContactKey.kContactPresenceUnvailableKey
    }
    
    func presenceStatusStringForCurrentLoggedUser() -> String {
        let currentUserID = UserSession.getCurrentUser().contactID
        return presenceStatusStringFor(contactID: currentUserID)
    }
    
    func presenceStatusStringFor(contactID: String?) -> String {
        if let idString = contactID {
            if let presenceString = statusDict[idString] {
                return presenceString
            }
        }
        return ContactKey.kContactPresenceUnvailableKey
    }
    
    func isContactOnline(contact: Contact?) -> Bool {
        var isContactOnline = false
        
        let contactStatusString = presenceStatusStringFor(contact: contact)
        if contactStatusString != ContactKey.kContactPresenceUnvailableKey {
            isContactOnline = true
        }
        
        return isContactOnline
    }
    
    //MARK: - User Defaults -
    
    func presenceOfCurrentUserFromUserDefaults() -> String {
        let currentUser = UserSession.getCurrentUser()
        let dict = UserDefaults.standard.object(forKey: UserDefaultsKey.kUserDefaultsPresenceDict) as? [String:String]
        if let presenceDict = dict, let presenceString = presenceDict[currentUser.contactID] {
            return presenceString
        }
        return ContactKey.kContactPresenceUnvailableKey
    }
    
    func saveUserPresenceToUserDefaults(statusString: String?) {
        if let status = statusString {
            let curUser = UserSession.getCurrentUser()
            if let userID = curUser.contactID {
                if var presenceDict = UserDefaults.standard.object(forKey:  UserDefaultsKey.kUserDefaultsPresenceDict) as? [String: String?] {
                    presenceDict[userID] = status
                    UserDefaults.standard.set(presenceDict, forKey:  UserDefaultsKey.kUserDefaultsPresenceDict)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    //MARK: - Save presence data -
    
    func saveContactStatusFrom(messageDict:[String:Any]?) {
        if let dict = messageDict {
            if dict.count > 0 {
                let params = dict[MessageKey.kMessageParamsKey] as! [String: Any]
                let contactID = params[ContactKey.kContactUIDKey] as? String
                if let idString = contactID, let presence = params[ContactKey.kContactPresenceKey] as? String {
                    statusDict[idString] = presence
                    NotificationCenter.default.post(name: NSNotification.Name(LocalNotificationKey.kPresenceUpdated), object: self, userInfo: [LocalNotificationKey.kUpdatedContactUserInfoKey : idString])
                }
            }
        }
    }
    func save(status:String?, forContactWithVidaoID:String?) {
        if let statusString = status, let idString = forContactWithVidaoID {
            statusDict[idString] = statusString
        }
    }
    
    //MARK: - Delete presence data -
    
    func clearStatusDictionary() {
        statusDict.removeAll()
    }
}
