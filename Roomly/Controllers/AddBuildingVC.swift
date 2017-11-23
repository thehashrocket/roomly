//
//  AddBuildingVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/23/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class AddBuildingVC: UIViewController {
    
    var ref: DatabaseReference!
    
    // Outlets
    @IBOutlet weak var buildingNameTxt: UITextField!
    @IBOutlet weak var streetTxt: UITextField!
    @IBOutlet weak var cityTxt: UITextField!
    @IBOutlet weak var stateTxt: UITextField!
    @IBOutlet weak var zipTxt: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Actions
    @IBAction func dismissPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        let key = self.ref.child("buildings").childByAutoId().key
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        guard let name = buildingNameTxt.text , buildingNameTxt.text != "" else {
            return
        }
        guard let street = streetTxt.text , streetTxt.text != "" else {
            return
        }
        guard let city = cityTxt.text , cityTxt.text != "" else {
            return
        }
        guard let state = stateTxt.text , stateTxt.text != "" else {
            return
        }
        guard let zip = zipTxt.text , zipTxt.text != "" else {
            return
        }
        
        
        let building = Building(id: key, buildingName: name, street: street, city: city, state: state, zip: zip, uid: userID, imageName: "house1.jpg")
        
        
        let post = [
            "buildingName" : building.buildingName,
            "street" : building.street,
            "city" : building.city,
            "state" : building.state,
            "zip" : building.zip,
            "uid" : building.uid,
            "id" : building.id
        ]
        
        let childUpdates = ["/buildings/\(key)": post]
        self.ref.updateChildValues(childUpdates)
    }
    

}
