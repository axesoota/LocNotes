//
//  ViewController.swift
//  LocNotes
//
//  Created by axe2 on 6/22/16.
//  Copyright © 2016 axe. All rights reserved.
//

import UIKit

class SplashScreenController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup the timer to hide the splash screen and goto the next screen
        _ = NSTimer.scheduledTimerWithTimeInterval(
            2, target: self, selector: #selector(SplashScreenController.switchOutToListScreen), userInfo: nil, repeats: false
        )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func switchOutToListScreen() {
        performSegueWithIdentifier("showNewUser", sender: self)
    }
    
}
