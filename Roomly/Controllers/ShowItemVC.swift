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

    // Outlets
    @IBOutlet weak var itemNameText: UILabel!
    @IBOutlet weak var itemDescriptionText: UILabel!
    @IBOutlet weak var PurchaseAmountText: UILabel!
    @IBOutlet weak var PurchaseDateText: UILabel!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                let userID = Auth.auth().currentUser?.uid
                let item = DataService.instance.getSelectedItem() as String
                let room = DataService.instance.getSelectedRoom() as String
                
                self.ref.child("items").child(userID!).child(room).child(item).observe(DataEventType.value, with: { (snapshot) in
                    self.spinner.startAnimating()
                    let value = snapshot.value as? NSDictionary
                    
                    if ((value) != nil) {
                        self.itemNameText.text = value?["itemName"] as? String
                        self.itemDescriptionText.text = value?["itemDescription"] as? String
                        self.PurchaseAmountText.text = value?["purchaseAmount"] as? String
                        self.PurchaseDateText.text = value?["purchaseDate"] as? String
                        if ((value?["imageName"]) != nil) {
                            self.saved_image = (value?["imageName"] as? String)!
                        } else {
                            self.saved_image = ""
                        }
                        let room_id = value?["roomId"] as! String
                        let item_id = value?["id"] as! String
                        let user_id = value?["uid"] as! String
                        let destination = "items/\(user_id)/\(room_id)/\(item_id)/"
                        
                        CloudStorage.instance.loadTopImage(destination: destination, saved_image: self.saved_image, completion: { (image) in
                            self.imagePicked.image = image
                        })
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Actions
    @IBAction func editItemPressed(_ sender: Any) {
        let editItem = EditItemVC()
        editItem.modalPresentationStyle = .custom
        present(editItem, animated: true, completion: nil)
    }
    
}
