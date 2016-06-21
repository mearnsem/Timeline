//
//  PostController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/13/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class PostController {
    
    static let sharedPostController = PostController()
    let cloudKitManager: CloudKitManager
    var isSyncing: Bool = false
    
    init(){
        self.cloudKitManager = CloudKitManager()
        subscribeToNewPosts { (success, error) in
            if success {
                print("Successfully subscribed to new posts.")
            }
        }
    }
    
    var posts: [Post] {
        let request = NSFetchRequest(entityName: "Post")
        let timestampSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timestampSortDescriptor]
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(request)) as? [Post] ?? []
        return results
    }
    
    func createPost(image: UIImage, caption: String) {
        guard let data = UIImageJPEGRepresentation(image, 0.7) else {return}
        let post = Post(photo: data)
        addCommentToPost(post, text: caption)
        
        if let cloudKitRecord = post.cloudKitRecord {
            cloudKitManager.saveRecord(cloudKitRecord) { (record, error) in
                if let record = record {
                    post.update(record)
                }
            }
        }
        
        saveContext()
    }
    
    func addCommentToPost(post: Post, text: String) {
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
            print("Post could not be saved.")
        }
    }
    
    //MARK: - Subscriptions
    
    func subscribeToNewPosts(completion: ((success: Bool, error: NSError?) -> Void)?) {
        let predicate = NSPredicate(value: true)
        
        cloudKitManager.subscribe(Post.keyType, predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: CKSubscriptionOptions.FiresOnRecordCreation) { (subscription, error) in
            if let completion = completion {
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func addSubscriptionToPostComments(post: Post, alertBody: String?, completion: ((success: Bool, error: NSError?) -> Void)?) {
        guard let recordID = post.cloudKitRecordID else {
            fatalError("Unable to create CloudKit reference for subscription")
        }
        
        let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
        
        cloudKitManager.subscribe(Comment.keyType, predicate: predicate, subscriptionID: post.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: [Comment.keyType, Comment.keyPost], options: CKSubscriptionOptions.FiresOnRecordCreation) { (subscription, error) in
            if let completion = completion {
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func removeSubscriptionToPostComments(post: Post, completion: ((success: Bool, error: NSError?) -> Void)?) {
        cloudKitManager.unsubscribe(post.recordName) { (subscriptionID, error) in
            if let completion = completion {
                let success = subscriptionID != nil && error == nil
                completion(success: success, error: error)
            }
        }
    }
    
    func checkSubscriptionToPostComments(post: Post, completion: ((subscribed: Bool) -> Void)?) {
        cloudKitManager.fetchSubscription(post.recordName) { (subscription, error) in
            if let completion = completion {
                let subscribed = subscription != nil
                completion(subscribed: subscribed)
            }
        }
    }
    
    func togglePostCommentSubscription(post: Post, completion: ((success: Bool, isSubscribed: Bool, error: NSError?) -> Void)?) {
        cloudKitManager.fetchSubscriptions { (subscriptions, error) in
            if subscriptions?.filter({$0.subscriptionID == post.recordName}).first != nil {
                self.removeSubscriptionToPostComments(post, completion: { (success, error) in
                    if let completion = completion {
                        completion(success: success, isSubscribed: false, error: error)
                    }
                })
            } else {
                self.addSubscriptionToPostComments(post, alertBody: "Someone commented on a post you are following", completion: { (success, error) in
                    if let completion = completion {
                        completion(success: true, isSubscribed: true, error: error)
                    }
                })
            }
        }
    }
    
    //MARK: - Helper Functions
    
    func postWithName(name: String) -> Post? {
        if name.isEmpty {
            return nil
        }
        let fetchRequest = NSFetchRequest(entityName: "Post")
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [name])
        fetchRequest.predicate = predicate
        
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [Post] ?? nil
        return result?.first
    }
    
    func syncedRecords(type: String) -> [CloudKitManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: type)
        fetchRequest.predicate = NSPredicate(format: "recordIDData != nil")
        
        let moc = Stack.sharedStack.managedObjectContext
        let results = (try? moc.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        
        return results
    }
    
    func unsyncedRecords(type: String) -> [CloudKitManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: type)
        fetchRequest.predicate = NSPredicate(format: "recordIDData == nil")
        
        let moc = Stack.sharedStack.managedObjectContext
        let results = (try? moc.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        
        return results
    }
    
    func fetchNewRecords(type: String, completion: (() -> Void)?) {
        let referencesToExclude = syncedRecords(type).flatMap({$0.cloudKitReference})
        let predicate: NSPredicate
        if !referencesToExclude.isEmpty {
            predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [referencesToExclude])
        } else {
            predicate = NSPredicate(value: true)
        }
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
            switch type {
            case "Post":
                let _ = Post(record: record)
            case "Comment":
                let _ = Comment(record: record, context: Stack.sharedStack.managedObjectContext)
            default:
                break
            }
            self.saveContext()
            
        }) { (records, error) in
            if let error = error {
                print("Error fetching new records from CloudKit: \(error)")
            }
            completion?()
        }
    }
    
    func pushChangesToCloudKit(completion: ((success: Bool, error: NSError?) -> Void)? = nil) {
        let unsavedManagedObjects = unsyncedRecords(Post.keyType) + unsyncedRecords(Comment.keyType)
        let unsavedRecords = unsavedManagedObjects.flatMap({$0.cloudKitRecord})
        
        cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
            guard let record = record else {return}
            if let matchingManagedObject = unsavedManagedObjects.filter({$0.recordName == record.recordID.recordName}).first {
                matchingManagedObject.update(record)
            }
        }) { (records, error) in
            let success = records != nil
            completion?(success: success, error: error)
        }
    }
    
    func performFullSync(completion: (() -> Void)? = nil) {
        if isSyncing {
            completion?()
            return
        }
        
        isSyncing = true
        
        pushChangesToCloudKit { (success, error) in
            self.fetchNewRecords(Post.keyType, completion: {
                self.fetchNewRecords(Comment.keyType, completion: {
                    completion?()
                    self.isSyncing = false
                })
            })
        }
    }
    
    
    
    
    
    
    
    
}
