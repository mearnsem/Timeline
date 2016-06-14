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
    
    static let sharedController = PostController()
    let fetchedResultsController: NSFetchedResultsController
    
    init() {
        let request = NSFetchRequest(entityName: "Post")
        let timestampSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [timestampSortDescriptor]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Stack.sharedStack.managedObjectContext, sectionNameKeyPath: "timestamp", cacheName: nil)
        _ = try? fetchedResultsController.performFetch()
    }
    
    func createPost(image: UIImage, caption: String) {
        guard let data = UIImageJPEGRepresentation(image, 0.7) else {return}
        let post = Post(photo: data)
        addCommentToPost(post, text: caption)
        saveContext()
    }
    
    func addCommentToPost(post: Post, text: String) {
        _ = Comment(post: post, text: text, timestamp: NSDate())
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
    
}