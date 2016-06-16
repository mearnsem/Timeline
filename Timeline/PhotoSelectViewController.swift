//
//  PhotoSelectViewController.swift
//  Timeline
//
//  Created by Emily Mearns on 6/15/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PhotoSelectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var addPostImageView: UIImageView!
    @IBOutlet weak var selectImageButtonText: UIButton!

    weak var delegate: PhotoSelectViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func selectImageButtonPressed(sender: AnyObject) {
        setupImagePicker()
        selectImageButtonText.setTitle("", forState: .Normal)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {return}
        delegate?.photoSelectViewControllerSelectedImage(image)
        addPostImageView.image = image
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setupImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let actionSheet = UIAlertController(title: "Please choose image source", message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .Default) { (_) in
            imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            actionSheet.addAction(photoLibraryAction)
        }
        
        let cameraAction = UIAlertAction(title: "Camera", style: .Default) { (_) in
            imagePicker.sourceType = .Camera
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        actionSheet.addAction(cameraAction)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            actionSheet.addAction(cameraAction)
        }
        
        presentViewController(actionSheet, animated: true, completion: nil)
        
    }
}

protocol PhotoSelectViewControllerDelegate: class {
    func photoSelectViewControllerSelectedImage(image: UIImage)
}