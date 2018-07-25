//
//  ContactsAndCallsRelationsDB.swift
//
//  Created by dev on 12/19/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ContactsAndCallsRelationsDB: NSObject {
    
    class func getAllRelations() -> [ContactsAndCallsRelations] {
        return ContactsAndCallsRelationsDB.getAllRelations(includesPropertyValues:true)
    }
    
    class func getAllRelations(includesPropertyValues:Bool) -> [ContactsAndCallsRelations] {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ContactsAndCallsRelations> = ContactsAndCallsRelations.fetchRequest()
        
        let contactIDSortDescriptor = NSSortDescriptor(key: ContactKey.kContactIdKey, ascending: true)
        fetchRequest.sortDescriptors = [contactIDSortDescriptor]
        
        fetchRequest.includesPropertyValues = includesPropertyValues
        
        var fetchedObjects = [ContactsAndCallsRelations]()
        do{
            fetchedObjects = try context.fetch(fetchRequest)
        } catch {
            fatalError("Error retriving Relations")
        }
        return fetchedObjects
    }
    
    class func getRelationsWith(callID:String?) -> [ContactsAndCallsRelations]? {
        if let idString = callID {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<ContactsAndCallsRelations> = ContactsAndCallsRelations.fetchRequest()
            let predicate = NSPredicate(format: "(SELF.callID LIKE[c] %@)", [idString])
            fetchRequest.predicate = predicate
            do{
                let fetchedObjects = try context.fetch(fetchRequest)
                return fetchedObjects
            } catch {
                fatalError("Error retriving Relations")
            }
        }
        return nil
    }
    
    class func getRelationsWith(contactID:String?) -> [ContactsAndCallsRelations]? {
        if let idString = contactID {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<ContactsAndCallsRelations> = ContactsAndCallsRelations.fetchRequest()
            let predicate = NSPredicate(format: "(SELF.contactID LIKE[c] %@)", [idString])
            fetchRequest.predicate = predicate
            do{
                let fetchedObjects = try context.fetch(fetchRequest)
                return fetchedObjects
            } catch {
                fatalError("Error retriving Relations")
            }
        }
        return nil
    }
    
    class func getRelationWith(contactID:String?, callID:String?) -> ContactsAndCallsRelations? {
        if let contactIDString = contactID, let callIDString = callID {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<ContactsAndCallsRelations> = ContactsAndCallsRelations.fetchRequest()
            
            let predicate = NSPredicate(format: "(SELF.contactID LIKE[c] %@ AND SELF.callID LIKE[c] %@)", [contactIDString, callIDString])
            fetchRequest.predicate = predicate
            do{
                let fetchedObjects = try context.fetch(fetchRequest)
                return fetchedObjects.first
            } catch {
                fatalError("Error retriving Relations")
            }
        }
        return nil
    }
    
    class func clearRelationsList() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let relations = ContactsAndCallsRelationsDB.getAllRelations(includesPropertyValues: false)
        
        for relation in relations {
            context.delete(relation)
        }
        
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save: \(error.localizedDescription)")
        }
    }
    
    class func removeRelationWith(contactID:String?, callID:String?) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let relationToDelete = ContactsAndCallsRelationsDB.getRelationWith(contactID: contactID, callID: callID)
        if let relation = relationToDelete {
            context.delete(relation)
            
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save: \(error.localizedDescription)")
            }
        }
    }
    
    class func saveRelationWith(contactID:String?, callID:String?) -> ContactsAndCallsRelations? {
        if let contactIDString = contactID, let callIDString = callID {
                
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let tempRelation = ContactsAndCallsRelationsDB.getRelationWith(contactID: contactID, callID: callID)
            var temp = ContactsAndCallsRelations()
            if tempRelation != nil {
                temp = tempRelation!
                print("Contact found")
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "ContactsAndCallsRelations", in: context)
                if let contactEntity = entity {
                    temp = NSManagedObject(entity: contactEntity, insertInto: context) as! ContactsAndCallsRelations
                }
            }
            temp.callID = callIDString
            temp.contactID = contactIDString
            
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save: \(error.localizedDescription)")
            }
            
            return temp
        }
        return nil
    }

}
