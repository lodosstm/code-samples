//
//  ContactsDB.swift
//
//  Created by dev on 12/13/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ContactsDB : NSObject {
    
    //MARK: - Get -
    
    class func getUserContactsFromDB () -> [Contact] {
        let predicate = NSPredicate(format: "(SELF.contactStatus LIKE[c] %@)", [ContactKey.kContactStatusActiveKey])
        return ContactsDB.getContactsWith(predicate: predicate)
    }
    
    class func getNonFriendContactsFromDB () -> [Contact] {
        let predicate = NSPredicate(format: "(SELF.contactStatus LIKE[c] %@)", [ContactKey.kContactStatusUnknownKey])
        return ContactsDB.getContactsWith(predicate: predicate)
    }
    
    class func getRequestUsersFromDB () -> [Contact] {
        let predicate = NSPredicate(format: "(SELF.contactStatus LIKE[c] %@)", [ContactKey.kContactStatusRequestKey])
        return ContactsDB.getContactsWith(predicate: predicate)
    }
    
    class func getBlockedUsersFromDB () -> [Contact] {
        let predicate = NSPredicate(format: "(SELF.isBlocked == %@)", [NSNumber(booleanLiteral: true)])
        return ContactsDB.getContactsWith(predicate: predicate)
    }
    
    class func getAllUsersFromDB () -> [Contact] {
        return ContactsDB.getContactsWith(predicate: nil)
    }
    
    class func getContactsWith(predicate: NSPredicate?) -> [Contact] {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        
        if let contactPredicate = predicate {
            fetchRequest.predicate = contactPredicate
        }
        
        let lastNameSortDescriptor = NSSortDescriptor(key: ContactKey.kContactLastNameDBKey, ascending: true)
        let firstNameSortDescriptor = NSSortDescriptor(key: ContactKey.kContactFirstNameDBKey, ascending: true)
        fetchRequest.sortDescriptors = [firstNameSortDescriptor, lastNameSortDescriptor]
        
        var fetchedObjects = [Contact]()
        do{
            fetchedObjects = try context.fetch(fetchRequest)
        } catch {
            fatalError("Error retriving Contacts")
        }
        return fetchedObjects
    }
    
    class func getContactBy(contactID:String?) -> Contact? {
        if let idString = contactID {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
            let predicate = NSPredicate(format: "(SELF.contactID LIKE[c] %@)", [idString])
            fetchRequest.predicate = predicate
            do{
                let fetchedObjects = try context.fetch(fetchRequest)
                return fetchedObjects.first
            } catch {
                fatalError("Error retriving Contacts")
            }
        }
        return nil
    }
    
    //MARK: - Modify -
    
    class func change(friendStatus:String, contact:Contact?) {
        if let contactToChange = contact {
            contactToChange.contactStatus = friendStatus
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save: \(error.localizedDescription)")
            }
        }
    }
    
    class func change(muteStatus:Bool, contact:Contact?) {
        if let contactToChange = contact {
            contactToChange.mute = muteStatus
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save: \(error.localizedDescription)")
            }
        }
    }
    
    class func change(friendStatus:String, contactID:String?) {
        if let idString = contactID {
            let contact = ContactsDB.getContactBy(contactID: idString)
            if let contactToChange = contact {
                contactToChange.contactStatus = friendStatus
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: - Clear and Delete -
    
    class func clearNonContactsList () {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let predicate = NSPredicate(format: "(SELF.contactStatus LIKE[c] %@)", [ContactKey.kContactStatusUnknownKey])
        fetchRequest.predicate = predicate
        fetchRequest.includesPropertyValues = false
        do{
            let fetchedObjects = try context.fetch(fetchRequest)
            for contact in fetchedObjects {
                context .delete(contact)
            }
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save: \(error.localizedDescription)")
            }
        } catch {
            fatalError("Error retriving Contacts")
        }
    }
    
    class func clearLocalContactsList () {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        fetchRequest.includesPropertyValues = false
        do{
            let fetchedObjects = try context.fetch(fetchRequest)
            for contact in fetchedObjects {
                context .delete(contact)
            }
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save: \(error.localizedDescription)")
            }
        } catch {
            fatalError("Error retriving Contacts")
        }
    }
    
    class func deleteContactWith(contactID:String?) {
        if let idString = contactID {
            let contact = ContactsDB.getContactBy(contactID: idString)
            if let contactToDelete = contact {
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                context.delete(contactToDelete)
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: - Save -
    
    class func saveContactsFrom(array:[[String:Any]]?) {
        if let contactDictsArray = array {
            for  contact in contactDictsArray.enumerated(){
                let tempContact = ContactsDB.saveContactFrom(dict: contact)
                if tempContact == nil {
                    print("Error occured during contact saving")
                }
            }
        }
    }
    
    class func saveNonContactsFrom (array:[[String:Any]]?) {
        if let contactDictsArray = array {
            let currentUserID = UserDB.getCurrentUserFromDB().contactID
            for (_, contact) in contactDictsArray.enumerated(){
                if let contactID = obj[ContactKey.kContactIdKey] {
                    let isCurrentUser = currentUserID == contactID as? String
                    if !isCurrentUser {
                        let tempContact = ContactsDB.saveContactFrom(dict: contact)
                        if tempContact == nil {
                            print("Error occured during contact saving")
                        }
                    }
                }
            }
        }
    }
    
    class func saveContactFrom(dict: [String:Any]?) -> Contact? {
        return DBParser.saveContactFrom(dict: dict)
    }
}
