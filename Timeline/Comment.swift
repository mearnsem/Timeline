//
//  Comment.swift
//  Timeline
//
//  Created by Emily Mearns on 6/13/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData


class Comment: SyncableObject {

    convenience init?(post: Post, text: String, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else {return nil}
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.post = post
        self.text = text
    }

}
