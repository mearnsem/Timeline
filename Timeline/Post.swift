//
//  Post.swift
//  Timeline
//
//  Created by Emily Mearns on 6/21/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Post: SyncableObject, SearchableRecord, CloudKitManagedObject {
    
    static let keyType = "Post"
    static let keyTimestamp = "timestamp"
    static let keyPhotoData = "photoData"

    convenience init(photo: NSData, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else {
            fatalError("Failed to create entity")
        }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.timestamp = timestamp
        self.recordName = self.nameForManagedObject()
    }
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        return (self.comments?.array as? [Comment])?.filter({$0.matchesSearchTerm(searchTerm)}).count > 0
    }
    
    lazy var temporaryPhotoURL: NSURL = {
        
        // Must write to temporary directory to be able to pass image file path url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.recordName).URLByAppendingPathExtension("jpg")
        
        self.photoData.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    // MARK: - CKMO
    
    var recordType: String = Post.keyType
    
    var cloudKitRecord: CKRecord? {
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Post.keyTimestamp] = timestamp
        record[Post.keyPhotoData] = CKAsset(fileURL: temporaryPhotoURL)
        
        return record
    }
    
    convenience required init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let timestamp = record.creationDate, let photoData = record[Post.keyPhotoData] as? CKAsset else {return nil}
        guard let entity = NSEntityDescription.entityForName(Post.keyType, inManagedObjectContext: context) else {
            fatalError()
        }
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = NSData(contentsOfURL: photoData.fileURL)!
        self.timestamp = timestamp
        self.recordName = record.recordID.recordName
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
    }

}
