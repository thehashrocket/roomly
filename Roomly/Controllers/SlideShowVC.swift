//
//  SlideShowVC.swift
//  Roomly
//
//  Created by Jason Shultz on 12/13/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class SlideShowVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Outlets
    @IBOutlet weak var slideShowCollection: UICollectionView!
    
    static let notificationName = Notification.Name("myNotificationName")
    
    var datasource: [UIImage]?
    var timer:Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        slideShowCollection.dataSource = self
        slideShowCollection.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNotification(notification:)), name: SlideShowVC.notificationName, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func autoScrollImageSlider() {
        
        DispatchQueue.global(qos: .background).async {
            
            DispatchQueue.main.async {
                
                let firstIndex = 0
                let lastIndex = (self.datasource?.count)! - 1
                
                let currentIndex = self.slideShowCollection.indexPathsForVisibleItems
                let nextIndex = currentIndex[0].row + 1
                
                let nextIndexPath: IndexPath = IndexPath.init(item: nextIndex, section: 0)
                let firstIndexPath: IndexPath = IndexPath.init(item: firstIndex, section: 0)
                // holding off on auto scrolling for now. it's confusing.
//                if nextIndex > lastIndex {
//                    self.slideShowCollection.scrollToItem(at: firstIndexPath, at: .centeredHorizontally, animated: true)
//                } else {
//                    self.slideShowCollection.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
//                }
            }
        }
    }
    
    func scrollToPreviousOrNextCell(direction: String) {
        print("direction: \(direction)")
        DispatchQueue.global(qos: .background).async {
            
            DispatchQueue.main.async {
                
                let firstIndex = 0
                let lastIndex = (self.datasource?.count)! - 1
                
                let currentIndex = self.slideShowCollection.indexPathsForVisibleItems
                
                let nextIndex = currentIndex[0].row + 1
                let previousIndex = currentIndex[0].row - 1
                
                let nextIndexPath: IndexPath = IndexPath.init(item: nextIndex, section: 0)
                let previousIndexPath: IndexPath = IndexPath.init(item: previousIndex, section: 0)
                
                if direction == "Previous" {
                    if previousIndex < firstIndex {
                        
                    } else {
                        self.slideShowCollection.scrollToItem(at: previousIndexPath, at: .centeredHorizontally, animated: true)
                    }
                } else if direction == "Next" {
                    if nextIndex > lastIndex {
                        
                    } else {
                        self.slideShowCollection.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if ((datasource) != nil) {
            return datasource!.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cellId = "cell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! SlideShowCell
        cell.updateView(image: self.datasource![indexPath.row])
        return cell
        
    }
    
    //After you've received data from server or you are ready with the datasource, call this method. Magic!
    func reloadCollectionView() {
        self.slideShowCollection.reloadData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func onNotification(notification:Notification)
    {
        if ((notification.userInfo!["images"]) != nil) {
            self.datasource = notification.userInfo!["images"] as? [UIImage]
            self.reloadCollectionView()
        }
    }

    // Actions
    @IBAction func PreviousButton(_ sender: Any) {
        if self.datasource != nil {
            if self.datasource?.count != 0 {
                self.scrollToPreviousOrNextCell(direction: "Previous")
            }
        }
    }
    
    @IBAction func NextButton(_ sender: Any) {
        if self.datasource != nil {
            if self.datasource?.count != 0 {
                self.scrollToPreviousOrNextCell(direction: "Next")
            }
        }
    }
    
}
