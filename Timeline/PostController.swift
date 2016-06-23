//
//  PostController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/21/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class PostController {
    
    static let sharedController = PostController()
    let cloudKitManager: CloudKitManager
    var isSyncing: Bool = false
    
    init() {
        self.cloudKitManager = CloudKitManager()
    }
    
    func createPost(photo: UIImage, caption: String) {
        guard let data = UIImageJPEGRepresentation(photo, 0.8) else {return}
        let post = Post(photo: data)
        
        addCommentToPost(caption, post: post)
        saveContext()
        
        if let postRecord = post.cloudKitRecord {
            cloudKitManager.saveRecord(postRecord, completion: { (record, error) in
                if let record = record {
                    post.update(record)
                }
            })
        }
    }
    
    func addCommentToPost(text: String, post: Post) {
        let comment = Comment(post: post, text: text)
        saveContext()
        
        if let commentRecord = comment.cloudKitRecord {
            cloudKitManager.saveRecord(commentRecord, completion: { (record, error) in
                if let record = record {
                    comment.update(record)
                }
            })
        }
    }
    
    func saveContext() {
        let moc = Stack.sharedStack.managedObjectContext
        do {
            try moc.save()
        } catch {
            print("Context could not be saved")
        }
    }
    
    // MARK: - Helper Functions
    
    func postWithName(name: String) -> Post? {
        if name.isEmpty {return nil}
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [name])
        fetchRequest.predicate = predicate
        
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [Post] ?? nil
        return result?.first
    }
    
    func syncedRecords(type: String) -> [CloudKitManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "recordIDData != nil")
        fetchRequest.predicate = predicate
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        return results
    }
    
    func unsyncedRecords(type: String) -> [CloudKitManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "recordIDData = nil")
        fetchRequest.predicate = predicate
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        return results
    }
    
    func fetchNewReocrds(type: String, completion: (() -> Void)?) {
        let references = syncedRecords(type).flatMap({$0.cloudKitReference})
        var predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [references])
        
        if references.isEmpty {
            predicate = NSPredicate(value: true)
        }
        
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
            switch type {
            case Post.keyType:
                let _ = Post(record: record)
            case Comment.keyType:
                let _ = Comment(record: record)
            default:
                return
            }
            self.saveContext()
        }) { (records, error) in
            if error != nil {
                print("Error")
            }
        }
        
    }
    
    func pushChangesToCloudKit(completion: ((success: Bool, error: NSError?) -> Void)?) {
        let unsavedManagedObjects = unsyncedRecords(Post.keyType) + unsyncedRecords(Comment.keyType)
        let unsavedRecords = unsavedManagedObjects.flatMap({$0.cloudKitRecord})
        
        cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
            guard let record = record else {return}
            if let matchingRecord = unsavedManagedObjects.filter({$0.recordName == record.recordID.recordName}).first {
                matchingRecord.update(record)
            }
        }) { (records, error) in
            if let completion = completion {
                let success = records != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func performFullSync(completion: (() -> Void)?) {
        if isSyncing {
            if let completion = completion {
                completion()
            }
        } else {
            isSyncing = true
            
            pushChangesToCloudKit { (success, error) in
                self.fetchNewReocrds(Post.keyType, completion: {
                    self.fetchNewReocrds(Comment.keyType, completion: {
                        self.isSyncing = false
                        if let completion = completion {
                            completion()
                        }
                    })
                })
            }
        }
    }
}



