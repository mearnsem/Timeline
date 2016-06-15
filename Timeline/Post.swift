//
//  Post.swift
//  Timeline
//
//  Created by Emily Mearns on 6/14/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData

class Post: SyncableObject, SearchableRecord {
    
    convenience init(photo: NSData, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else { fatalError()}
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.timestamp = timestamp
    }
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        return true
    }
    
}
