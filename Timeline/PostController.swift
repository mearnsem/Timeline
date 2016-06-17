//
//  PostController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/13/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostController {
    
    static let sharedPostController = PostController()
    
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
        saveContext()
    }
    
    func addCommentToPost(post: Post, text: String) {
        _ = Comment(post: post, text: text)
        saveContext()
    }
    
    func saveContext() {
        let moc = Stack.sharedStack.managedObjectContext
        do {
            try moc.save()
        } catch {
            print("Post could not be saved.")
        }
    }
    
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
    
}