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
    var handle: AuthStateDidChangeListenerHandle?
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener() { auth, user in
            
            if let user = user {
                // User is signed in.
                self.loginBtn.title = "Logout"
                self.buildingTable.reloadData()
            } else {
                DataService.instance.resetBuildings()
                self.buildingTable.reloadData()
                self.loginBtn.title = "Login"
                print("No user is signed in.")
            }
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildingTable.dataSource = self
        buildingTable.delegate = self
        
        self.auth = Auth.auth()

        if Auth.auth().currentUser != nil {
            UINavigationBar.appearance().barTintColor = .blue
            UINavigationBar.appearance().tintColor = .white
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            UINavigationBar.appearance().isTranslucent = false
            
            self.ref = Database.database().reference()
            
            guard let userID = Auth.auth().currentUser?.uid else { return }
            self.ref.child("buildings").child(userID).observe(DataEventType.value, with: { (snapshot) in
                self.spinner.startAnimating()
                
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                
                DataService.instance.resetBuildings()
                
                postDict.forEach({ (arg) in
                    
                    let (_, value) = arg
                    let dataChange = value as! [String: AnyObject]
                    
                    let id = dataChange["id"] as! String
                    let buildingName = dataChange["buildingName"] as! String
                    let street = dataChange["street"] as! String
                    let city = dataChange["city"] as! String
                    let country = dataChange["country"] as! String
                    let state = dataChange["state"] as! String
                    let zip = dataChange["zip"] as! String
                    let imageName = dataChange["imageName"] as! String
                    let uid = dataChange["uid"] as! String
                    let files = NSDictionary()
                    
                    let building = Building(id: id, buildingName: buildingName, street: street, city: city, state: state, country: country, zip: zip, uid: uid, imageName: imageName, images: files)
                    
                    DataService.instance.setBuilding(building: building)
                    
                    self.buildingTable.reloadData()
                    self.spinner.stopAnimating()
                })
            }, withCancel: { (error) in
                print("BuildingVC: ")
                print(error)
            })
        }
        
        self.buildingTable.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // [START remove_auth_listener]
        Auth.auth().removeStateDidChangeListener(handle!)
        // [END remove_auth_listener]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Outlets
    
    @IBOutlet weak var aboutBtn: UIBarButtonItem!
    @IBOutlet weak var loginBtn: UIBarButtonItem!
    @IBOutlet weak var buildingTable: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

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
        DataService.instance.setSelectedBuilding(building: building)
        performSegue(withIdentifier: "RoomVC", sender: building)
    }
    
    @IBAction func addBuildingPressed(_ sender: Any) {
        let addBuilding = AddBuildingVC()
        addBuilding.modalPresentationStyle = .custom
        present(addBuilding, animated: true, completion: nil)
    }
    
    @IBAction func loginBtnPressed(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            do {
                try self.auth?.signOut()
                performSegue(withIdentifier: "loginTabController", sender: nil)
            } catch {
                
            }
        } else {
            performSegue(withIdentifier: "loginTabController", sender: nil)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let roomVC = segue.destination as? RoomVC {
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            navigationItem.backBarButtonItem = barBtn
            assert(sender as? Building != nil)
            roomVC.initRooms(building: sender as! Building)
        }
    }
}

