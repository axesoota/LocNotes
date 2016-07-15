//
//  UserLocationLogsViewController.swift
//  LocNotes
//
//  Created by Akshit (Axe) Soota on 7/6/16.
//  Copyright © 2016 axe. All rights reserved.
//

import CoreData
import UIKit

class UserLocationLogsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var locationLogsTableView: UITableView!
    let reuseIdentifierlocationLogWithImage: String = "locationLogCellWithImage"
    let reuseIdentifierlocationLogWithoutImage: String = "locationLogCellWithoutImage"
    // Holds the Refresh Button Navigation Bar Item
    var navigationItemRefreshButton: UIBarButtonItem?
    // Array that holds all the Location Logs fetched from Core Data
    var locationLogs: [LocationLog] = []
    // Dictionary to hold the images for each Location Log that has images associated with them
    var locationLogImages: Dictionary<String, UIImage> = [String: UIImage]()
    // Holds if the TableView should show a loading cell or not
    var tableViewLoadingCellShown: Bool = false
    // Holds the TableView loading cell itself
    var tableViewLoadingCell: UITableViewCell? // TODO
    
    // Core Data Managed Context
    var managedContext : NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch Location logs from CoreData
        fetchLocationLogs()
        // Set up the views
        setupViews()
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
    
    // MARK: - Setup View Functions here
    func fetchLocationLogs() {
        func resizeImage(image: UIImage, size: CGSize) -> UIImage {
            // CITATION: http://stackoverflow.com/a/7775470/705471
            
            let newRect: CGRect = CGRectIntegral(CGRectMake(0, 0, size.width, size.height))
            let imageRef: CGImageRef = image.CGImage!
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            
            CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
            let flipVertical: CGAffineTransform = CGAffineTransformMake(1, 0, 0, -1, 0, size.height)
            
            CGContextConcatCTM(context, flipVertical)
            CGContextDrawImage(context, newRect, imageRef)
            
            let newImageRef: CGImageRef = CGBitmapContextCreateImage(context)! as CGImage
            let newImage: UIImage = UIImage(CGImage: newImageRef)
            
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        // Load the Managed Context from the AppDelegate
        if( self.managedContext == nil ) {
            self.managedContext = AppDelegate().managedObjectContext
        }
        // Proceed to querying it
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "LocationLog")
        let imageFetchQuery: NSFetchRequest = NSFetchRequest(entityName: "FullResolutionS3Image")
        do {
            let results = try self.managedContext?.executeFetchRequest(fetchRequest)
            let locationLogs: [LocationLog] = results as! [LocationLog]
            
            let imageResults = try self.managedContext?.executeFetchRequest(imageFetchQuery)
            let images: [FullResolutionS3Image] = imageResults as! [FullResolutionS3Image]
            
            // Save the Location Logs reversed
            self.locationLogs = locationLogs.sort({(first: LocationLog, second: LocationLog) -> Bool in
                return Double(first.addedDate!) > Double(second.addedDate!)
            })
            
            // Update the Image Array for the location logs
            self.locationLogImages = [String: UIImage]()
            // Iterate over each of the Location Logs
            for locationLog in self.locationLogs {
                // Check if this posses an image or not
                if( locationLog.imageS3ids != nil && locationLog.imageS3ids?.isEmpty == false ) {
                    // There is an image here
                    let firstS3ImageID: String = (locationLog.imageS3ids?.characters.split(";").map(String.init)[0])!
                    // Find the image here
                    for anImage in images {
                        if( anImage.respectiveLogID == locationLog.logID && anImage.s3id == firstS3ImageID ) {
                            self.locationLogImages[locationLog.logID!] = resizeImage(UIImage(data: anImage.image!)!, size: CGSizeMake(UIScreen.mainScreen().bounds.width, 250))
                            // We found the image and we saved it, so:
                            break
                        }
                    }
                    // Done!
                }
            }
            
        } catch {
            CommonUtils.showDefaultAlertToUser(self, title: "CoreData Error", alertContents: "We were unable to pull your Location Logs using the CoreData API. Please re-open the application to try again!")
        }
    }
    
    func setupViews() {
        // Table View Delegate should be us
        self.locationLogsTableView.delegate = self
        // Also the Data Source
        self.locationLogsTableView.dataSource = self
        
        // Setup Table View No Location Logs Background
        let nibArray: [AnyObject] = NSBundle.mainBundle().loadNibNamed("NoLocationLogsView", owner: self, options: nil)
        let toReturn = nibArray[0] as! UIView
        toReturn.frame.size = self.locationLogsTableView.frame.size
        self.locationLogsTableView.backgroundView = toReturn
        
        // Grab the refresh button reference
        self.navigationItemRefreshButton = self.navigationItem.leftBarButtonItem
    }
    
    // MARK: - UITableView Delegate and Data Source Functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // See if the "No Location Logs" view has to be shown or not
        if( locationLogs.count == 0 ) {
            self.locationLogsTableView.separatorStyle = .None
            self.locationLogsTableView.backgroundView?.hidden = false
        } else {
            self.locationLogsTableView.separatorStyle = .SingleLine
            self.locationLogsTableView.backgroundView?.hidden = true
        }
        // Now return
        if( self.tableViewLoadingCellShown ) {
            return locationLogs.count + 1
        }
        return locationLogs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Check if we are loading something
        if( self.tableViewLoadingCellShown && indexPath.row == 0 ) {
            // Return the loading cell
            // TODO:
            return UITableViewCell()
        }
        // Now, fetch the TableViewCell accordingly
        var llIndex: Int = indexPath.row
        
        if( self.tableViewLoadingCellShown ) {
            llIndex -= 1      // The first cell is the Loading Cell
        }
        
        if( self.locationLogs[llIndex].imageS3ids == nil || self.locationLogs[llIndex].imageS3ids?.isEmpty == true ) {
            // We've got no images
            let origTableCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifierlocationLogWithoutImage)!
            let locationLogCell: LocationLogWithoutImageTableViewCell = origTableCell as! LocationLogWithoutImageTableViewCell
            // Now, set the information
            locationLogCell.locationLogTitle.text = self.locationLogs[llIndex].logTitle!
            locationLogCell.locationLogDesc.text = self.locationLogs[llIndex].logDesc!
            // Set TableViewCell Insets
            locationLogCell.preservesSuperviewLayoutMargins = false
            locationLogCell.separatorInset = UIEdgeInsetsZero
            locationLogCell.layoutMargins = UIEdgeInsetsZero
            
            // Now, return
            return locationLogCell
        } else {
            // We've got images
            let origTableCell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifierlocationLogWithImage)!
            let locationLogCell: LocationLogWithImageTableViewCell = origTableCell as! LocationLogWithImageTableViewCell
            // Now, set the information
            locationLogCell.locationLogTitle.text = self.locationLogs[llIndex].logTitle!
            locationLogCell.locationLogDesc.text = self.locationLogs[llIndex].logDesc!
            locationLogCell.imageHolder.image = self.locationLogImages[self.locationLogs[llIndex].logID!]
            // Set TableViewCell Insets
            locationLogCell.preservesSuperviewLayoutMargins = false
            locationLogCell.separatorInset = UIEdgeInsetsZero
            locationLogCell.layoutMargins = UIEdgeInsetsZero
            
            // Now, return
            return locationLogCell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Check if we are loading something
        if( self.tableViewLoadingCellShown && indexPath.row == 0 ) {
            return 64
        }
        // Else, check:
        var llIndex: Int = indexPath.row
        
        if( self.tableViewLoadingCellShown ) {
            llIndex -= 1      // The first cell is the Loading Cell
        }
        
        if( self.locationLogs[llIndex].imageS3ids == nil || self.locationLogs[llIndex].imageS3ids?.isEmpty == true ) {
            // No images cell => 64
            return 64
        } else {
            return 250
        }
    }
    
    // MARK: - Actions received here
    @IBAction func navigationBarSettingsButtonClicked(sender: UIBarButtonItem) {
        // Navigate to the Settings Page
        self.performSegueWithIdentifier("showSettingsPage", sender: self)
    }
    
    @IBAction func navigationBarAddButtonClicked(sender: UIBarButtonItem) {
        // Navigate to the add location log screen
        self.navigationController!.performSegueWithIdentifier("showNewOrUpdateLocationLog", sender: self)
    }
    
    @IBAction func navigationBarRefreshButtonClicked(sender: AnyObject) {
        // Show the activity indicator instead of the Refresh Button
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: .White)
        let refreshBarButton: UIBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.leftBarButtonItem = refreshBarButton
        activityIndicator.startAnimating()
        // Show activity indicator on the Status Bar
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // TODO: Query the server and compare
    }
    
    // MARK: - Segue actions handler here
    @IBAction func unwindSegue(segue: UIStoryboardSegue) {
        if( segue.sourceViewController.isKindOfClass(NewUserLocationLogViewController) ) {
            // Call the function to populate the LocationLogs from CoreData
            self.fetchLocationLogs()
            // And, refresh the TableView
            self.locationLogsTableView.reloadData()
            // Scroll to the top of the TableView
            self.locationLogsTableView.setContentOffset(CGPointZero, animated: true)
        }
    }

}
