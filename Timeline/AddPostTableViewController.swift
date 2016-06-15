//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/13/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController {

    @IBOutlet weak var addPostImageView: UIImageView!
    @IBOutlet weak var captionTextFIeld: UITextField!
    @IBOutlet weak var selectImageButtonText: UIButton!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - IBActions
    
    @IBAction func selectImageButtonPressed(sender: AnyObject) {
        addPostImageView.image = UIImage(named: "samplepic")
        selectImageButtonText.setTitle("", forState: .Normal)
    }

    @IBAction func addPostButtonPressed(sender: AnyObject) {
        if let image = addPostImageView.image, let caption = captionTextFIeld.text {
            PostController.sharedPostController.createPost(image, caption: caption)
            self.dismissViewControllerAnimated(true, completion: nil)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
