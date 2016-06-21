//
//  PostController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/21/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostController {
    
    static let sharedController = PostController()
    
//    var posts: [Post] {
//        let fetchRequest = NSFetchRequest(entityName: "Post")
//        let moc = Stack.sharedStack.managedObjectContext
//        return (try? moc.executeFetchRequest(fetchRequest)) as? [Post] ?? []
//    }
    
    func createPost(photo: UIImage, caption: String) {
        guard let data = UIImageJPEGRepresentation(photo, 0.8) else {return}
        let post = Post(photo: data)
        
        addCommentToPost(caption, post: post)
        saveContext()
    }
    
    func addCommentToPost(text: String, post: Post) {
        let _ = Comment(post: post, text: text)
        saveContext()
    }
    
    func saveContext() {
        let moc = Stack.sharedStack.managedObjectContext
        do {
            try moc.save()
        } catch {
            print("Context could not be saved")
        }
    }
    
}