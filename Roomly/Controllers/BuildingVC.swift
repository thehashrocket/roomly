//
//  HomeVC.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class BuildingVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var ref: DatabaseReference!
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildingTable.dataSource = self
        buildingTable.delegate = self
        
        self.ref = Database.database().reference()
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                print("start login success: " + (UserDataService.instance.email) )
                
                let key = self.ref.child("posts").childByAutoId().key
                let userID = Auth.auth().currentUser?.uid
                
                let post = ["uid": userID,
                            "author": "username",
                            "title": "title",
                            "body": "body"]
                
                let childUpdates = ["/posts/\(key)": post,
                                    "/user-posts/\(userID)/\(key)/": post]
                self.ref.updateChildValues(childUpdates)
                
                
                
//                self.ref.child("users").child("123456").setValue(["username": "test@test.com"])
                
//                self.ref.child("buildings").child(userID!).setValue([
//                    "username": UserDataService.instance.email,
//                    "uid": UserDataService.instance.id
//                    ])
                
            } else {
                // TODO: Segue to WelcomeVC here.
                print("No user is signed in.")
            }
        }
        
        
        
//        ref = Database.database().reference()
//
//        self.ref.child("users").child(user.uid).setValue(["username": username])
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Outlets
    
    @IBOutlet weak var buildingTable: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataService.instance.getBuildings().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell") as? BuildingCell {
            let building = DataService.instance.getBuildings()[indexPath.row]
            cell.updateViews(building: building)
            return cell
        } else {
            return BuildingCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let building = DataService.instance.getBuildings()[indexPath.row]
        performSegue(withIdentifier: "RoomVC", sender: building)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("in segue")
        if let roomVC = segue.destination as? RoomVC {
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            navigationItem.backBarButtonItem = barBtn
            print (sender)
            assert(sender as? Building != nil)
            roomVC.initRooms(building: sender as! Building)
        }
    }


}

