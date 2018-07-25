//
//  ContactsDataSource.swift
//
//  Created by dev on 12/13/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation

class ContactsDataSource : NSObject {
    
    var contactsArray = [Contact]()
    var filteredContactsArray = [Contact]()
    var filterText : String? = ""
    
    // MARK: - Contacts Load -
    func getContactsFromSocketWith(completion:((_ responseDict: [String : Any]) -> Void)?) {
        ContactsSoketsManager.getContactsWith{ (responseDict) -> () in
            ContactsDB.saveContactsFrom(array: responseDict[ContactKey.kContactStatusRequestKey] as? [[String: Any]])
            ContactsDB.saveContactsFrom(array: responseDict[ContactKey.kContactStatusPendingKey] as? [[String: Any]])
            ContactsDB.saveContactsFrom(array: responseDict[ContactKey.kContactStatusActiveKey] as? [[String: Any]])
            if let completionHandler = completion {
                completionHandler(responseDict)
            }
        }
    }
    
    func getContactsFromCoreDataWith(completion:(() -> Void)?) {
        contactsArray = ContactsDB.getUserContactsFromDB()
        if let completionHandler = completion {
            completionHandler()
        }
    }
    
    func getRequestContactsFromCoreDataWith(completion:(() -> Void)?) {
        contactsArray = ContactsDB.getRequestUsersFromDB()
        if let completionHandler = completion {
            completionHandler()
        }
    }
    
    // MARK: - Filter -
    
    func filterContactsArrayFor(text: String?) -> [Contact] {
        if let searchText = text {
            if !searchText.isEmpty {
                filterText = searchText
                let predicate = NSPredicate(format: "SELF.firstName contains[c] %@ || SELF.lastName contains[c] %@ || SELF.id contains[c] %@", argumentArray: [searchText, searchText, searchText])
                filteredContactsArray = contactsArray.filter{predicate.evaluate(with: $0)}
                return filteredContactsArray
            }
        }
        
        return contactsArray
    }
    
    func searchContactsOnServer(text: String?, completion:(() -> Void)?) {
        if let searchText = text {
            if !searchText.isEmpty {
                filterText = searchText
                filteredContactsArray = [Contact]()
                
                ContactsSoketsManager.getListOfUsersWith(text: searchText, completion: {[weak self] (response) in
                    ContactsDB.clearNonContactsList()
                    if (response is [[String:Any]]) {
                        ContactsDB.saveNonContactsFrom(array: response as? [[String:Any]])
                    }
                    if let weakself = self {
                        var temp = ContactsDB.getNonFriendContactsFromDB()
                        let predicate = NSPredicate(format: "SELF.firstName contains[c] %@ || SELF.lastName contains[c] %@ || SELF.id contains[c] %@", argumentArray: [searchText, searchText, searchText])
                        temp.append(contentsOf: weakself.contactsArray.filter{predicate.evaluate(with: $0)})
                        weakself.filteredContactsArray = temp.sorted(by: { (obj1, obj2) -> Bool in
                            obj1.nameToDisplay() < obj2.nameToDisplay()
                        })
                        if let completionHandler = completion {
                            completionHandler()
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Interface -
    
    func contactsCount() -> Int {
        let contactsToShowArray = contactsToShow()
        return contactsToShowArray.count
    }
    
    func setRequestedForContact(number: Int) {
        var isFilterEnabled = false
        if let search = filterText {
            if !search.isEmpty {
                isFilterEnabled = true
            }
        }
        if isFilterEnabled {
            filteredContactsArray[number].status = ContactKey.kContactStatusRequestKey
        }
    }
    
    func contactAt(index: Int) -> Contact? {
        var contact : Contact?
        let contactsToShowArray = contactsToShow()
        
        if (contactsToShowArray.count > index) {
            contact = contactsToShowArray[index]
        }
        return contact
    }
    
    func remove(contact: Contact?) {
        if let contactToRemove = contact {
            var contactsToShowArray = contactsToShow()
            if let index = contactsToShowArray.index(of: contactToRemove) {
                contactsToShowArray.remove(at: index)
            }
        }
    }
    
    func removeContactWith(idString: String?) {
        if let contactID = idString {
            var contactToRemove: Contact?
            let contactsToShowArray = contactsToShow()
            for contact in contactsToShowArray.enumerated() {
                if (contact.contactID == contactID) {
                    contactToRemove = contact
                }
            }
            remove(contact: contactToRemove)
        }
        
    }
    
    func indexOfContactWith(idString: String?) -> Int {
        var index = 0
        if let contactID = idString {
            let contactsToShowArray = contactsToShow()
            for (id, contact) in contactsToShowArray.enumerated() {
                if (contact.contactID == contactID) {
                    index = id
                }
            }
        }
        return index
    }
    
    func contactsToShow() -> [Contact] {
        var isFilterEnabled = false
        if let search = filterText {
            if !search.isEmpty {
                isFilterEnabled = true
            }
        }
        if isFilterEnabled {
            return filteredContactsArray
        } else {
            return contactsArray
        }
    }
}
