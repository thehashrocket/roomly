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
    
    var ref: DatabaseReference!
    
    var selected_item = ""
    var selected_room = ""
    var saved_image = ""

    // Outlets
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var itemDescription: UITextField!
    @IBOutlet weak var purchaseAmount: UITextField!
    @IBOutlet weak var purchaseDate: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                let userID = Auth.auth().currentUser?.uid
                let item = DataService.instance.getSelectedItem() as String
                let room = DataService.instance.getSelectedRoom() as String
                print(self.selected_room)
                print(self.selected_item)
                self.ref.child("items").child(userID!).child(room).child(item).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    self.itemName.text = value?["itemName"] as! String
                    self.itemDescription.text = value?["itemDescription"] as! String
                    self.purchaseAmount.text = value?["purchaseAmount"] as! String
                    self.purchaseDate.text = value?["purchaseDate"] as! String
                    self.saved_image = value?["imageName"] as! String
                    
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(value?["imageName"] as! String)
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    
                    self.imagePicked.image = image
                    
                }) { (error) in
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
}
