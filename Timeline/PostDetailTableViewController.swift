//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/13/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostDetailTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var commentButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var followPostButton: UIBarButtonItem!
    @IBOutlet weak var detailImageView: UIImageView!
    
    var fetchedResultsController: NSFetchedResultsController?
    var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
        
        //        if let font = UIFont(name: "Avenir", size: 14) {
        //            commentButton.setTitleTextAttributes([NSFontAttributeName: font], forState: .Normal)
        //            shareButton.setTitleTextAttributes([NSFontAttributeName: font], forState: .Normal)
        //            followPostButton.setTitleTextAttributes([NSFontAttributeName: font], forState: .Normal)
        //        }
        
        setupFetchedResultsController()
        
        if let post = post {
            updateWithPost(post)
        }
    }
    
    // MARK: - Functions
    
    func setupFetchedResultsController() {
        guard let post = post else { fatalError() }
        
        let request = NSFetchRequest(entityName: "Comment")
        let predicate = NSPredicate(format: "post == %@", argumentArray: [post])
        let timestampDescriptor = NSSortDescriptor(key: "timestamp", ascending: true)
        
        request.predicate = predicate
        request.sortDescriptors = [timestampDescriptor]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Stack.sharedStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch let error as NSError {
            print("Unable to perform fetch request: \(error.localizedDescription)")
        }
        fetchedResultsController?.delegate = self
    }
    
    func updateWithPost(post: Post) {
        let image = UIImage(data: post.photoData ?? NSData())
        detailImageView.image = image
        
        tableView.reloadData()
        
        PostController.sharedPostController.checkSubscriptionToPostComments(post) { (subscribed) in
            if subscribed {
                self.followPostButton.title = "Unfollow Post"
            } else {
                self.followPostButton.title = "Follow Post"
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func commentButtonPressed(sender: AnyObject) {
        var commentTextField: UITextField?
        let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Write your comment here"
            commentTextField = textField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "Add Comment", style: .Default) { (_) in
            guard let post = self.post, let commentTextField = commentTextField?.text where commentTextField.characters.count > 0 else {return}
            PostController.sharedPostController.addCommentToPost(post, text: commentTextField)
            self.tableView.reloadData()
        }
        alertController.addAction(okAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonPressed(sender: AnyObject) {
        guard let image = detailImageView.image else {return}
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func followButtonPressed(sender: AnyObject) {
        guard  let post = post else {return}
        PostController.sharedPostController.togglePostCommentSubscription(post) { (success, isSubscribed, error) in
            self.updateWithPost(post)
        }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController?.sections else {return 0}
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections else {return 0}
        return sections[section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath)
        
        if let comment = fetchedResultsController?.objectAtIndexPath(indexPath) as? Comment {
            cell.textLabel?.text = comment.text
            
        }
        
        return cell
    }
    
}
