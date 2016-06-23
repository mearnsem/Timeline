//
//  Comment.swift
//  Timeline
//
//  Created by Emily Mearns on 6/21/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Comment: SyncableObject, SearchableRecord, CloudKitManagedObject {
    
    static let keyType = "Comment"
    static let keyTimestamp = "timestamp"
    static let keyText = "text"
    static let keyPost = "post"

    convenience init(post: Post, text: String, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else {
            fatalError("Failed to create entity")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.post = post
        self.text = text
        self.timestamp = timestamp
        self.recordName = nameForManagedObject()
    }
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        if text.containsString(searchTerm) {
            return true
        } else {
            return false
        }
    }
    
    var recordType: String = Comment.keyType
    
    var cloudKitRecord: CKRecord? {
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Comment.keyTimestamp] = timestamp
        record[Comment.keyText] = text
        
        guard let post = post,
            let postRecord = post.cloudKitRecord else {
            fatalError()
        }
        
        record[Comment.keyPost] = CKReference(record: postRecord, action: .DeleteSelf)
        return record
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let timestamp = record.creationDate, let text = record[Comment.keyText] as? String, let postReference = record[Comment.keyPost] as? CKReference else {return nil}
        
        guard let entity = NSEntityDescription.entityForName(Comment.keyType, inManagedObjectContext: context) else {
            fatalError("Core data failed to create entity")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.timestamp = timestamp
        self.text = text
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.recordName = record.recordID.recordName
        
        if let post = PostController.sharedController.postWithName(postReference.recordID.recordName) {
            self.post = post
        }
    }

}
