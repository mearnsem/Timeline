//
//  Comment.swift
//  Timeline
//
//  Created by Emily Mearns on 6/14/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Comment: SyncableObject, SearchableRecord, CloudKitManagedObject {
    
    static let keyType = "Comment"
    static let keyText = "text"
    static let keyTimestamp = "timestamp"
    static let keyPost = "post"
    
    convenience init(post: Post, text: String, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName(Comment.keyType, inManagedObjectContext: context) else {
            fatalError()
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.post = post
        self.text = text
        self.timestamp = timestamp
        self.recordName = nameForManagedObject()
    }
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        return text.containsString(searchTerm) ?? false
    }
    
    // MARK: - CloudKitManagedObject Methods
    
    var recordType: String = Comment.keyType
    
    var cloudKitRecord: CKRecord? {
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Comment.keyTimestamp] = timestamp
        record[Comment.keyText] = text
        
        guard let post = post,
            postRecord = post.cloudKitRecord else {
                fatalError()
        }
        record[Comment.keyPost] = CKReference(record: postRecord, action: .DeleteSelf)
        return record
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext) {
        guard let timestamp = record.creationDate, text = record[Comment.keyText] as? String, postReference = record[Comment.keyPost] as? CKReference else {return nil}
        
        guard let entity = NSEntityDescription.entityForName(Comment.keyType, inManagedObjectContext: Stack.sharedStack.managedObjectContext) else {fatalError()}
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.timestamp = timestamp
        self.text = text
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        
        if let post = PostController.sharedPostController.postWithName(postReference.recordID.recordName) {
            self.post = post
        }
        
    }
    
}
