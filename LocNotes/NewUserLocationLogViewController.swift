//
//  NewUserLocationLogViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/7/16.
//  Copyright © 2016 axe. All rights reserved.
//

import Photos
import UIKit

class NewUserLocationLogViewController: UIViewController, UITextViewDelegate, UICollectionViewDataSource,
                                        UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                        UICollectionViewDelegateFlowLayout
{

    @IBOutlet weak var titleTextFieldHolder: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextFieldHolder: UIView!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var logPhotosMainHolder: UIView!
    @IBOutlet weak var logPhotosMainScrollView: UIScrollView!
    @IBOutlet weak var logPhotosCollectionView: UICollectionView!
    // The Description Field default placeholder text
    var defaultDescriptionTextFieldPlaceholder: String!
    // Default placeholder color for the Description Text Field
    var defaultDescriptionTextFieldPlaceholderColor: UIColor!
    // Holds the PhotoViews shown in the CollectionView
    var photoViews: [PhotoView] = []
    // ImagePicker for the user to pick pictures from the saved photos
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup view
        setupView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Set the status bar color to the light color
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Set the status bar color back to default
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
    
    // MARK: - Setup functions
    func setupView() {
        // Custom functions
        func generateTopBorder(forView: UIView!) {
            let topBorder: UIView = UIView(frame: CGRectMake(0, 0, forView.frame.size.width, 1))
            topBorder.backgroundColor = UIColor.darkGrayColor()
            // Add it
            forView.addSubview(topBorder)
        }
        
        func generateBottomBorder(forView: UIView!) {
            let bottomBorder: UIView = UIView(frame: CGRectMake(0, forView.frame.size.height - 1, forView.frame.size.width, 1))
            bottomBorder.backgroundColor = UIColor.darkGrayColor()
            // Add it
            forView.addSubview(bottomBorder)
        }
        
        // Add the top border for the field holders
        generateTopBorder(self.titleTextFieldHolder)
        generateTopBorder(self.descriptionTextFieldHolder)
        generateTopBorder(self.logPhotosMainHolder)
        // Add the bottom border for the field holders
        generateBottomBorder(self.titleTextFieldHolder)
        generateBottomBorder(self.self.descriptionTextFieldHolder)
        generateBottomBorder(logPhotosMainHolder)
        
        // Let us handle the text view events to deal with the placeholder text
        self.defaultDescriptionTextFieldPlaceholder = self.descriptionTextField.text
        self.defaultDescriptionTextFieldPlaceholderColor = self.descriptionTextField.textColor
        self.descriptionTextField.delegate = self
        
        // Setup the background color for the CollectionView
        self.logPhotosCollectionView.backgroundColor = UIColor.clearColor()
        self.logPhotosCollectionView.backgroundView = UIView(frame: CGRectZero)
        // Let us handle the data source and delegate for the CollectionView of the photos
        self.logPhotosCollectionView.dataSource = self
        // We should handle the FlowLayout for the Photos CollectionView as well
        self.logPhotosCollectionView.delegate = self
    }
    
    // MARK: - TextView Delegate functions to deal with placeholder text
    func textViewDidBeginEditing(textView: UITextView) {
        if( textView == descriptionTextField &&
            textView.textColor == defaultDescriptionTextFieldPlaceholderColor ) {
            
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if( textView == descriptionTextField &&
            textView.text.isEmpty ) {
            
            textView.text = defaultDescriptionTextFieldPlaceholder
            textView.textColor = defaultDescriptionTextFieldPlaceholderColor
        }
    }
    
    // MARK: - PhotoCollectionView Functions
    func addPhotoButtonClicked(sender: AnyObject) -> Void {
        // Allow the user to pick photos now; Check for authorization now
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            // Complain as we don't have access
            
            // Setup the Alert Controller
            let alertController: UIAlertController = UIAlertController(title: "Attention", message: "Please allow us to access your photo library in the Settings so that you can pick and add photos to your location log. Goto settings?", preferredStyle: .Alert)
            
            // Setup the Action Buttons for the Alert
            let settingsAction: UIAlertAction = UIAlertAction(title: "Settings", style: .Default) {(_) -> Void in
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                if let url = settingsUrl {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            
            // Now attach the action buttons to the Alert Controller
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            // Now show it
            self.presentViewController(alertController, animated: true, completion: nil)
            
        } else {
            // We have access to their photos
            if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
                // Setup some things up
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                imagePicker.allowsEditing = false
                // Now present the controller
                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    func removePhotoButtonClicked(sender: AnyObject, extraInfo: PhotoView?) -> Void {
        if( extraInfo == nil ) {
            return // We cannot do anything :(
        }
        // Fetch the index and remove the PhotoView at that index
        self.photoViews.removeAtIndex(extraInfo!.photoViewIndex)
        // Update all the PhotoView indexes
        if( self.photoViews.count != 0 ) {
            for index in 0...(self.photoViews.count - 1) {
                photoViews[index].photoViewIndex = index
            }
        }
        // Force update of the CollectionView
        self.logPhotosCollectionView.reloadData()
    }
    
    func imageClicked(sender: AnyObject, extraInfo: PhotoView?) -> Void {
        // TODO
    }
    
    // MARK: - ImagePickerController Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        // Hide the ImagePicker
        self.dismissViewControllerAnimated(true, completion: {() -> Void in
            // Do nothing
        })
        // Now, save the image
        let newPhotoView: PhotoView = PhotoView()
        newPhotoView.image = image // Save the image
        newPhotoView.photoViewIndex = self.photoViews.count // Add the photo view index
        // Add it to the list of PhotoViews
        self.photoViews.append(newPhotoView)
        // Now force an update of the CollectionView
        self.logPhotosCollectionView.reloadData()
        // Scroll to end of the PhotosCollectionView
        let lastIndexPath: NSIndexPath = NSIndexPath(forItem: self.photoViews.count, inSection: 0)
        self.logPhotosCollectionView.scrollToItemAtIndexPath(lastIndexPath, atScrollPosition: .Right, animated: true)
    }
    
    // MARK: - UICollectionViewDataSource Delegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one to the number of PhotoViews (the one extra is for the plus button collection view)
        return (self.photoViews.count + 1)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Check if we should be returning a default PhotoView cell or a plus button CollectionView
        if( indexPath.row == self.photoViews.count ) {
            let addPhotoCell: AddNewPhotoCollectionViewCell? = collectionView.dequeueReusableCellWithReuseIdentifier("addPhotoCell", forIndexPath: indexPath) as? AddNewPhotoCollectionViewCell
            // Customize the cell
            addPhotoCell?.addPhotoButtonClickedFunction = self.addPhotoButtonClicked
            // Now, return
            return addPhotoCell!
        }
        // Else, we are returning a normal PhotoViewCell
        var photoViewCell: PhotoCollectionViewCell! = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        // Check for null
        if( photoViewCell == nil ) {
            photoViewCell = PhotoCollectionViewCell(frame: CGRect(x: 0, y: 0, width: 128, height: 128))
        }
        // Customize the cell
        photoViewCell?.extraInformation = self.photoViews[indexPath.row]
        photoViewCell?.imageViewClickedFunction = self.imageClicked
        photoViewCell?.removePhotoButtonClickedFunction = self.removePhotoButtonClicked
        // Now return
        return photoViewCell!
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // REFERENCE: http://stackoverflow.com/a/29987062/705471
        
        if( indexPath.row == self.photoViews.count ) {
            // If we're asked for the size of the add photo button, default 128x128 is sent
            return CGSize(width: 128, height: 128)
        }
        // Else, calculate the ratio and then send the new size
        return CGSize(width: CGFloat(self.photoViews[indexPath.row].image!.size.width * (128 / self.photoViews[indexPath.row].image!.size.height)),
                      height: 128)
    }
    
    // MARK: - Other methods
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews() // Let the super do its stuff
        logPhotosCollectionView.collectionViewLayout.invalidateLayout()
    }

}
