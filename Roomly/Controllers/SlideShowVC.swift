//
//  SlideShowVC.swift
//  Roomly
//
//  Created by Jason Shultz on 12/13/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class SlideShowVC: UIViewController {
    
    static let notificationName = Notification.Name("myNotificationName")
    
    var slideShowDictionary = NSDictionary()
    var slideShowImages = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(onNotification(notification:)), name: SlideShowVC.notificationName, object: nil)
        
    }
    
    func setSlideShowImages(images: [UIImage]) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func onNotification(notification:Notification)
    {
        guard let slideShowImages = notification.userInfo!["images"] else { return }
        print("slideShowImages \(slideShowImages)")
    }
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
