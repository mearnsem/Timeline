//
//  Post.swift
//  Timeline
//
//  Created by Emily Mearns on 6/14/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Post: SyncableObject, SearchableRecord, CloudKitManagedObject {
    
    static let keyType = "Post"
    static let keyTimestamp = "timestamp"
    static let keyPhoto = "photoData"
    
    convenience init(photo: NSData, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else {
            fatalError()
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.timestamp = timestamp
        self.recordName = self.nameForManagedObject()
    }
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        return (self.comments?.array as? [Comment])?.filter({$0.matchesSearchTerm(searchTerm)}).count > 0
    }
    
    var recordType: String = Post.keyType
    
    var cloudKitRecord: CKRecord? {
        let asset = CKAsset(fileURL: temporaryPhotoURL)
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Post.keyTimestamp] = timestamp
        record[Post.keyPhoto] = asset
        
        return record
    }
    
    lazy var temporaryPhotoURL: NSURL = {
        
        // Must write to temporary directory to be able to pass image file path url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.recordName).URLByAppendingPathExtension("jpg")
        
        self.photoData?.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let timestamp = record.creationDate, photoData = record[Post.keyPhoto] as? CKAsset else {return nil}
            
        guard let entity = NSEntityDescription.entityForName(Post.keyType, inManagedObjectContext: context) else {
            fatalError()
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.timestamp = timestamp
        self.photoData = NSData(contentsOfURL: photoData.fileURL)
        self.recordName = record.recordID.recordName
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
    }
    
    
}












