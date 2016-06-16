//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/13/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController, PhotoSelectViewControllerDelegate {
    
    @IBOutlet weak var captionTextFIeld: UITextField!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - IBActions

    @IBAction func addPostButtonPressed(sender: AnyObject) {
        if let image = image, let caption = captionTextFIeld.text {
            PostController.sharedPostController.createPost(image, caption: caption)
            self.dismissViewControllerAnimated(true, completion: nil)
            self.tableView.reloadData()
        } else {
            let alertController = UIAlertController(title: "Missing Information", message: "Check that you have selected a photo and written a caption.", preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alertController.addAction(dismissAction)
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoSelectViewControllerSelectedImage(image: UIImage) {
        self.image = image
    }
   
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedPhotoSelect" {
            let photoSelectVC = segue.destinationViewController as? PhotoSelectViewController
            photoSelectVC?.delegate = self
        }
    }
 

}
