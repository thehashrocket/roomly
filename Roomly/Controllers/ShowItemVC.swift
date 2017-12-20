//
//  ShowItemVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/26/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ShowItemVC: UIViewController {
    
    // Variables
    var ref: DatabaseReference!
    var selected_item = ""
    var selected_room = ""
    var saved_image = ""
    var slideShowDictionary = NSDictionary()
    var slideShowImages = [UIImage]()

    // Outlets
    @IBOutlet weak var itemNameText: UILabel!
    @IBOutlet weak var itemDescriptionText: UILabel!
    @IBOutlet weak var PurchaseAmountText: UILabel!
    @IBOutlet weak var PurchaseDateText: UILabel!

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(SlideShowVC.notificationName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }

    func loadData() {
        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                let userID = Auth.auth().currentUser?.uid
                let item = DataService.instance.getSelectedItem() as String
                let room = DataService.instance.getSelectedRoom() as String
                
                let itemRef = self.ref.child("items").child(userID!).child(room).child(item)
                itemRef.keepSynced(true)
                
                itemRef.observe(DataEventType.value, with: { (snapshot) in
                    self.spinner.startAnimating()
                    let value = snapshot.value as? NSDictionary
                    
                    if ((value) != nil) {
                        self.itemNameText.text = value?["itemName"] as? String
                        self.title = value?["itemName"] as? String
                        self.itemDescriptionText.text = value?["itemDescription"] as? String
                        //                        self.PurchaseAmountText.text = "\(String(format: "$%.02f", value?["purchaseAmount"] as! CVarArg))"
                        var formatted_string = Double()
                        formatted_string = (value?["purchaseAmount"] as! NSString).doubleValue
                        self.PurchaseAmountText.text = (String(format: "$%.02f", formatted_string))
                        self.PurchaseDateText.text = value?["purchaseDate"] as? String
                        if ((value?["imageName"]) != nil) {
                            self.saved_image = (value?["imageName"] as? String)!
                        } else {
                            self.saved_image = ""
                        }
                        let room_id = value?["roomId"] as! String
                        let item_id = value?["id"] as! String
                        let user_id = value?["uid"] as! String
                        let destination = "/images/items/\(user_id)/\(room_id)/\(item_id)/"
                        
                        let slideShowDictionary = value?["images"] as? NSDictionary
                        self.slideShowImages.removeAll()
                        if ((slideShowDictionary) != nil) {
                            let total = slideShowDictionary?.count
                            var count = 0
                            
                            slideShowDictionary?.forEach({ (_,value) in
                                CloudStorage.instance.downloadImage(reference: destination, image_key: value as! String, completion: { (image) in
                                    self.slideShowImages.append(image)
                                })
                                count = count + 1
                                if (count == total) {
                                    NotificationCenter.default.post(name: SlideShowVC.notificationName, object: nil, userInfo:["images": self.slideShowImages])
                                }
                            })
                            
                        } else {
                            
                        }
                    }
                    
                    self.navigationItem.title = value?["itemName"] as? String
                    self.spinner.stopAnimating()
                }){ (error) in
                    self.spinner.stopAnimating()
                    print(error.localizedDescription)
                }
                
            } else {
                // TODO: Segue to WelcomeVC here.
                print("No user is signed in.")
            }
        }
    }
    
    // Actions
    @IBAction func unwindToShowItemVC(segue:UIStoryboardSegue) {
        loadData()
    }
    
    @IBAction func editItemPressed(_ sender: Any) {
//        let editItem = EditItemVC()
//        editItem.modalPresentationStyle = .custom
//        present(editItem, animated: true, completion: nil)
    }
    
}
