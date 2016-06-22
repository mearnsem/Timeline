//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/21/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostDetailTableViewController: UITableViewController {
    
    var post: Post?
    var fetchedResultsController: NSFetchedResultsController?
    
    @IBOutlet weak var postImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
    }
    
    func updateWithPost(post: Post) {
        let image = UIImage(data: post.photoData)
        postImageView.image = image
        
        tableView.reloadData()
    }
    
    // MARK: - Fetched Results Controller
    
    func setupFetchedResultsController() {
        guard let post = post else {
            fatalError("Could not unwrap post")
        }
        
        let request = NSFetchRequest(entityName: "Comment")
        let sortDescriptors = NSSortDescriptor(key: "timestamp", ascending: false)
        let predicate = NSPredicate(format: "post == %@", [post])
        
        request.sortDescriptors = [sortDescriptors]
        request.predicate = predicate
        request.returnsObjectsAsFaults = false
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Stack.sharedStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Unable to create fetched results controller: \(error)")
        }
        
        fetchedResultsController?.delegate = self
        
    }
    
    // MARK: - IBActions
    
    @IBAction func commentButtonPressed(sender: AnyObject) {
        var commentTextField: UITextField?
        
        let alertController = UIAlertController(title: "Add Comment", message: "Write your comment for this post", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            commentTextField = textField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "OK", style: .Default) { (_) in
            guard let post = self.post, commentText = commentTextField?.text else {return}
            PostController.sharedController.addCommentToPost(commentText, post: post)
            self.tableView.reloadData()
        }
        alertController.addAction(okAction)
    }
    
    @IBAction func shareButtonPressed(sender: AnyObject) {
        
    }
    
    @IBAction func followButtonPressed(sender: AnyObject) {
        
    }

    // MARK: - Table view data source

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
        /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PostDetailTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        case .Insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        case .Move:
            guard let indexPath = indexPath, newIndexPath = newIndexPath else {return}
            tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
        case .Update:
            guard let indexPath = indexPath else {return}
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}

